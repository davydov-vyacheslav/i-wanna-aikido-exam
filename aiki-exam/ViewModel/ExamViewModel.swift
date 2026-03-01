import Foundation
import Combine
import AVFoundation

// MARK: – Exam state machine

enum ExamState: Equatable {
    case idle       // before first Start
    case running
    case paused
    case finished
}

// MARK: – ExamViewModel

@MainActor
final class ExamViewModel: ObservableObject {

    // ── Published state ───────────────────────────────────

    @Published private(set) var state: ExamState = .idle
    @Published private(set) var currentTechnic: TechnicItem?
    @Published private(set) var doneCount:    Int = 0
    @Published private(set) var skippedCount: Int = 0
    @Published private(set) var timerProgress: Double = 1.0   // 1 → 0 within each interval
    @Published private(set) var examElapsed:  Int = 0         // seconds (time mode)

    // ── Dependencies (injected) ───────────────────────────

    private let settings: AppSettings
    private var profile: Profile?

    // ── Internal ──────────────────────────────────────────

    /// Tracks which technics have been shown (no-repeat mode).
    private var seenIDs: Set<String> = []

    private var techniqueTimer: Timer?
    private var progressTimer: Timer?
    private var examClockTimer: Timer?
    private var progressStep: Int = 0   // counts down from totalSteps
    private var audioPlayer: AVAudioPlayer?

    // ── Init ──────────────────────────────────────────────

    init(settings: AppSettings) {
        self.settings = settings
    }

    // MARK: – Public interface

    /// Call once when the active profile changes or the screen appears.
    func bind(profile: Profile?) {
        if self.profile?.id != profile?.id {
            self.profile = profile
            reset()
        }
    }

    func start() {
        guard state != .running, let profile, settings.canStart(profile: profile) else { return }
        if state == .idle, currentTechnic == nil {
            currentTechnic = pickNext()
        }
        state = .running
        startTimers()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        stopTimers()
    }

    func skip() {
        guard state == .running, canSkipNow else { return }
        skippedCount += 1
        currentTechnic = pickNext(excluding: currentTechnic)
        restartTechniqueTimer()
    }

    func reset() {
        stopTimers()
        state           = .idle
        currentTechnic  = nil
        doneCount       = 0
        skippedCount    = 0
        timerProgress   = 1.0
        examElapsed     = 0
        seenIDs         = []
    }

    // MARK: – Computed helpers

    var canSkipNow: Bool {
        guard state == .running, let current = currentTechnic else { return false }
        if settings.examMode == .time, !settings.allowRepeat {
            let remaining = remainingExamSeconds
            // Pool after removing current from seen + skip
            let poolSize = pool(excluding: current).count
            return settings.canSkip(remainingSeconds: remaining, poolSizeAfterSkip: poolSize)
        }
        return true
    }

    var examProgress: Double {
        switch settings.examMode {
        case .count:
            guard settings.examCountTarget > 0 else { return 0 }
            return min(1.0, Double(doneCount) / Double(settings.examCountTarget))
        case .time:
            let total = settings.examTimeMinutes * 60
            guard total > 0 else { return 0 }
            return min(1.0, Double(examElapsed) / Double(total))
        }
    }

    var remainingExamSeconds: Int {
        max(0, settings.examTimeMinutes * 60 - examElapsed)
    }

    var isFeasible: Bool {
        guard let profile else { return false }
        return settings.canStart(profile: profile)
    }

    var requiredTechniquesForTimedNoRepeat: Int {
        settings.minimumTechniquesForTimedNoRepeat
    }

    // MARK: – Timer management

    private func startTimers() {
        startProgressTimer()
        startTechniqueTimer()
        if settings.examMode == .time {
            startExamClock()
        }
    }

    private func stopTimers() {
        techniqueTimer?.invalidate();  techniqueTimer = nil
        progressTimer?.invalidate();  progressTimer = nil
        examClockTimer?.invalidate(); examClockTimer = nil
    }

    private func restartTechniqueTimer() {
        techniqueTimer?.invalidate()
        progressTimer?.invalidate()
        timerProgress = 1.0
        startProgressTimer()
        startTechniqueTimer()
    }

    private func startTechniqueTimer() {
        let interval = TimeInterval(settings.intervalSeconds)
        techniqueTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.advanceTechnique() }
        }
    }

    private func startProgressTimer() {
        let totalSteps = settings.intervalSeconds * 10   // update 10× per second
        progressStep   = totalSteps
        timerProgress  = 1.0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.progressStep -= 1
                self.timerProgress = max(0, Double(self.progressStep) / Double(totalSteps))
            }
        }
    }

    private func startExamClock() {
        examClockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state == .running else { return }
                self.examElapsed += 1
                if self.examElapsed >= self.settings.examTimeMinutes * 60 {
                    self.finish()
                }
            }
        }
    }

    private func advanceTechnique() {
        guard state == .running else { return }

        // Mark current as done
        if let current = currentTechnic {
            seenIDs.insert(current.id)
            doneCount += 1
            playSound()
        }

        // Check finish conditions
        if settings.examMode == .count, doneCount >= settings.examCountTarget {
            finish(); return
        }
        let next = pickNext()
        if next == nil, !settings.allowRepeat {
            finish(); return          // pool exhausted
        }
        currentTechnic = next
        restartProgressBar()
    }

    private func restartProgressBar() {
        progressTimer?.invalidate()
        timerProgress = 1.0
        startProgressTimer()
    }

    private func finish() {
        stopTimers()
        state = .finished
    }

    // MARK: – Technique pool

    /// Returns a random technic from the available pool (respecting allowRepeat and seenIDs),
    /// optionally excluding one specific technic (for skip).
    private func pickNext(excluding exclude: TechnicItem? = nil) -> TechnicItem? {
        // FIMXE: sue randomize flag
        var candidates = pool()
        if let ex = exclude {
            candidates = candidates.filter { $0.id != ex.id }
        }
        return candidates.randomElement()
    }

    private func pool(excluding exclude: TechnicItem? = nil) -> [TechnicItem] {
        guard let profile else { return [] }
        var base = profile.technics
        if !settings.allowRepeat {
            base = base.filter { !seenIDs.contains($0.id) }
        }
        if let ex = exclude {
            base = base.filter { $0.id != ex.id }
        }
        return base
    }

    // MARK: – Sound

    private func playSound() {
        guard settings.soundEnabled else { return }
        // In production use AudioServicesPlaySystemSound or a bundled .wav
        // Here we use system "Tock" sound (id 1104)
        AudioServicesPlaySystemSound(1104)
    }
}

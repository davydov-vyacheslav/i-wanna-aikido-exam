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

    /// IDs excluded from pool: completed + skipped (used when allowRepeat = false).
    private var usedIDs: Set<String> = []
    
    /// Ordered queue used when allowRepeat = true && randomize = false.
    /// Completed and skipped items are appended to the end.
    private var orderedQueue: [TechnicItem] = []

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
        if state == .idle {
            // Initialise queue / pool for the new exam run
            if settings.allowRepeat && !settings.randomize {
                orderedQueue = Array(profile.technics)
            }
            if currentTechnic == nil {
                currentTechnic = dequeueNext()
            }
        }
        state = .running
        startTimers()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        stopTimers()
    }

    /// Skips the current technique:
    /// - allowRepeat=false  → adds to usedIDs (permanently removed from pool).
    /// - allowRepeat=true, randomize=false → deferred to end of ordered queue.
    /// - allowRepeat=true, randomize=true  → excluded only from the immediate next pick.
    func skip() {
        guard state == .running, canSkipNow, let current = currentTechnic else { return }
        skippedCount += 1

        if settings.allowRepeat && !settings.randomize {
            orderedQueue.append(current)          // defer to end of queue
            currentTechnic = orderedQueue.isEmpty ? nil : orderedQueue.removeFirst()
        } else if !settings.allowRepeat {
            usedIDs.insert(current.id)            // permanently remove from pool
            currentTechnic = dequeueNext(excluding: current)
        } else {
            // allowRepeat=true, randomize=true: just pick a different random
            currentTechnic = dequeueNext(excluding: current)
        }

        restartTechniqueTimer()
    }
    
    /// Forces an immediate finish regardless of exam mode / progress.
    func forceFinish() {
        guard state == .running || state == .paused else { return }
        finish()
    }

    func reset() {
        stopTimers()
        state           = .idle
        currentTechnic  = nil
        doneCount       = 0
        skippedCount    = 0
        timerProgress   = 1.0
        examElapsed     = 0
        usedIDs         = []
        orderedQueue    = []
    }

    // MARK: – Computed helpers

    var canSkipNow: Bool {
        guard state == .running, let current = currentTechnic else { return false }

        if settings.allowRepeat && !settings.randomize {
            // Queue must have at least one other item waiting
            return !orderedQueue.isEmpty
        }

        let poolAfterSkip = availablePool(excluding: current)
        guard !poolAfterSkip.isEmpty else { return false }

        // Time mode + no-repeat: ensure enough unique techniques cover remaining time
        if settings.examMode == .time, !settings.allowRepeat {
            return settings.canSkip(
                remainingSeconds: remainingExamSeconds,
                poolSizeAfterSkip: poolAfterSkip.count
            )
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

    /// Marks the current technique as done, picks the next one, and checks finish conditions.
    /// Exposed as `internal` so unit tests can drive state without real timers.
    func advanceTechnique() {
        guard state == .running else { return }

        // Mark current as done
        if let current = currentTechnic {
            doneCount += 1
            playSound()

            if settings.allowRepeat && !settings.randomize {
                // Cycle: append done item back to end of queue
                orderedQueue.append(current)
            } else {
                // Pool mode: mark as used so it won't reappear
                usedIDs.insert(current.id)
            }
        }

        // Check finish conditions before picking next
        if settings.examMode == .count, doneCount >= settings.examCountTarget {
            finish(); return
        }

        // Pick next
        let next = dequeueNext()
        if next == nil && !settings.allowRepeat {
            finish(); return          // pool exhausted in no-repeat mode
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

    // MARK: – Technique selection

    /// Returns the next technique to display.
    /// Routing logic:
    ///   - allowRepeat=true, randomize=false → pop from front of orderedQueue
    ///   - allowRepeat=true, randomize=true  → random from full profile pool (excluding `exclude`)
    ///   - allowRepeat=false, randomize=true → random from unseen pool
    ///   - allowRepeat=false, randomize=false → first of unseen pool (original insertion order)
    private func dequeueNext(excluding exclude: TechnicItem? = nil) -> TechnicItem? {
        if settings.allowRepeat && !settings.randomize {
            // Queue mode: consume from front
            if orderedQueue.isEmpty { return nil }
            let item = orderedQueue.removeFirst()
            // If caller excluded this item (edge case during skip), defer it and try next
            if let ex = exclude, item.id == ex.id {
                orderedQueue.append(item)
                return orderedQueue.isEmpty ? nil : orderedQueue.removeFirst()
            }
            return item
        }

        // Pool-based modes
        var candidates = availablePool()
        if let ex = exclude {
            candidates = candidates.filter { $0.id != ex.id }
        }
        return settings.randomize ? candidates.randomElement() : candidates.first
    }

    /// Returns the pool of candidates eligible for selection.
    /// When allowRepeat=false, excludes items already in usedIDs (done + skipped).
    private func availablePool(excluding exclude: TechnicItem? = nil) -> [TechnicItem] {
        guard let profile else { return [] }
        var base = profile.technics
        if !settings.allowRepeat {
            base = base.filter { !usedIDs.contains($0.id) }
        }
        if let ex = exclude {
            base = base.filter { $0.id != ex.id }
        }
        return base
    }

    // MARK: – Sound

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: .mixWithOthers)
        try? session.setActive(true)
    }

    private func playSound() {
        guard settings.soundEnabled else { return }

        guard let url = Bundle.main.url(forResource: "gong", withExtension: "caf") else {
            AudioServicesPlaySystemSound(1304)
            return
        }

        configureAudioSession()

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            assertionFailure("AVAudioPlayer error: \(error)")
        }
    }
}

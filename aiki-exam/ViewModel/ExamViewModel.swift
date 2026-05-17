import Foundation
import Combine
import AVFoundation

// MARK: – Exam state machine

enum ExamState: String, Equatable {
    case idle       // before first Start
    case running
    case paused
    case finished
}

// MARK: – ExamViewModel

@MainActor
final class ExamViewModel: ObservableObject {

    @Published private(set) var state: ExamState = .idle
    @Published private(set) var currentTechnic: TechnicItem?
    @Published private(set) var doneCount:    Int = 0
    @Published private(set) var skippedCount: Int = 0
    @Published private(set) var timerProgress: Double = 1.0   // 1 → 0 within each interval
    @Published private(set) var examElapsed:  Int = 0         // seconds (time mode)

    private let settings: AppSettings
    private var profile: Profile?
    private var queue: ExamQueue?
    private let audio = ExamAudio.shared
    private let timers = ExamTimers()

    /// Set by ExamView to resolve vocab keys → display strings for TTS.
    var nameResolver: ((String, VocabularyType) -> String)?
    var speechTextResolver: ((String, VocabularyType) -> String)?

    // ── Init ──────────────────────────────────────────────

    init(settings: AppSettings) {
        self.settings = settings
        setupTimers()
    }

    private func setupTimers() {
        timers.onAdvance  = { [weak self] in self?.advanceTechnique() }
        timers.onProgress = { [weak self] v in self?.timerProgress = v }
        timers.onExamTick = { [weak self] in
            guard let self, self.state == .running else { return }
            self.examElapsed += 1
            if self.examElapsed >= self.settings.examTimeMinutes * 60 { self.finish() }
        }
        syncVoice()
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
            queue = ExamQueue(profile: profile, settings: settings)
            if currentTechnic == nil {
                currentTechnic = queue?.dequeueNext()
            }
            audio.playGong(enabled: settings.soundEnabled)
            speakCurrent()   // announce first technique
            timers.startAll(
                intervalSeconds: settings.intervalSeconds,
                includeExamClock: settings.examMode == .time
            )
        }
        
        if state == .paused {
            audio.resume()
            timers.resumeTimers(
                intervalSeconds: settings.intervalSeconds,
                includeExamClock: settings.examMode == .time
            )
        }

        state = .running
        syncVoice()
        notifyWatch()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timers.stop()
        audio.pause()
        notifyWatch()
    }

    /// Skips the current technique:
    /// - allowRepeat=false  → adds to usedIDs (permanently removed from pool).
    /// - allowRepeat=true, randomize=false → deferred to end of ordered queue.
    /// - allowRepeat=true, randomize=true  → excluded only from the immediate next pick.
    func skip() {
        guard state == .running,
              let current = currentTechnic,
              queue?.canSkip(current: current, remainingExamSeconds: remainingExamSeconds) == true
        else { return }
        skippedCount += 1
        queue?.markSkipped(current)
        currentTechnic = queue?.dequeueNext(excluding: current)
        audio.playGong(enabled: settings.soundEnabled)
        speakCurrent()
        timers.restartInterval(intervalSeconds: settings.intervalSeconds)
        notifyWatch()
    }
    
    /// Forces an immediate finish regardless of exam mode / progress.
    func forceFinish() {
        guard state == .running || state == .paused else { return }
        audio.stop()
        finish()
    }

    func reset() {
        timers.stop()
        audio.stop()
        audio.deactivateSession()
        state           = .idle
        currentTechnic  = nil
        doneCount       = 0
        skippedCount    = 0
        timerProgress   = 1.0
        examElapsed     = 0
        queue           = nil
        notifyWatch()
    }
    
    private func finish() {
        timers.stop()
        audio.deactivateSession()
        state = .finished
        notifyWatch()
    }

    // MARK: – Computed helpers

    var canSkipNow: Bool {
        guard state == .running, let current = currentTechnic else { return false }
        return queue?.canSkip(current: current, remainingExamSeconds: remainingExamSeconds) ?? false
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

    var remainingExamSeconds: Int { max(0, settings.examTimeMinutes * 60 - examElapsed) }
    var isFeasible: Bool { profile.map { settings.canStart(profile: $0) } ?? false }

    /// Marks the current technique as done, picks the next one, and checks finish conditions.
    /// Exposed as `internal` so unit tests can drive state without real timers.
    func advanceTechnique() {
        guard state == .running else { return }

        // Mark current as done
        if let current = currentTechnic {
            doneCount += 1
            queue?.markDone(current)
            audio.playGong(enabled: settings.soundEnabled)
        }

        // Check finish conditions before picking next
        if settings.examMode == .count, doneCount >= settings.examCountTarget {
            finish(); return
        }

        if queue?.isExhausted == true {
            finish(); return
        }
        
        currentTechnic = queue?.dequeueNext()
        speakCurrent()       // TTS after gong
        timers.resetProgress()
        notifyWatch()
    }

    // MARK: – TTS

    private func speakCurrent() {
        guard let tc = currentTechnic, let resolve = speechTextResolver else { return }
        let text = [resolve(tc.positionKey, .position),
                    resolve(tc.attackKey,   .attack),
                    resolve(tc.techniqueKey, .technique)].joined(separator: ". ")
        audio.speakAfterGong(text: text, enabled: settings.ttsEnabled, gongEnabled: settings.soundEnabled)
    }
    
    func speak(text: String) {
        audio.speakNow(text: text)
    }

    private func syncVoice() {
        audio.voiceIdentifier = settings.voiceIdentifier
    }
    
    // MARK: – Watch sync

    private func notifyWatch() {
        // TODO: WatchBridge.shared.send(state: state, technic: currentTechnic, nameResolver: nameResolver)
    }
}

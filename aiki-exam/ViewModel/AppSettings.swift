import Foundation
import Combine
import SwiftUI

// MARK: – Exam mode

enum ExamMode: String, CaseIterable, Identifiable {
    case count = "count"
    case time  = "time"
    var id: String { rawValue }
    
    var label: LocalizedStringKey {
        switch self {
        case .count: return ".label.examMode.count"
        case .time: return ".label.examMode.time"
        }
    }
}

private enum UDKey {
    static let randomize        = "randomizeFlag"
    static let examMode         = "examMode"
    static let examCountTarget  = "examCountTarget"
    static let examTimeMinutes  = "examTimeMinutes"
    static let intervalSeconds  = "intervalSeconds"
    static let allowRepeat      = "allowRepeat"
    static let soundEnabled     = "soundEnabled"
    static let ttsEnabled       = "ttsEnabled"
    static let activeProfileID  = "activeProfileID"
}

// MARK: – AppSettings

final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    @Published var randomize: Bool       { didSet { ud.set(randomize,       forKey: UDKey.randomize) } }
    @Published var examMode: ExamMode    { didSet { ud.set(examMode.rawValue, forKey: UDKey.examMode) } }
    @Published var examCountTarget: Int  { didSet { ud.set(examCountTarget,  forKey: UDKey.examCountTarget) } }
    @Published var examTimeMinutes: Int  { didSet { ud.set(examTimeMinutes,  forKey: UDKey.examTimeMinutes) } }
    @Published var intervalSeconds: Int  { didSet { ud.set(intervalSeconds,  forKey: UDKey.intervalSeconds) } }
    @Published var allowRepeat: Bool     { didSet { ud.set(allowRepeat,      forKey: UDKey.allowRepeat) } }
    @Published var soundEnabled: Bool    { didSet { ud.set(soundEnabled,     forKey: UDKey.soundEnabled) } }
    @Published var ttsEnabled: Bool      { didSet { ud.set(ttsEnabled,       forKey: UDKey.ttsEnabled) } }
    @Published var activeProfileID: UUID? {
        didSet { ud.set(activeProfileID?.uuidString, forKey: UDKey.activeProfileID) }
    }

    private let ud: UserDefaults

    private convenience init() {
        self.init(userDefaults: .standard)
    }

    /// Designated init. Exposed as `internal` so unit tests can inject an
    /// isolated suite without touching the real app's UserDefaults.
    init(
        userDefaults: UserDefaults,
        allowRepeat:      Bool     = true,
        randomize:        Bool     = false,
        examMode:         ExamMode = .count,
        examCountTarget:  Int      = 10,
        examTimeMinutes:  Int      = 5,
        intervalSeconds:  Int      = 30,
        soundEnabled:     Bool     = true,
        ttsEnabled:       Bool     = true,
        activeProfileID:  UUID?    = nil
    ) {
        self.ud = userDefaults
        self.randomize = userDefaults.bool(forKey: UDKey.randomize, default: randomize)
        self.examMode = userDefaults.decoded(forKey: UDKey.examMode, default: examMode)
        self.examCountTarget = userDefaults.int(forKey: UDKey.examCountTarget, default: examCountTarget)
        self.examTimeMinutes = userDefaults.int(forKey: UDKey.examTimeMinutes, default: examTimeMinutes)
        self.intervalSeconds = userDefaults.int(forKey: UDKey.intervalSeconds, default: intervalSeconds)
        self.allowRepeat = userDefaults.bool(forKey: UDKey.allowRepeat, default: allowRepeat)
        self.soundEnabled = userDefaults.bool(forKey: UDKey.soundEnabled, default: soundEnabled)
        self.ttsEnabled = userDefaults.bool(forKey: UDKey.ttsEnabled, default: ttsEnabled)
        self.activeProfileID = userDefaults.uuid(forKey: UDKey.activeProfileID) ?? activeProfileID
    }

    // MARK: – Feasibility

    /// Minimum unique techniques required to run a no-repeat timed exam.
    var minimumTechniquesForTimedNoRepeat: Int {
        Int(ceil(Double(examTimeMinutes * 60) / Double(intervalSeconds)))
    }

    /// Whether a given profile can start the exam under current settings.
    func canStart(profile: Profile) -> Bool {
        cantStartReason(profile: profile) == nil
    }

    func cantStartReason(profile: Profile) -> LocalizedStringKey? {
        // Always invalid: interval longer than total exam duration
        if examMode == .time, (examTimeMinutes * 60) < intervalSeconds {
            return ".error.settings.profile.incompatible_by_interval_value_for_exam"
        }
        // No-repeat feasibility checks
        if !allowRepeat {
            switch examMode {
            case .count:
                if profile.technics.count < examCountTarget {
                    return ".error.settings.profile.incompatible_by_technics_count \(examCountTarget) \(profile.technics.count)"
                }
            case .time:
                if profile.technics.count < minimumTechniquesForTimedNoRepeat {
                    return ".error.settings.profile.incompatible_by_time_count \(minimumTechniquesForTimedNoRepeat) \(profile.technics.count)"
                }
            }
        }
        return nil
    }

    /// Whether a skip is safe: won't leave fewer unique techs than the time remaining requires.
    func canSkip(remainingSeconds: Int, poolSizeAfterSkip: Int) -> Bool {
        guard examMode == .time, !allowRepeat else { return true }
        let needed = Int(ceil(Double(remainingSeconds) / Double(intervalSeconds)))
        return poolSizeAfterSkip >= needed
    }
}

// MARK: – UserDefaults helpers

private extension UserDefaults {

    func bool(forKey key: String, default fallback: Bool) -> Bool {
        object(forKey: key) as? Bool ?? fallback
    }

    func int(forKey key: String, default fallback: Int) -> Int {
        let v = integer(forKey: key)
        return v == 0 ? fallback : v
    }

    func uuid(forKey key: String) -> UUID? {
        string(forKey: key).flatMap(UUID.init(uuidString:))
    }

    func decoded<T: RawRepresentable>(forKey key: String, default fallback: T) -> T
        where T.RawValue == String
    {
        string(forKey: key).flatMap(T.init(rawValue:)) ?? fallback
    }
}

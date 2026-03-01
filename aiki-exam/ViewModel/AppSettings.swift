import Foundation
import Combine

// MARK: – Exam mode

enum ExamMode: String, CaseIterable, Identifiable {
    case count = "count"
    case time  = "time"
    var id: String { rawValue }
}

private enum UDKey {
    static let randomize        = "randomizeFlag"
    static let examMode         = "examMode"
    static let examCountTarget  = "examCountTarget"
    static let examTimeMinutes  = "examTimeMinutes"
    static let intervalSeconds  = "intervalSeconds"
    static let allowRepeat      = "allowRepeat"
    static let soundEnabled     = "soundEnabled"
    static let activeProfileID  = "activeProfileID"
}

// MARK: – AppSettings

/// Single source of truth for all user preferences.
/// Persisted via UserDefaults so it survives relaunches without
/// a SwiftData fetch. Active profile ID is joined to SwiftData at
/// the Settings screen.
final class AppSettings: ObservableObject {

    static let shared = AppSettings()
    private init() {}

    @Published var randomize: Bool = ud.bool(forKey: UDKey.randomize, default: false) {
        didSet { ud.set(randomize, forKey: UDKey.randomize) }
    }

    @Published var examMode: ExamMode = ud.decoded(forKey: UDKey.examMode, default: .count) {
        didSet { ud.set(examMode.rawValue, forKey: UDKey.examMode) }
    }

    @Published var examCountTarget: Int = ud.int(forKey: UDKey.examCountTarget, default: 10) {
        didSet { ud.set(examCountTarget, forKey: UDKey.examCountTarget) }
    }

    @Published var examTimeMinutes: Int = ud.int(forKey: UDKey.examTimeMinutes, default: 5) {
        didSet { ud.set(examTimeMinutes, forKey: UDKey.examTimeMinutes) }
    }

    @Published var intervalSeconds: Int = ud.int(forKey: UDKey.intervalSeconds, default: 30) {
        didSet { ud.set(intervalSeconds, forKey: UDKey.intervalSeconds) }
    }

    @Published var allowRepeat: Bool = ud.bool(forKey: UDKey.allowRepeat, default: true) {
        didSet { ud.set(allowRepeat, forKey: UDKey.allowRepeat) }
    }

    @Published var soundEnabled: Bool = ud.bool(forKey: UDKey.soundEnabled, default: true) {
        didSet { ud.set(soundEnabled, forKey: UDKey.soundEnabled) }
    }

    @Published var activeProfileID: UUID? = ud.uuid(forKey: UDKey.activeProfileID) {
        didSet { ud.set(activeProfileID?.uuidString, forKey: UDKey.activeProfileID) }
    }

    // MARK: – Feasibility

    /// Minimum unique techniques required to run a no-repeat timed exam.
    var minimumTechniquesForTimedNoRepeat: Int {
        Int(ceil(Double(examTimeMinutes * 60) / Double(intervalSeconds)))
    }

    /// Whether a given profile can start the exam under current settings.
    func canStart(profile: Profile) -> Bool {
        guard !profile.technics.isEmpty else { return false }
        if examMode == .time && !allowRepeat {
            return profile.technics.count >= minimumTechniquesForTimedNoRepeat
        } else if examMode == .count && !allowRepeat {
            return profile.technics.count >= examCountTarget
        }
        return true
    }

    /// Whether a skip is safe: won't leave fewer unique techs than
    /// the time remaining requires.
    func canSkip(
        remainingSeconds: Int,
        poolSizeAfterSkip: Int
    ) -> Bool {
        guard examMode == .time, !allowRepeat else { return true }
        let needed = Int(ceil(Double(remainingSeconds) / Double(intervalSeconds)))
        return poolSizeAfterSkip >= needed
        // TODO: process count based mode
    }
}

// MARK: – Helpers
private let ud = UserDefaults.standard

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

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
        (string(forKey: key)).flatMap(T.init(rawValue:)) ?? fallback
    }
}

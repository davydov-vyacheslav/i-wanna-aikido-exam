import XCTest
// TODO: rewrite to import Testing
@testable import aiki_exam

// MARK: – Mock settings helper

private func makeSettings(
    mode: ExamMode = .count,
    countTarget: Int = 3,
    timeMinutes: Int = 2,
    intervalSec: Int = 30,
    allowRepeat: Bool = true,
    sound: Bool = false
) -> AppSettings {
    let s = AppSettings.shared
    s.examMode          = mode
    s.examCountTarget   = countTarget
    s.examTimeMinutes   = timeMinutes
    s.intervalSeconds   = intervalSec
    s.allowRepeat       = allowRepeat
    s.soundEnabled      = sound
    return s
}

private func makeTechnics(_ count: Int) -> [TechnicItem] {
    (0..<count).map { i in
        TechnicItem(positionKey: "pos_\(i)", attackKey: "atk_\(i)", techniqueKey: "tec_\(i)")
    }
}

private func makeProfile(technicsCount: Int = 10) -> Profile {
    Profile(name: "Test", technics: makeTechnics(technicsCount))
}

// MARK: – ExamViewModelTests

@MainActor
final class ExamViewModelTests: XCTestCase {

    // MARK: – Initial state

    func test_initialState_isIdle() {
        let vm = ExamViewModel(settings: makeSettings())
        XCTAssertEqual(vm.state, .idle)
        XCTAssertNil(vm.currentTechnic)
        XCTAssertEqual(vm.doneCount, 0)
        XCTAssertEqual(vm.skippedCount, 0)
        XCTAssertEqual(vm.examElapsed, 0)
    }

    // MARK: – bind()

    func test_bind_nilProfile_leavesIdle() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: nil)
        XCTAssertEqual(vm.state, .idle)
        XCTAssertFalse(vm.isFeasible)
    }

    func test_bind_validProfile_setsFeasible() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile())
        XCTAssertTrue(vm.isFeasible)
    }

    func test_bind_newProfile_resetsState() {
        let s  = makeSettings()
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile())
        vm.start()
        XCTAssertEqual(vm.state, .running)

        // Bind a different profile
        vm.bind(profile: Profile(name: "Other", technics: makeTechnics(5)))
        XCTAssertEqual(vm.state, .idle)
        XCTAssertNil(vm.currentTechnic)
    }

    func test_bind_sameProfileID_doesNotReset() {
        let s  = makeSettings()
        let vm = ExamViewModel(settings: s)
        let p  = makeProfile()
        vm.bind(profile: p)
        vm.start()
        let before = vm.state
        vm.bind(profile: p)  // same id
        XCTAssertEqual(vm.state, before)  // no reset
    }

    // MARK: – start()

    func test_start_setsRunning() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile())
        vm.start()
        XCTAssertEqual(vm.state, .running)
    }

    func test_start_picksInitialTechnic() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile())
        vm.start()
        XCTAssertNotNil(vm.currentTechnic)
    }

    func test_start_withNoProfile_doesNotRun() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.start()
        XCTAssertEqual(vm.state, .idle)
    }

    func test_start_whenNotFeasible_doesNotRun() {
        // time mode, no-repeat, only 1 technic → need ceil(120/30)=4
        let s  = makeSettings(mode: .time, timeMinutes: 2, intervalSec: 30, allowRepeat: false)
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile(technicsCount: 1))
        XCTAssertFalse(vm.isFeasible)
        vm.start()
        XCTAssertEqual(vm.state, .idle)
    }

    // MARK: – pause()

    func test_pause_stopsRunning() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile())
        vm.start()
        vm.pause()
        XCTAssertEqual(vm.state, .paused)
    }

    func test_pause_thenStart_resumesRunning() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile())
        vm.start()
        vm.pause()
        vm.start()
        XCTAssertEqual(vm.state, .running)
    }

    // MARK: – reset()

    func test_reset_clearsAllState() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile())
        vm.start()
        vm.reset()
        XCTAssertEqual(vm.state, .idle)
        XCTAssertNil(vm.currentTechnic)
        XCTAssertEqual(vm.doneCount, 0)
        XCTAssertEqual(vm.skippedCount, 0)
        XCTAssertEqual(vm.examElapsed, 0)
    }

    // MARK: – skip()

    func test_skip_incrementsSkippedCount() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile(technicsCount: 20))
        vm.start()
        let before = vm.skippedCount
        vm.skip()
        XCTAssertEqual(vm.skippedCount, before + 1)
    }

    func test_skip_doesNotIncrementDoneCount() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile(technicsCount: 20))
        vm.start()
        vm.skip()
        XCTAssertEqual(vm.doneCount, 0)
    }

    func test_skip_whenNotRunning_doesNothing() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile())
        // state = idle
        vm.skip()
        XCTAssertEqual(vm.skippedCount, 0)
    }

    func test_skip_changesCurrentTechnic() {
        let vm = ExamViewModel(settings: makeSettings())
        vm.bind(profile: makeProfile(technicsCount: 50))
        vm.start()
        let before = vm.currentTechnic
        // With 50 items, the chance of same pick is 1/50 — run 10 times
        var changed = false
        for _ in 0..<10 {
            vm.skip()
            if vm.currentTechnic?.id != before?.id { changed = true; break }
        }
        XCTAssertTrue(changed, "Skip should produce a different technic most of the time")
    }

    // MARK: – canSkipNow

    func test_canSkip_countMode_alwaysTrue() {
        let s  = makeSettings(mode: .count, allowRepeat: false)
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile(technicsCount: 10))
        vm.start()
        XCTAssertTrue(vm.canSkipNow)
    }

    func test_canSkip_timeMode_repeat_alwaysTrue() {
        let s  = makeSettings(mode: .time, timeMinutes: 5, intervalSec: 30, allowRepeat: true)
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile(technicsCount: 10))
        vm.start()
        XCTAssertTrue(vm.canSkipNow)
    }

    func test_canSkip_timeMode_noRepeat_blockedWhenPoolTooSmall() {
        // 1 minute, 30 sec interval → need 2 techs minimum
        // Profile has exactly 2 unique techs; if we skip one, 1 remains < 2 needed
        let s  = makeSettings(mode: .time, timeMinutes: 1, intervalSec: 30, allowRepeat: false)
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile(technicsCount: 2))
        vm.start()
        // With only 2 techs and 2 needed, skipping is not safe
        XCTAssertFalse(vm.canSkipNow)
    }

    // MARK: – feasibility

    func test_feasibility_timedNoRepeat_enoughTechs() {
        // 1 min / 30 sec = need 2 → give 5 → feasible
        let s = makeSettings(mode: .time, timeMinutes: 1, intervalSec: 30, allowRepeat: false)
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile(technicsCount: 5))
        XCTAssertTrue(vm.isFeasible)
    }

    func test_feasibility_timedNoRepeat_tooFewTechs() {
        // 2 min / 30 sec = need 4 → give 3 → not feasible
        let s = makeSettings(mode: .time, timeMinutes: 2, intervalSec: 30, allowRepeat: false)
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile(technicsCount: 3))
        XCTAssertFalse(vm.isFeasible)
    }

    func test_feasibility_countMode_anyNonEmpty_feasible() {
        let s  = makeSettings(mode: .count, allowRepeat: false)
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile(technicsCount: 1))
        XCTAssertTrue(vm.isFeasible)
    }

    // MARK: – examProgress

    func test_examProgress_countMode_startsAtZero() {
        let s  = makeSettings(mode: .count, countTarget: 10)
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile())
        vm.start()
        XCTAssertEqual(vm.examProgress, 0.0, accuracy: 0.01)
    }

    func test_examProgress_countMode_clampsAtOne() {
        let s  = makeSettings(mode: .count, countTarget: 0)  // edge case
        let vm = ExamViewModel(settings: s)
        vm.bind(profile: makeProfile())
        XCTAssertEqual(vm.examProgress, 0.0)  // guard in computed var
    }

    // MARK: – minimumTechniquesForTimedNoRepeat

    func test_minimumTechs_calculation() {
        let s = makeSettings(mode: .time, timeMinutes: 1, intervalSec: 20, allowRepeat: false)
        // ceil(60/20) = 3
        XCTAssertEqual(s.minimumTechniquesForTimedNoRepeat, 3)
    }

    func test_minimumTechs_nonDivisible() {
        let s = makeSettings(mode: .time, timeMinutes: 1, intervalSec: 40, allowRepeat: false)
        // ceil(60/40) = 2
        XCTAssertEqual(s.minimumTechniquesForTimedNoRepeat, 2)
    }
}

import XCTest
// TODO: rewrite to import Testing
@testable import aiki_exam


// MARK: – TechnicItemTests

final class TechnicItemTests: XCTestCase {

    func test_id_isCompositeKey() {
        let tc = TechnicItem(positionKey: "pos_tachi_waza", attackKey: "atk_shomen_uchi", techniqueKey: "tec_ikkyo")
        XCTAssertEqual(tc.id, "pos_tachi_waza|atk_shomen_uchi|tec_ikkyo")
    }

//    func test_codable_roundtrip() throws {
//        let tc  = TechnicItem(positionKey: "p", attackKey: "a", techniqueKey: "t")
//        let data = try JSONEncoder().encode([tc])
//        let decoded = try JSONDecoder().decode([TechnicItem].self, from: data)
//        XCTAssertEqual(decoded.first, tc)
//    }
//
//    func test_hashable_equality() {
//        let a = TechnicItem(positionKey: "p", attackKey: "a", techniqueKey: "t")
//        let b = TechnicItem(positionKey: "p", attackKey: "a", techniqueKey: "t")
//        XCTAssertEqual(a, b)
//        let set: Set = [a, b]
//        XCTAssertEqual(set.count, 1)
//    }
//
//    func test_differentTechnics_notEqual() {
//        let a = TechnicItem(positionKey: "p1", attackKey: "a", techniqueKey: "t")
//        let b = TechnicItem(positionKey: "p2", attackKey: "a", techniqueKey: "t")
//        XCTAssertNotEqual(a, b)
//    }
//}
//
//// MARK: – ProfileTests
//
//final class ProfileTests: XCTestCase {
//
//    private func tech(_ n: Int) -> TechnicItem {
//        TechnicItem(positionKey: "p\(n)", attackKey: "a\(n)", techniqueKey: "t\(n)")
//    }
//
//    func test_init_storesTechnics() {
//        let technics = [tech(0), tech(1), tech(2)]
//        let profile  = Profile(name: "Test", technics: technics)
//        XCTAssertEqual(profile.technics.count, 3)
//        XCTAssertEqual(profile.technics[1].positionKey, "p1")
//    }
//
//    func test_technics_setter_roundtrip() {
//        let profile = Profile(name: "Test", technics: [])
//        profile.technics = [tech(0), tech(1)]
//        XCTAssertEqual(profile.technics.count, 2)
//        XCTAssertEqual(profile.technics[0].attackKey, "a0")
//    }
//
//    func test_clone_copiesTechnics() {
//        let original = Profile(name: "Orig", technics: [tech(0), tech(1)])
//        let cloned   = original.clone(name: "Copy")
//
//        XCTAssertNotEqual(cloned.id, original.id)
//        XCTAssertEqual(cloned.name, "Copy")
//        XCTAssertEqual(cloned.technics.count, 2)
//        XCTAssertFalse(cloned.isPreset)
//    }
//
//    func test_clone_isDeepCopy() {
//        let original = Profile(name: "Orig", technics: [tech(0)])
//        let cloned   = original.clone(name: "Copy")
//
//        // Mutate clone – original must not change
//        cloned.technics = [tech(9), tech(8)]
//        XCTAssertEqual(original.technics.count, 1)
//    }
//
//    func test_fromCartesian_countIsCorrect() {
//        let positions  = ["p1", "p2"]
//        let attacks    = ["a1", "a2", "a3"]
//        let techniques = ["t1", "t2"]
//        let profile = Profile.fromCartesian(name: "X", positions: positions, attacks: attacks, techniques: techniques)
//        XCTAssertEqual(profile.technics.count, 2 * 3 * 2)  // 12
//    }
//
//    func test_fromCartesian_allCombinationsPresent() {
//        let ps = ["p1"]; let as_ = ["a1"]; let ts = ["t1","t2","t3"]
//        let profile = Profile.fromCartesian(name: "X", positions: ps, attacks: as_, techniques: ts)
//        let keys = Set(profile.technics.map(\.techniqueKey))
//        XCTAssertEqual(keys, ["t1","t2","t3"])
//    }
//
//    func test_emptyCartesian_producesEmptyList() {
//        let profile = Profile.fromCartesian(name: "X", positions: [], attacks: ["a1"], techniques: ["t1"])
//        XCTAssertTrue(profile.technics.isEmpty)
//    }
//}
//
//// MARK: – PresetsTests
//
//final class PresetsTests: XCTestCase {
//
//    func test_allPresets_haveThreeSchools() {
//        XCTAssertEqual(Presets.all.count, 3)
//    }
//
//    func test_presetIDs_areUnique() {
//        let ids = Presets.all.map(\.id)
//        XCTAssertEqual(Set(ids).count, ids.count)
//    }
//
//    func test_aikikai_hasNoEmptyKeys() {
//        for tc in Presets.aikikai.technics {
//            XCTAssertFalse(tc.positionKey.isEmpty)
//            XCTAssertFalse(tc.attackKey.isEmpty)
//            XCTAssertFalse(tc.techniqueKey.isEmpty)
//        }
//    }
//
//    func test_allPresets_haveAtLeastOneTechnic() {
//        for preset in Presets.all {
//            XCTAssertGreaterThan(preset.technics.count, 0, "\(preset.id) has no technics")
//        }
//    }
//
//    func test_cartesian_isCorrect() {
//        let result = Presets.cartesian(
//            positions:  ["p1","p2"],
//            attacks:    ["a1"],
//            techniques: ["t1","t2"]
//        )
//        XCTAssertEqual(result.count, 4)  // 2×1×2
//    }
//
//    func test_makeProfile_from_preset() {
//        let profile = Presets.makeProfile(from: Presets.aikikai, name: "Copy")
//        XCTAssertEqual(profile.technics.count, Presets.aikikai.technics.count)
//        XCTAssertFalse(profile.isPreset)
//        XCTAssertEqual(profile.name, "Copy")
//    }
//
//    func test_presetTechnics_noDuplicates() {
//        for preset in Presets.all {
//            let ids = preset.technics.map(\.id)
//            let unique = Set(ids)
//            XCTAssertEqual(unique.count, ids.count, "\(preset.id) has duplicate technics")
//        }
//    }
//}
//
//// MARK: – AppSettingsTests
//
//final class AppSettingsTests: XCTestCase {
//
//    private func makeProfile(_ count: Int) -> Profile {
//        let technics = (0..<count).map { i in
//            TechnicItem(positionKey: "p\(i)", attackKey: "a\(i)", techniqueKey: "t\(i)")
//        }
//        return Profile(name: "T", technics: technics)
//    }
//
//    func test_canStart_countMode_anyNonEmptyProfile() {
//        let s = AppSettings()
//        s.examMode    = .count
//        s.allowRepeat = false
//        XCTAssertTrue(s.canStart(profile: makeProfile(1)))
//    }
//
//    func test_canStart_noProfile_returnsFalse() {
//        let s = AppSettings()
//        XCTAssertFalse(s.canStart(profile: nil))
//    }
//
//    func test_canStart_emptyProfile_returnsFalse() {
//        let s = AppSettings()
//        s.examMode = .count
//        XCTAssertFalse(s.canStart(profile: makeProfile(0)))
//    }
//
//    func test_canStart_timedNoRepeat_enoughTechs() {
//        let s = AppSettings()
//        s.examMode        = .time
//        s.allowRepeat     = false
//        s.examTimeMinutes = 1
//        s.intervalSeconds = 30
//        // need ceil(60/30)=2
//        XCTAssertTrue(s.canStart(profile: makeProfile(2)))
//    }
//
//    func test_canStart_timedNoRepeat_notEnoughTechs() {
//        let s = AppSettings()
//        s.examMode        = .time
//        s.allowRepeat     = false
//        s.examTimeMinutes = 2
//        s.intervalSeconds = 30
//        // need ceil(120/30)=4 → 3 < 4
//        XCTAssertFalse(s.canStart(profile: makeProfile(3)))
//    }
//
//    func test_canSkip_countMode_alwaysTrue() {
//        let s = AppSettings()
//        s.examMode    = .count
//        s.allowRepeat = false
//        XCTAssertTrue(s.canSkip(remainingSeconds: 100, poolSizeAfterSkip: 0))
//    }
//
//    func test_canSkip_timeMode_repeat_alwaysTrue() {
//        let s = AppSettings()
//        s.examMode    = .time
//        s.allowRepeat = true
//        XCTAssertTrue(s.canSkip(remainingSeconds: 100, poolSizeAfterSkip: 0))
//    }
//
//    func test_canSkip_timeMode_noRepeat_poolSufficient() {
//        let s = AppSettings()
//        s.examMode        = .time
//        s.allowRepeat     = false
//        s.intervalSeconds = 30
//        // remaining=60 → need 2, pool=3 → ok
//        XCTAssertTrue(s.canSkip(remainingSeconds: 60, poolSizeAfterSkip: 3))
//    }
//
//    func test_canSkip_timeMode_noRepeat_poolInsufficient() {
//        let s = AppSettings()
//        s.examMode        = .time
//        s.allowRepeat     = false
//        s.intervalSeconds = 30
//        // remaining=60 → need 2, pool=1 → blocked
//        XCTAssertFalse(s.canSkip(remainingSeconds: 60, poolSizeAfterSkip: 1))
//    }
//
//    func test_minimumTechs_divisible() {
//        let s = AppSettings()
//        s.examTimeMinutes = 1; s.intervalSeconds = 20
//        XCTAssertEqual(s.minimumTechniquesForTimedNoRepeat, 3) // 60/20
//    }
//
//    func test_minimumTechs_rounds_up() {
//        let s = AppSettings()
//        s.examTimeMinutes = 1; s.intervalSeconds = 40
//        XCTAssertEqual(s.minimumTechniquesForTimedNoRepeat, 2) // ceil(60/40)=2
//    }
//}
//
//// MARK: – L10nTests
//
//final class L10nTests: XCTestCase {
//
//    func test_allLanguages_resolvePositionKeys() {
//        for lang in ["uk","en","ru"] {
//            for key in MasterLists.positions {
//                let val = loc(key, lang: lang)
//                XCTAssertNotEqual(val, key, "Missing \(key) in \(lang)")
//            }
//        }
//    }
//
//    func test_allLanguages_resolveAttackKeys() {
//        for lang in ["uk","en","ru"] {
//            for key in MasterLists.attacks {
//                let val = loc(key, lang: lang)
//                XCTAssertNotEqual(val, key, "Missing \(key) in \(lang)")
//            }
//        }
//    }
//
//    func test_allLanguages_resolveTechniqueKeys() {
//        for lang in ["uk","en","ru"] {
//            for key in MasterLists.techniques {
//                let val = loc(key, lang: lang)
//                XCTAssertNotEqual(val, key, "Missing \(key) in \(lang)")
//            }
//        }
//    }
//
//    func test_allLanguages_resolveSchoolKeys() {
//        let schoolKeys = [L.school_aikikai, L.school_yoshinkan, L.school_iwama]
//        for lang in ["uk","en","ru"] {
//            for key in schoolKeys {
//                XCTAssertNotEqual(loc(key, lang: lang), key, "Missing \(key) in \(lang)")
//            }
//        }
//    }
//
//    func test_unknownKey_returnsKey() {
//        XCTAssertEqual(loc("nonexistent_key_xyz", lang: "uk"), "nonexistent_key_xyz")
//    }
}

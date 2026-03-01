import Foundation

enum Presets {

    static let all: [Profile] = [aikikai, yoshinkan, iwama]

    // ── Aikikai ───────────────────────────────────────────
// FIXME: as yaml storage ??? and more presice technics + link to orgin, like
    
    static let aikikai = Profile(
        name: "Aikikai",
        technics: cartesian(
            positions: [.tachi_waza, .suwari_waza],
            attacks:   [.shomen_uchi, .yokomen_uchi, .tsuki,
                        .katate_dori, .ryote_dori, .morote_dori],
            techniques:[.ikkyo, .nikkyo, .sankyo, .gokkyo,
                        .shiho_nage, .irimi_nage, .kote_gaeshi,
                        .kokyu_nage, .kokyu_ho]
        ),
        isPreset: true,
    )

    // ── Yoshinkan ─────────────────────────────────────────

    static let yoshinkan = Profile(
        name: "Yoshinkai",
        technics: cartesian(
            positions: [.tachi_waza, .suwari_waza, .hanmi_handachi_waza],
            attacks:   [.shomen_uchi, .yokomen_uchi, .katate_dori,
                        .ryote_dori, .morote_dori, .kata_dori, .ushiro_ryote_dori],
            techniques:[.ikkyo, .nikkyo, .sankyo, .yonkyo,
                        .gokkyo, .shiho_nage, .irimi_nage, .kote_gaeshi,
                        .kaiten_nage, .kokyu_nage]
        ),
        isPreset: true,
    )

    // ── Iwama ─────────────────────────────────────────────

    static let iwama = Profile(
        name: "Iwama",
        technics: cartesian(
            positions: [.tachi_waza],
            attacks:   [.shomen_uchi, .yokomen_uchi, .tsuki,
                        .katate_dori, .morote_dori, .ushiro_ryote_dori,
                        .ushiro_katate_dori_kubishime],
            techniques:[.ikkyo, .nikkyo, .sankyo, .yonkyo,
                        .shiho_nage, .irimi_nage, .kote_gaeshi,
                        .tenchi_nage, .aiki_otoshi, .sumi_otoshi,
                        .kokyu_nage]
        ),
        isPreset: true,
    )

    // MARK: – Helper

    static func cartesian(
        positions: [MasterPositions],
        attacks: [MasterAttacks],
        techniques: [MasterTechnics]
    ) -> [TechnicItem] {
        var result: [TechnicItem] = []
        result.reserveCapacity(positions.count * attacks.count * techniques.count)
        for p in positions {
            for a in attacks {
                for t in techniques {
                    result.append(TechnicItem(positionKey: p.rawValue, attackKey: a.rawValue, techniqueKey: t.rawValue))
                }
            }
        }
        return result
    }

    /// Creates a user-owned Profile pre-populated from a preset.
    static func makeProfile(from preset: Profile, name: String) -> Profile {
        Profile(name: name, technics: preset.technics, isPreset: false)
    }
}

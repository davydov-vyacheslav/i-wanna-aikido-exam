//
//  OotbValues.swift
//  aiki-exam
//
//  Created by Slava Davydov on 01.03.2026.
//

import SwiftUI

protocol ChipOption: RawRepresentable, Hashable, CaseIterable {
    var l10n: LocalizedStringKey { get }
}

enum MasterPositions: String, CaseIterable, ChipOption {
    case tachi_waza = "tachi_waza"
    case suwari_waza = "suwari_waza"
    case hanmi_handachi_waza = "hanmi_handachi_waza"
    
    var l10n: LocalizedStringKey {
        switch self {
        case .tachi_waza: return ".ootb.position.tachi_waza"
        case .suwari_waza: return ".ootb.position.suwari_waza"
        case .hanmi_handachi_waza: return ".ootb.position.hanmi_handachi_waza"
        }
    }
}

enum MasterAttacks: String, CaseIterable, ChipOption {
    case katate_dori = "katate_dori"
    case ryote_dori = "ryote_dori"
    case morote_dori = "morote_dori"
    case kata_dori = "kata_dori"
    case ushiro_ryote_dori = "ushiro_ryote_dori"
    case ushiro_katate_dori_kubishime = "ushiro_katate_dori_kubishime"
    case shomen_uchi = "shomen_uchi"
    case yokomen_uchi = "yokomen_uchi"
    case tsuki = "tsuki"
    
    var l10n: LocalizedStringKey {
        switch self {
        case .katate_dori: return ".ootb.attacks.katate_dori"
        case .ryote_dori: return ".ootb.attacks.ryote_dori"
        case .morote_dori: return ".ootb.attacks.morote_dori"
        case .kata_dori: return ".ootb.attacks.kata_dori"
        case .ushiro_ryote_dori: return ".ootb.attacks.ushiro_ryote_dori"
        case .ushiro_katate_dori_kubishime: return ".ootb.attacks.ushiro_katate_dori_kubishime"
        case .shomen_uchi: return ".ootb.attacks.shomen_uchi"
        case .yokomen_uchi: return ".ootb.attacks.yokomen_uchi"
        case .tsuki: return ".ootb.attacks.tsuki"
        }
    }
}

enum MasterTechnics: String, CaseIterable, ChipOption {
    case irimi_nage = "irimi_nage"
    case tenchi_nage = "tenchi_nage"
    case kote_gaeshi = "kote_gaeshi"
    case shiho_nage = "shiho_nage"
    case kaiten_nage = "kaiten_nage"
    case juji_garami = "juji_garami"
    case ikkyo = "ikkyo"
    case nikkyo = "nikkyo"
    case sankyo = "sankyo"
    case gokkyo = "gokkyo"
    case yonkyo = "yonkyo"
    case kokyu_ho = "kokyu_ho"
    case aiki_otoshi = "aiki_otoshi"
    case sumi_otoshi = "sumi_otoshi"
    case kokyu_nage = "kokyu_nage"
    
    var l10n: LocalizedStringKey {
        switch self {
        case .irimi_nage: return ".ootb.technics.irimi_nage"
        case .tenchi_nage: return ".ootb.technics.tenchi_nage"
        case .kote_gaeshi: return ".ootb.technics.kote_gaeshi"
        case .shiho_nage: return ".ootb.technics.shiho_nage"
        case .kaiten_nage: return ".ootb.technics.kaiten_nage"
        case .juji_garami: return ".ootb.technics.juji_garami"
        case .ikkyo: return ".ootb.technics.ikkyo"
        case .nikkyo: return ".ootb.technics.nikkyo"
        case .sankyo: return ".ootb.technics.sankyo"
        case .gokkyo: return ".ootb.technics.gokkyo"
        case .yonkyo: return ".ootb.technics.yonkyo"
        case .kokyu_ho: return ".ootb.technics.kokyu_ho"
        case .aiki_otoshi: return ".ootb.technics.aiki_otoshi"
        case .sumi_otoshi: return ".ootb.technics.sumi_otoshi"
        case .kokyu_nage: return ".ootb.technics.kokyu_nage"
        }
    }
}

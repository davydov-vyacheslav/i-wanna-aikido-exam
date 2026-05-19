//
//  VocabularyItem.swift
//  aiki-exam
//
//  Created by Slava Davydov on 03.05.2026.
//

import Foundation
import SwiftData

enum VocabularyType: String, Codable, CaseIterable, Identifiable {
    case position, attack, technique
    var id: String { rawValue }

    var sectionTitle: String {
        switch self {
        case .position:  return "Positions" // TODO: l10n, beware of usage
        case .attack:    return "Attacks"
        case .technique: return "Techniques"
        }
    }
    
    var label: String {
        switch self {
        case .position:  return "Position" // TODO: l10n, beware of usage
        case .attack:    return "Attack"
        case .technique: return "Technique"
        }
    }
}

@Model
final class VocabularyItem {

    @Attribute(.unique) var id: UUID
    var key: String
    private var typeRaw: String
    var displayName: String
    var pronunciation: String?

    var type: VocabularyType {
        get { VocabularyType(rawValue: typeRaw) ?? .technique }
        set { typeRaw = newValue.rawValue }
    }

    init(key: String, type: VocabularyType, displayName: String, pronunciation: String?) {
        self.id          = UUID()
        self.key         = key
        self.typeRaw     = type.rawValue
        self.displayName = displayName
        self.pronunciation = pronunciation
    }
    
    var speechText: String {
        get { pronunciation ?? displayName }
    }

}

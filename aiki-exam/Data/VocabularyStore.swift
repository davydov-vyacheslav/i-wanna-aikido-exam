//
//  VocabularyStore.swift
//  aiki-exam
//
//  Created by Slava Davydov on 03.05.2026.
//

import Foundation
import SwiftData
import Combine

// MARK: – Errors

enum VocabularyError: LocalizedError {
    case duplicate
    case emptyName
    case inUse([String])   // profile names

    var errorDescription: String? { // TODO: l10n
        switch self {
        case .duplicate:       return "A term with that name already exists."
        case .emptyName:       return "Name cannot be empty."
        case .inUse(let ps):   return "Used in profile(s): \(ps.joined(separator: ", ")).\nRemove from those profiles first."
        }
    }
}

// MARK: – VocabStore

@MainActor
final class VocabularyStore: ObservableObject {

    private let context: ModelContext

    @Published private(set) var positions:  [VocabularyItem] = []
    @Published private(set) var attacks:    [VocabularyItem] = []
    @Published private(set) var techniques: [VocabularyItem] = []

    init(context: ModelContext) {
        self.context = context
        refresh()
    }

    // MARK: – Lookup

    func displayName(for key: String, type: VocabularyType) -> String {
        items(for: type).first { $0.key == key }?.displayName ?? key
    }

    func items(for type: VocabularyType) -> [VocabularyItem] {
        switch type {
        case .position:  return positions
        case .attack:    return attacks
        case .technique: return techniques
        }
    }

    // MARK: – CRUD

    /// Adds a new custom vocab item. Throws if name is empty or a duplicate.
    func add(displayName: String, type: VocabularyType) throws {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw VocabularyError.emptyName }
        guard !items(for: type).contains(where: { $0.displayName.lowercased() == trimmed.lowercased() }) else {
            throw VocabularyError.duplicate
        }
        let key = trimmed.lowercased()
            .components(separatedBy: .whitespaces).joined(separator: "_")
        context.insert(VocabularyItem(key: key, type: type, displayName: trimmed))
        refresh()
    }

    /// Renames any item (preset or custom). Throws on empty name or duplicate.
    func rename(_ item: VocabularyItem, to newName: String) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw VocabularyError.emptyName }
        guard !items(for: item.type).contains(where: {
            $0.id != item.id && $0.displayName.lowercased() == trimmed.lowercased()
        }) else { throw VocabularyError.duplicate }
        item.displayName = trimmed
        refresh()
    }

    /// Deletes a custom item. Throws if the key is still referenced by any profile.
    func delete(_ item: VocabularyItem, allProfiles: [Profile]) throws {
        let usedIn = allProfiles.filter { p in
            p.technics.contains { tc in
                switch item.type {
                case .position:  return tc.positionKey  == item.key
                case .attack:    return tc.attackKey    == item.key
                case .technique: return tc.techniqueKey == item.key
                }
            }
        }
        guard usedIn.isEmpty else { throw VocabularyError.inUse(usedIn.map(\.name)) }
        context.delete(item)
        refresh()
    }

    // MARK: – Internal

    func refresh() {
        let all = (try? context.fetch(
            FetchDescriptor<VocabularyItem>(sortBy: [SortDescriptor(\.displayName)])
        )) ?? []
        positions  = all.filter { $0.type == .position }
        attacks    = all.filter { $0.type == .attack }
        techniques = all.filter { $0.type == .technique }
    }
}

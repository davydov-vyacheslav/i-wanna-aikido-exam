import Foundation
import SwiftData
import Yams

// MARK: – Public seeding API

enum DefaultsLoader {

    private static let seededKey = "defaults_seeded_v1"

    static func seedPresets(into ctx: ModelContext, settings: AppSettings) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        
        let doc = loadYAML()

        // insert vocabulary data
        func insertVocabulary(_ entries: [YAMLVocabEntry], type: VocabularyType) {
            for (_, e) in entries.enumerated() {
                ctx.insert(VocabularyItem(key: e.key, type: type, displayName: e.name, pronunciation: e.pronunciation))
            }
        }
        insertVocabulary(doc.vocab.positions,  type: .position)
        insertVocabulary(doc.vocab.attacks,    type: .attack)
        insertVocabulary(doc.vocab.techniques, type: .technique)
        
        // insert presents
        for p in doc.presets {
            let technics = p.combos.map {
                TechnicItem(positionKey: $0.position, attackKey: $0.attack, techniqueKey: $0.technique)
            }
            ctx.insert(Profile(name: p.name, technics: technics, isPreset: true))
        }
        
        // set active profile and lock seedkey
        if let first = ctx.insertedModelsArray.compactMap({ $0 as? Profile }).first {
            settings.activeProfileID = first.id
        }
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    // MARK: – Load & decode

    private static func loadYAML() -> YAMLDocument {
        guard
            let url  = Bundle.main.url(forResource: "defaults", withExtension: "yaml"),
            let text = try? String(contentsOf: url, encoding: .utf8),
            let raw  = try? Yams.load(yaml: text) as? [String: Any]
        else { return YAMLDocument() }
        return YAMLDocument(raw: raw)
    }

}

// MARK: – Decoded model

struct YAMLDocument {
    var vocab   = YAMLVocabSection()
    var presets: [YAMLPresetEntry] = []

    init() {}

    init(raw: [String: Any]) {
        // vocab:
        if let vocabRaw = raw["vocab"] as? [String: Any] {
            vocab.positions  = entries(from: vocabRaw["positions"])
            vocab.attacks    = entries(from: vocabRaw["attacks"])
            vocab.techniques = entries(from: vocabRaw["techniques"])
        }
        // presets:
        if let presetsRaw = raw["presets"] as? [[String: Any]] {
            presets = presetsRaw.compactMap { YAMLPresetEntry(raw: $0) }
        }
    }

    private func entries(from value: Any?) -> [YAMLVocabEntry] {
        guard let arr = value as? [[String: String]] else { return [] }
        return arr.compactMap { dict in
            guard let key = dict["key"], let name = dict["name"] else { return nil }
            return YAMLVocabEntry(key: key, name: name, pronunciation: dict["pronunciation"])
        }
    }
}

struct YAMLVocabSection {
    var positions:  [YAMLVocabEntry] = []
    var attacks:    [YAMLVocabEntry] = []
    var techniques: [YAMLVocabEntry] = []
}

struct YAMLVocabEntry { let key, name: String; let pronunciation: String? }

struct YAMLCombo { let position, attack, technique: String }

struct YAMLPresetEntry {
    let name, source: String
    let combos: [YAMLCombo]

    init?(raw: [String: Any]) {
        guard let name = raw["name"] as? String else { return nil }
        self.name   = name
        self.source = raw["source"] as? String ?? ""
        self.combos = (raw["combos"] as? [[String]] ?? []).compactMap { arr in
            guard arr.count == 3 else { return nil }
            return YAMLCombo(position: arr[0], attack: arr[1], technique: arr[2])
        }
    }
}

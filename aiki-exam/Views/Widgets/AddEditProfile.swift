//
//  AddEditProfile.swift
//  aiki-exam
//
//  Created by Slava Davydov on 01.03.2026.
//

import SwiftUI
import SwiftData

struct ProfileWizardView: View {
    var targetProfile: Profile? = nil

    @EnvironmentObject private var vocabStore: VocabularyStore
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selPositions: Set<String> = []
    @State private var selAttacks: Set<String> = []
    @State private var selTechniques: Set<String> = []

    private var isAddMode: Bool { targetProfile != nil }
    
    private var newCombos: Int {
        let existingIDs: Set<String> = isAddMode
            ? Set(targetProfile!.technics.map(\.id))
            : []
        var count = 0
        for p in selPositions {
            for a in selAttacks {
                for t in selTechniques where
                    !existingIDs.contains("\(p)|\(a)|\(t)") {
                    count += 1
                }
            }
        }
        return count
    }

    private var canConfirm: Bool {
        isAddMode ? newCombos > 0 : (!name.isEmpty && newCombos > 0)
    }

    var body: some View {
        let listView = List {
            if !isAddMode {
                Section {
                    TextField(".placeholder.profile.name", text: $name)
                        .font(.body)
                }
            }
            Section(".title.profile.creation.positions") {
                ChipPicker(items: vocabStore.positions, selectedKeys: $selPositions)
            }
            Section(".title.profile.creation.attacks") {
                ChipPicker(items: vocabStore.attacks, selectedKeys: $selAttacks)
            }
            Section(".title.profile.creation.techniques") {
                ChipPicker(items: vocabStore.techniques, selectedKeys: $selTechniques)
            }
            Section(".title.profile.creation.summary") {
                Text(
                    isAddMode
                        ? LocalizedStringKey(".label.profile.technics.new_combinations \(newCombos)")
                        : LocalizedStringKey(".label.profile.technics.total_combinations \(newCombos)")
                )
                .foregroundColor(.secondary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button(".button.common.cancel", action: { dismiss() })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                Button(isAddMode
                       ? ".button.common.add"
                       : ".button.profile.creation.create", action: confirm)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canConfirm)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.bar)
            
        }

        if isAddMode {
            NavigationStack {
                listView
                    .navigationTitle(".title.profile.add_technics")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            listView
        }
    }

    private func confirm() {
        let items = buildItems()
        if let profile = targetProfile {
            let existing = Set(profile.technics.map(\.id))
            let toAdd = items.filter { !existing.contains($0.id) }
            profile.technics.append(contentsOf: toAdd)
        } else {
            ctx.insert(Profile(name: name, technics: items, isPreset: false))
        }
        dismiss()
    }

    private func buildItems() -> [TechnicItem] {
        var result: [TechnicItem] = []
        for p in selPositions {
            for a in selAttacks {
                for t in selTechniques {
                    result.append(TechnicItem(positionKey: p, attackKey: a, techniqueKey: t))
                }
            }
        }
        return result
    }
}


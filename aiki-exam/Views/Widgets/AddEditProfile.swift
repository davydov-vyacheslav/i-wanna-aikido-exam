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
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selPositions:  Set<MasterPositions> = []
    @State private var selAttacks:    Set<MasterAttacks> = []
    @State private var selTechniques: Set<MasterTechnics> = []

    private var isAddMode: Bool { targetProfile != nil }
    
    private var newCombos: Int {
        let existingKeys: Set<String> = isAddMode
            ? Set(targetProfile!.technics.map { "\($0.positionKey)|\($0.attackKey)|\($0.techniqueKey)" })
            : []
        var count = 0
        for p in selPositions {
            for a in selAttacks {
                for t in selTechniques where !existingKeys.contains("\(p.rawValue)|\(a.rawValue)|\(t.rawValue)") {
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
                ChipPicker(all: Array(MasterPositions.allCases), selected: $selPositions)
            }
            Section(".title.profile.creation.attacks") {
                ChipPicker(all: Array(MasterAttacks.allCases), selected: $selAttacks)
            }
            Section(".title.profile.creation.techniques") {
                ChipPicker(all: Array(MasterTechnics.allCases), selected: $selTechniques)
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
                       ? ".button.profile.creation.add"
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
            let existingKeys = Set(profile.technics.map { "\($0.positionKey)|\($0.attackKey)|\($0.techniqueKey)" })
            let toAdd = items.filter { !existingKeys.contains("\($0.positionKey)|\($0.attackKey)|\($0.techniqueKey)") }
            profile.technics.append(contentsOf: toAdd)
        } else {
            ctx.insert(Profile(name: name, technics: items, isPreset: false))
        }
        dismiss()
    }

    private func buildItems() -> [TechnicItem] {
        var items: [TechnicItem] = []
        for p in selPositions {
            for a in selAttacks {
                for t in selTechniques {
                    items.append(TechnicItem(positionKey: p.rawValue, attackKey: a.rawValue, techniqueKey: t.rawValue))
                }
            }
        }
        return items
    }

    private func create() {
        let profile = fromCartesian(
            name: name,
            positions:  Array(selPositions),
            attacks:    Array(selAttacks),
            techniques: Array(selTechniques)
        )
        ctx.insert(profile)
        dismiss()
    }
    
    /// Build a profile from Cartesian product of key-lists.
    func fromCartesian(
        name: String,
        positions: [MasterPositions],
        attacks: [MasterAttacks],
        techniques: [MasterTechnics]
    ) -> Profile {
        var items: [TechnicItem] = []
        for p in positions {
            for a in attacks {
                for t in techniques {
                    items.append(TechnicItem(positionKey: p.rawValue, attackKey: a.rawValue, techniqueKey: t.rawValue))
                }
            }
        }
        return Profile(name: name, technics: items, isPreset: false)
    }
}


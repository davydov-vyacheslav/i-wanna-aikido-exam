//
//  ProfileDetailView.swift
//  aiki-exam
//
//  Created by Slava Davydov on 03.03.2026.
//

import SwiftUI
import SwiftData

struct ProfileDetailView: View {
    @Bindable var profile: Profile
    @Environment(\.modelContext) private var ctx
    @Environment(\.editMode)     private var editMode
    @Environment(\.dismiss)      private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var vocabStore: VocabularyStore
    @State private var showBulkAdd = false

    var body: some View {
        List {
            statsSection
            actionsSection
            technicsSection
        }
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: editToolbar)
        .sheet(isPresented: $showBulkAdd) {
            ProfileWizardView(targetProfile: profile)
        }
    }

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }
    
    @ToolbarContentBuilder
    private func editToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            EditButton()
                .opacity(profile.isPreset ? 0 : 1)
                .disabled(profile.isPreset)
        }
    }

    private var statsSection: some View {
        Section {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    if !profile.isPreset && isEditing {
                        TextField(".placeholder.profile.name", text: $profile.name)
                            .font(.headline)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, 4)
                    } else {
                        Text(profile.name).font(.subheadline)
                    }
                    Text(".label.profile.technics_count \(profile.technics.count)")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if settings.activeProfileID == profile.id {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var actionsSection: some View {
        Section {
            if settings.activeProfileID != profile.id {
                Button { settings.activeProfileID = profile.id } label: {
                    Label(".button.profile.set_current", systemImage: "checkmark.circle")
                }
            }
            Button(action: cloneAndDismiss) {
                Label(".button.profile.clone", systemImage: "doc.on.doc")
            }
            if !profile.isPreset {
                Button { showBulkAdd = true } label: {
                    Label(".button.profile.add_technics", systemImage: "plus.circle")
                }
            }
        }
    }

    private var technicsSection: some View {
        let positions = vocabStore.positions.filter { pos in
            profile.technics.contains { $0.positionKey == pos.key }
        }

        return ForEach(positions, id: \.key) { pos in
            let technics = profile.technics.filter { $0.positionKey == pos.key }
            Section(pos.displayName) {
                ForEach(technics) { tc in
                    HStack {
                        Text(vocabStore.displayName(for: tc.attackKey, type: .attack))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(vocabStore.displayName(for: tc.techniqueKey, type: .technique))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.callout)
                }
                .onDelete(perform: profile.isPreset ? nil : { offsets in
                    deleteTechnics(at: offsets, in: technics)
                })
            }
        }
    }

    private func deleteTechnics(at offsets: IndexSet, in group: [TechnicItem]) {
        let idsToDelete = Set(offsets.map { group[$0].id })
        profile.technics.removeAll { idsToDelete.contains($0.id) }
    }

    private func moveTechnics(from source: IndexSet, to destination: Int) {
        guard !profile.isPreset else { return }
        var t = profile.technics
        t.move(fromOffsets: source, toOffset: destination)
        profile.technics = t
    }

    private func cloneAndDismiss() {
        ctx.insert(profile.clone(name: String(localized: ".label.profile.copiedFrom \(profile.name)")))
        dismiss()
    }
}

// MARK: – TechnicRow

struct TechnicRow: View {
    let tc: TechnicItem
    let vocabStore: VocabularyStore

    var body: some View {
        HStack(spacing: 8) {
            Text(vocabStore.displayName(for: tc.positionKey, type: .position))
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.secondary)
                .font(.callout)
            Text(vocabStore.displayName(for: tc.attackKey, type: .attack))
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
            Text(vocabStore.displayName(for: tc.techniqueKey, type: .technique))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.red)
                .font(.callout)
        }
        .padding(.vertical, 2)
    }
}

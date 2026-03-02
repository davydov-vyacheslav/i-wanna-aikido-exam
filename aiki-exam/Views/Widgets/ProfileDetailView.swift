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
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
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
        Section(header: Text(".title.profile.technics")) {
            technicsList
        }
    }

    private var technicsList: some View {
        ForEach(profile.technics) { tc in
            TechnicRow(tc: tc)
        }
        .onDelete(perform: deleteTechnicsIfAllowed)
        .onMove(perform: moveTechnicsIfAllowed)
    }

    private func deleteTechnicsIfAllowed(at offsets: IndexSet) {
        guard !profile.isPreset else { return }
        var t = profile.technics
        t.remove(atOffsets: offsets)
        profile.technics = t
    }

    private func moveTechnicsIfAllowed(from source: IndexSet, to destination: Int) {
        guard !profile.isPreset else { return }
        var t = profile.technics
        t.move(fromOffsets: source, toOffset: destination)
        profile.technics = t
    }

    // MARK: – Actions

    private func cloneAndDismiss() {
        let cloned = profile.clone(name: String(localized: ".label.profile.copiedFrom \(profile.name)"))
        ctx.insert(cloned)
        dismiss()
    }

    private func deleteAndDismiss() {
        if settings.activeProfileID == profile.id {
            settings.activeProfileID = nil
        }
        ctx.delete(profile)
        dismiss()
    }
}

// MARK: – TechnicRow

struct TechnicRow: View {
    let tc: TechnicItem

    var body: some View {
        HStack(spacing: 8) {
            Text(MasterPositions.init(rawValue: tc.positionKey)!.l10n)
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.secondary)
                .font(.callout)
            Text(MasterAttacks.init(rawValue: tc.attackKey)!.l10n)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
            Text(MasterTechnics.init(rawValue: tc.techniqueKey)!.l10n)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.red)
                .font(.callout)
        }
        .padding(.vertical, 2)
    }
}

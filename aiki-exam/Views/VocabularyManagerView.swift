//
//  VocabularyManagerView.swift
//  aiki-exam
//
//  Created by Slava Davydov on 03.05.2026.
//

import SwiftUI
import SwiftData

struct VocabularyManagerView: View {
    @EnvironmentObject private var vocabStore: VocabularyStore
    @Query private var allProfiles: [Profile]

    // Add sheet state
    @State private var addType:    VocabularyType?
    @State private var addName     = ""
    @State private var addPronounce = ""
    // Rename alert state
    @State private var renameItem: VocabularyItem?
    @State private var renameName  = ""
    @State private var renamePronounce  = ""
    // Error alert
    @State private var errorMsg:   String?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(VocabularyType.allCases) { type in
                    Section(type.sectionTitle) {
                        ForEach(vocabStore.items(for: type), id: \.id) { item in
                            row(item)
                        }
                        Button {
                            addType = type
                            addName = ""
                            addPronounce = ""
                        } label: {
                            Label("Add \(type.label)", systemImage: "plus.circle")
                                .font(.callout)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.accentColor)
                    }
                }
            }
            .navigationTitle(".title.vocabulary")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $addType) { type in
                addSheet(type: type)
            }
            // ── Rename alert ──
            .alert("Rename", isPresented: Binding(
                get: { renameItem != nil },
                set: { if !$0 { renameItem = nil } }
            )) {
                TextField(".label.vocabulary.displayName", text: $renameName)
                TextField(".label.vocabulary.pronounce", text: $renamePronounce)
                Button(".button.common.cancel", role: .cancel) { renameItem = nil }
                Button(".button.common.save") { commitRename() }
            }
            .alert(".error.common.cant_complete", isPresented: Binding(
                get: { errorMsg != nil },
                set: { if !$0 { errorMsg = nil } }
            )) {
                Button(".button.common.ok", role: .cancel) { errorMsg = nil }
            } message: {
                Text(errorMsg ?? "")
            }
        }
    }

    // MARK: – Row

    @ViewBuilder
    private func row(_ item: VocabularyItem) -> some View {
        HStack {
            Text(item.displayName)

            Spacer()

            Button {
                ExamAudio.shared.speakNow(text: vocabStore.resolvedSpeechText(for: item))
            } label: {
                Image(systemName: "speaker.wave.2")
                    .foregroundColor(.secondary)
                    .font(.callout)
            }
            .buttonStyle(.borderless)

            let isLocked = allProfiles.contains(where: { p in p.technics.contains { tc in
                switch item.type {
                case .position:  return tc.positionKey  == item.key
                case .attack:    return tc.attackKey    == item.key
                case .technique: return tc.techniqueKey == item.key
                }
            }})
            Image(systemName: "lock.fill")
                .font(.caption2)
                .foregroundColor(.secondary)
                .opacity(isLocked ? 1 : 0)

        }
        .contentShape(Rectangle())
        .onTapGesture {
            renameItem = item
            renameName = item.displayName
            renamePronounce = item.pronunciation ?? ""
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                attemptDelete(item)
            } label: {
                Label(".button.common.delete", systemImage: "trash")
            }
        }
    }

    // MARK: – Add sheet

    @ViewBuilder
    private func addSheet(type: VocabularyType) -> some View {
        NavigationStack {
            Form {
                Section(".label.vocabulary.displayName") {
                    TextField(".placeholder.vocabulary.displayName", text: $addName)
                        .autocorrectionDisabled()
                    TextField(".placeholder.vocabulary.pronounce", text: $addPronounce)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("New \(type.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(".button.common.cancel") { addType = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(".button.common.add") { commitAdd(type: type) }
                        .disabled(addName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(220)])
    }

    // MARK: – Actions

    private func commitAdd(type: VocabularyType) {
        do {
            try vocabStore.add(displayName: addName, type: type, pronounce: addPronounce)
            addType = nil
        } catch {
            addType = nil
            errorMsg = error.localizedDescription
        }
    }

    private func commitRename() {
        guard let item = renameItem else { return }
        do {
            try vocabStore.rename(item, to: renameName, pronounce: renamePronounce)
        } catch {
            errorMsg = error.localizedDescription
        }
        renameItem = nil
    }

    private func attemptDelete(_ item: VocabularyItem) {
        do {
            try vocabStore.delete(item, allProfiles: allProfiles)
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

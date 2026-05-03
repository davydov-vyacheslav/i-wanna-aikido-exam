import SwiftUI
import SwiftData

// MARK: – ProfilesView

struct ProfilesView: View {
    @Environment(\.modelContext) private var ctx
    @EnvironmentObject private var settings: AppSettings
    @Query(
        filter: #Predicate<Profile> { !$0.isPreset },
        sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(
        filter: #Predicate<Profile> { $0.isPreset },
        sort: \Profile.createdAt) private var presets: [Profile]
    @State private var pendingDelete: Profile?
    
    var body: some View {
        NavigationStack {
            List {
                // Presents Profiles
                if !presets.isEmpty {
                    Section(header: Text(".title.profiles.presets")) {
                        ForEach(presets) { preset in
                            NavigationLink(destination: ProfileDetailView(profile: preset)) {
                                ProfileRow(profile: preset, isActive: preset.id == settings.activeProfileID)
                                    .swipeActions(edge: .trailing) {
                                        if preset.id != settings.activeProfileID {
                                            Button(role: .destructive) {
                                                pendingDelete = preset
                                            } label: {
                                                Label(".button.common.delete", systemImage: "trash")
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
                
                // User Profiles
                Section(header: Text(".title.profiles.user")) {
                    ForEach(profiles) { profile in
                        NavigationLink(destination: ProfileDetailView(profile: profile)) {
                            ProfileRow(profile: profile, isActive: profile.id == settings.activeProfileID)
                                .swipeActions(edge: .trailing) {
                                    if profile.id != settings.activeProfileID {
                                        Button(role: .destructive) {
                                            pendingDelete = profile
                                        } label: {
                                            Label(".button.common.delete", systemImage: "trash")
                                        }
                                    }
                                }

                        }
                    }
                }


            }
            .navigationTitle(".title.profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
               ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileWizardView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert(".alert.profile.delete.title", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )) {
                Button(".button.common.cancel", role: .cancel) { pendingDelete = nil }
                Button(".button.common.delete", role: .destructive) {
                    guard let profile = pendingDelete else { return }
                    deleteProfile(p: profile)
                    pendingDelete = nil
                }
            }
        }
    }

    private func deleteProfile(p: Profile) {
        ctx.delete(p)
    }
}

// MARK: – UserProfileRow

private struct ProfileRow: View {
    let profile: Profile
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name)
                    .font(.subheadline)
                Text(".label.profile.technics_count \(profile.technics.count)")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}





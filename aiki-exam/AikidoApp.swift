import SwiftUI
import SwiftData

@main
struct AikidoApp: App {

    @StateObject private var settings = AppSettings.shared

    private static let container: ModelContainer = {
        let schema = Schema([Profile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container creation failed: \(error)") // TODO: user-fieldly message
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ExamView()
                    .tabItem {
                        Label(".title.exam", systemImage: "figure.martial.arts")
                    }

                ProfilesView()
                    .tabItem {
                        Label(".title.profiles", systemImage: "list.bullet.rectangle.portrait")
                    }

                SettingsView()
                    .tabItem {
                        Label(".title.settings", systemImage: "gearshape")
                    }
            }
            .environmentObject(settings)
            .modelContainer(AikidoApp.container)
            .task { await seedIfNeeded() }
        }
    }

    // MARK: – First-launch seed

    @MainActor
    private func seedIfNeeded() async {
        let ctx = AikidoApp.container.mainContext
        let count = (try? ctx.fetchCount(FetchDescriptor<Profile>())) ?? 0
        guard count == 0 else { return }

        // FIXME: sync each time based on profile version
        // Insert Aikikai as the default starter profile
        Presets.all.forEach { profile in
            ctx.insert(profile)
        }
        settings.activeProfileID = Presets.aikikai.id
    }
}

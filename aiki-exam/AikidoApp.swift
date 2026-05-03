import SwiftUI
import SwiftData

@main
struct AikidoApp: App {

    let container: ModelContainer = {
        let schema = Schema([Profile.self, VocabularyItem.self])
        return try! ModelContainer(for: schema)
    }()

    private var settings  = AppSettings.shared
    @StateObject private var vocabStore: VocabularyStore

    init() {
        // Build VocabStore with the container's main context.
        let ctx = container.mainContext
        let vs  = VocabularyStore(context: ctx)
        _vocabStore = StateObject(wrappedValue: vs)

        // Seed defaults on first launch (idempotent).
        DefaultsLoader.seedPresets(into: ctx, settings: settings)
        vs.refresh()

        // Activate Watch connectivity.
        // TODO: WatchBridge.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(settings)
                .environmentObject(vocabStore)
        }
    }
}

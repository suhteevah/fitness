import SwiftUI
import SwiftData

@main
struct PerformanceTrackerApp: App {
    @State private var dataController = DataController.shared

    init() {
        Log.app.info("PerformanceTracker launching…")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Each step is wrapped so a failure in one doesn't kill the launch.
                    Self.safeRun("seed") {
                        SeedData.seedIfNeeded(context: dataController.mainContext)
                    }
                    await Self.safeAsyncRun("healthkit-auth") {
                        do {
                            try await HealthKitService.shared.requestAuthorization()
                        } catch {
                            Log.healthKit.error("Initial HealthKit auth failed: \(error.localizedDescription)")
                        }
                    }
                    await Self.safeAsyncRun("abacus-restore") {
                        let abacusSettings = AbacusCredentials.loadSettings()
                        if abacusSettings.isConfigured {
                            await AbacusService.shared.configure(abacusSettings)
                            Log.app.info("Abacus configured from Keychain at launch")
                        }
                    }
                }
                .preferredColorScheme(.dark)
        }
        .modelContainer(dataController.container)
    }

    // MARK: - Defensive launch helpers

    private static func safeRun(_ name: String, _ block: () -> Void) {
        // Swift can't catch ObjC exceptions or fatalError here; this is just
        // logging discipline. Keeps stack traces in Console.app legible.
        Log.app.debug("launch step start: \(name)")
        block()
        Log.app.debug("launch step done: \(name)")
    }

    private static func safeAsyncRun(_ name: String, _ block: () async -> Void) async {
        Log.app.debug("launch step start: \(name)")
        await block()
        Log.app.debug("launch step done: \(name)")
    }
}

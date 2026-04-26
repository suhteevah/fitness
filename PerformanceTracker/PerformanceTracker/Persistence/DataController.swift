import Foundation
import SwiftData

/// Manages the SwiftData stack for the app.
///
/// Recovery strategy when init fails:
///   1. Try persistent store at default URL
///   2. If that fails (schema mismatch, file corruption, etc.) — wipe the
///      on-disk store and try fresh
///   3. If THAT fails — fall back to in-memory so the app at least launches
///
/// This prevents a stale on-device store with an obsolete schema from making
/// the whole app unlaunchable.
@MainActor
public final class DataController {
    public static let shared = DataController()

    public let container: ModelContainer

    private init() {
        let modelTypes: [any PersistentModel.Type] = [
            Assessment.self,
            HealthMetrics.self,
            ManualEntry.self,
            EatenMealLog.self,
            MealPrepBatch.self,
        ]

        // Attempt 1 — load persistent store at default URL
        do {
            container = try ModelContainer(
                for: Assessment.self, HealthMetrics.self, ManualEntry.self,
                    EatenMealLog.self, MealPrepBatch.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            Log.persistence.info("SwiftData container initialized (persistent)")
            return
        } catch {
            Log.persistence.error("SwiftData persistent init failed: \(error.localizedDescription) — wiping store and retrying")
        }

        // Attempt 2 — wipe on-disk store and try again
        Self.wipeOnDiskStore()
        do {
            container = try ModelContainer(
                for: Assessment.self, HealthMetrics.self, ManualEntry.self,
                    EatenMealLog.self, MealPrepBatch.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            Log.persistence.warning("SwiftData container re-initialized after store wipe")
            return
        } catch {
            Log.persistence.error("SwiftData persistent init STILL failed after wipe: \(error.localizedDescription) — falling back to in-memory")
        }

        // Attempt 3 — last resort, in-memory store. Data won't persist across launches
        // but at least the app boots and the user can see the UI.
        do {
            container = try ModelContainer(
                for: Assessment.self, HealthMetrics.self, ManualEntry.self,
                    EatenMealLog.self, MealPrepBatch.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            Log.persistence.error("SwiftData running in-memory — DATA WILL NOT PERSIST")
        } catch {
            // If even in-memory fails, the runtime is broken in a way we can't recover from.
            Log.persistence.error("SwiftData in-memory init failed: \(error.localizedDescription) — app cannot launch")
            fatalError("SwiftData fundamentally broken: \(error)")
        }

        _ = modelTypes  // silence unused
    }

    public var mainContext: ModelContext { container.mainContext }

    // MARK: - On-disk store wipe

    /// Delete the SwiftData persistent store files. Used as a recovery step when
    /// the on-disk schema is incompatible with the current model classes.
    private static func wipeOnDiskStore() {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        // SwiftData default store name is `default.store` (+ `default.store-shm` and `-wal`)
        for suffix in ["", "-shm", "-wal", "-journal"] {
            let url = appSupport.appendingPathComponent("default.store\(suffix)")
            do {
                if fm.fileExists(atPath: url.path) {
                    try fm.removeItem(at: url)
                    Log.persistence.info("Removed stale store file: \(url.lastPathComponent)")
                }
            } catch {
                Log.persistence.error("Could not remove \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        // Also try the iCloud-friendly default location
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            for suffix in ["", "-shm", "-wal", "-journal"] {
                let url = docs.appendingPathComponent("default.store\(suffix)")
                if fm.fileExists(atPath: url.path) {
                    try? fm.removeItem(at: url)
                }
            }
        }
    }
}

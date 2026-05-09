import Foundation
import os

/// Loads pre-computed daily/weekly/monthly aggregates of Matt's full HealthKit
/// export (~8.5 yrs, 2.5M records distilled to ~900 KB JSON).
///
/// Built by `scripts/aggregate-healthkit-export.py` and bundled into the app
/// at `Resources/HistoricalHealth/{daily,weekly,monthly}.json`.
///
/// Use this for trajectory charts, P1/P2/P3 baseline replays, and any view
/// that needs more history than the live HealthKit reads cover.
public enum HistoricalHealthLoader {

    private static let logger = Logger(
        subsystem: "com.ridgecellrepair.performancetracker",
        category: "HistoricalHealth"
    )

    /// Bucket-agnostic record. Fields are nil when the underlying day/week/month
    /// had no samples for that metric.
    public struct Bucket: Codable, Sendable {
        /// Daily for daily.json, "YYYY-Www" for weekly.json, "YYYY-MM" for monthly.json.
        public let key: String
        public let days: Int?

        // Average metrics
        public let hr: Double?
        public let rhr: Double?
        public let hrv: Double?
        public let walkHR: Double?
        public let rr: Double?
        public let spo2: Double?
        public let vo2max: Double?
        public let wristTemp: Double?
        public let bodyMass: Double?

        // Sum metrics
        public let steps: Double?
        public let distWalkRun: Double?
        public let distCycle: Double?
        public let activeKcal: Double?
        public let basalKcal: Double?
        public let exerciseMin: Double?
        public let standMin: Double?
        public let flights: Double?

        // Sleep
        public let sleepAvgMin: Double?
        public let sleepAvgHr: Double?

        // Workouts
        public let workoutCount: Int?
        public let workoutMin: Double?
    }

    public enum Granularity: String {
        case daily, weekly, monthly
    }

    private struct AvgField: Decodable {
        let avg: Double?
    }

    /// Daily.json shape is heterogeneous: avg fields are objects ({avg,min,max,n}),
    /// sum fields are bare numbers. We decode it manually.
    private static func decodeDaily(_ data: Data) throws -> [Bucket] {
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            throw NSError(domain: "HistoricalHealth", code: 1)
        }
        var out: [Bucket] = []
        out.reserveCapacity(dict.count)
        for (key, rec) in dict {
            func avg(_ k: String) -> Double? {
                (rec[k] as? [String: Any])?["avg"] as? Double
            }
            func num(_ k: String) -> Double? {
                rec[k] as? Double
            }
            let sleep = rec["sleep"] as? [String: Any]
            out.append(Bucket(
                key: key,
                days: 1,
                hr: avg("hr"),
                rhr: avg("rhr"),
                hrv: avg("hrv"),
                walkHR: avg("walkHR"),
                rr: avg("rr"),
                spo2: avg("spo2"),
                vo2max: avg("vo2max"),
                wristTemp: avg("wristTemp"),
                bodyMass: avg("bodyMass"),
                steps: num("steps"),
                distWalkRun: num("distWalkRun"),
                distCycle: num("distCycle"),
                activeKcal: num("activeKcal"),
                basalKcal: num("basalKcal"),
                exerciseMin: num("exerciseMin"),
                standMin: num("standMin"),
                flights: num("flights"),
                sleepAvgMin: sleep?["asleepMin"] as? Double,
                sleepAvgHr: (sleep?["asleepMin"] as? Double).map { $0 / 60 },
                workoutCount: rec["workoutCount"] as? Int,
                workoutMin: rec["workoutMin"] as? Double
            ))
        }
        return out.sorted { $0.key < $1.key }
    }

    /// weekly.json + monthly.json have flat numeric fields.
    private static func decodeFlat(_ data: Data) throws -> [Bucket] {
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            throw NSError(domain: "HistoricalHealth", code: 2)
        }
        var out: [Bucket] = []
        out.reserveCapacity(dict.count)
        for (key, rec) in dict {
            func num(_ k: String) -> Double? { rec[k] as? Double }
            out.append(Bucket(
                key: key,
                days: rec["days"] as? Int,
                hr: num("hr"),
                rhr: num("rhr"),
                hrv: num("hrv"),
                walkHR: num("walkHR"),
                rr: num("rr"),
                spo2: num("spo2"),
                vo2max: num("vo2max"),
                wristTemp: num("wristTemp"),
                bodyMass: num("bodyMass"),
                steps: num("steps"),
                distWalkRun: num("distWalkRun"),
                distCycle: num("distCycle"),
                activeKcal: num("activeKcal"),
                basalKcal: num("basalKcal"),
                exerciseMin: num("exerciseMin"),
                standMin: num("standMin"),
                flights: num("flights"),
                sleepAvgMin: num("sleepAvgMin"),
                sleepAvgHr: num("sleepAvgHr"),
                workoutCount: (rec["workoutCount"] as? Int)
                    ?? (rec["workoutCount"] as? Double).map(Int.init),
                workoutMin: num("workoutMin")
            ))
        }
        return out.sorted { $0.key < $1.key }
    }

    private static var cache: [Granularity: [Bucket]] = [:]

    public static func load(_ granularity: Granularity) -> [Bucket] {
        if let hit = cache[granularity] { return hit }
        let name: String
        switch granularity {
        case .daily:   name = "daily"
        case .weekly:  name = "weekly"
        case .monthly: name = "monthly"
        }
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "json",
            subdirectory: "HistoricalHealth"
        ) ?? Bundle.main.url(forResource: name, withExtension: "json") else {
            logger.error("Historical \(name).json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let buckets = granularity == .daily
                ? try decodeDaily(data)
                : try decodeFlat(data)
            cache[granularity] = buckets
            logger.info("Loaded \(buckets.count) \(name) historical buckets from \(url.lastPathComponent)")
            return buckets
        } catch {
            logger.error("Failed to decode \(name).json: \(error.localizedDescription)")
            return []
        }
    }

    /// Convenience: most recent N weekly buckets.
    public static func recentWeeks(_ n: Int) -> [Bucket] {
        Array(load(.weekly).suffix(n))
    }

    /// Convenience: range of daily buckets between two ISO-date strings (inclusive).
    public static func days(from start: String, to end: String) -> [Bucket] {
        load(.daily).filter { $0.key >= start && $0.key <= end }
    }
}

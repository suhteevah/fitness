import Foundation

/// Loads daily health + project-status JSON produced by the 11pm routine.
///
/// Search order (first hit wins):
/// 1. Bundled `Resources/data/` inside the app (for seed data shipped with app)
/// 2. App group iCloud Drive container (for Phase 2 sync)
/// 3. App documents directory (for in-app written data)
///
/// Source: docs/DAILY-DATA-ROUTINE.md
public enum DailyDataLoader {

    // Foundation's formatters are documented thread-safe but not Sendable in Swift 6.
    // We treat them as read-only after initialization.
    nonisolated(unsafe) private static let isoDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let s = try container.decode(String.self)
            // Try with fractional seconds first, then without
            if let date = isoDateFormatter.date(from: s) { return date }
            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withInternetDateTime]
            if let date = f2.date(from: s) { return date }
            // Try date-only
            let df = DateFormatter()
            df.calendar = .init(identifier: .iso8601)
            df.dateFormat = "yyyy-MM-dd"
            if let date = df.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid date: \(s)"
            )
        }
        return d
    }()

    /// Load the health file for a specific day. Returns nil if the file isn't found or fails to parse.
    public static func loadHealthDay(_ date: Date) -> HealthDaily? {
        let dateString = dayString(date)
        guard let data = read(relativePath: "data/health-daily/\(dateString).json") else {
            Log.persistence.debug("No health file for \(dateString)")
            return nil
        }
        do {
            return try decoder.decode(HealthDaily.self, from: data)
        } catch {
            Log.persistence.error("Health decode failed for \(dateString): \(error.localizedDescription)")
            return nil
        }
    }

    /// Load health files for a date range (inclusive). Missing days are skipped.
    public static func loadHealthRange(_ start: Date, _ end: Date) -> [HealthDaily] {
        let cal = Calendar(identifier: .iso8601)
        var out: [HealthDaily] = []
        var cursor = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        while cursor <= endDay {
            if let day = loadHealthDay(cursor) { out.append(day) }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return out
    }

    /// Load a single project-status day.
    public static func loadProjectStatus(_ date: Date) -> ProjectStatusDay? {
        let dateString = dayString(date)
        guard let data = read(relativePath: "data/project-status/\(dateString).json") else {
            Log.persistence.debug("No project-status file for \(dateString)")
            return nil
        }
        do {
            return try decoder.decode(ProjectStatusDay.self, from: data)
        } catch {
            Log.persistence.error("ProjectStatus decode failed for \(dateString): \(error.localizedDescription)")
            return nil
        }
    }

    public static func loadProjectStatusRange(_ start: Date, _ end: Date) -> [ProjectStatusDay] {
        let cal = Calendar(identifier: .iso8601)
        var out: [ProjectStatusDay] = []
        var cursor = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        while cursor <= endDay {
            if let day = loadProjectStatus(cursor) { out.append(day) }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return out
    }

    // MARK: - Private helpers

    private static func dayString(_ date: Date) -> String {
        let df = DateFormatter()
        df.calendar = .init(identifier: .iso8601)
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    /// Try bundle resource first, then app-group / documents.
    private static func read(relativePath: String) -> Data? {
        // 1. App bundle resource
        let components = relativePath.split(separator: "/").map(String.init)
        if let lastDot = components.last?.lastIndex(of: ".") {
            let name = String(components.last![..<lastDot])
            let ext = String(components.last![components.last!.index(after: lastDot)...])
            let subdir = components.dropLast().joined(separator: "/")
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir),
               let data = try? Data(contentsOf: url) {
                return data
            }
        }

        // 2. Documents directory (future: user may sync files here)
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = docs.appendingPathComponent(relativePath)
            if let data = try? Data(contentsOf: url) { return data }
        }

        return nil
    }
}

// MARK: - Health aggregation helpers

public enum HealthAggregator {
    /// Aggregate a range of daily health entries into a weekly `HealthMetricsSnapshot`.
    /// Averages per-day fields and sums the weekly fields.
    public static func weeklySnapshot(
        days: [HealthDaily],
        periodStart: Date,
        periodEnd: Date,
        periodId: String,
        trainingAlignmentScore: Double? = nil
    ) -> HealthMetricsSnapshot {
        let bodies = days.compactMap(\.health)
        func avgDouble(_ keyPath: KeyPath<HealthBody, Double?>) -> Double? {
            let vals = bodies.compactMap { $0[keyPath: keyPath] }
            guard !vals.isEmpty else { return nil }
            return vals.reduce(0, +) / Double(vals.count)
        }
        func avgInt(_ keyPath: KeyPath<HealthBody, Int?>) -> Double? {
            let vals = bodies.compactMap { $0[keyPath: keyPath] }.map(Double.init)
            guard !vals.isEmpty else { return nil }
            return vals.reduce(0, +) / Double(vals.count)
        }

        // Exercise min/week — sum, not average
        let exerciseTotal: Double? = {
            let vals = bodies.compactMap(\.exerciseMin).map(Double.init)
            return vals.isEmpty ? nil : vals.reduce(0, +)
        }()

        // Sleep duration hours — average per night
        let sleepHours: Double? = {
            let vals = bodies.compactMap(\.sleep).compactMap(\.durationHours)
            return vals.isEmpty ? nil : vals.reduce(0, +) / Double(vals.count)
        }()

        // Bedtime SD minutes — stddev of bedtimes (minutes past midnight)
        let bedtimeSD: Double? = {
            let minutesPastMidnight: [Double] = bodies.compactMap { body -> Double? in
                guard let bt = body.sleep?.bedtime else { return nil }
                let cal = Calendar.current
                let comps = cal.dateComponents([.hour, .minute], from: bt)
                // Shift late-night bedtimes (past midnight) to post-day range so we can average
                let minutes = Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
                return minutes < 12 * 60 ? minutes + 24 * 60 : minutes
            }
            guard minutesPastMidnight.count >= 2 else { return nil }
            let mean = minutesPastMidnight.reduce(0, +) / Double(minutesPastMidnight.count)
            let variance = minutesPastMidnight
                .map { ($0 - mean) * ($0 - mean) }
                .reduce(0, +) / Double(minutesPastMidnight.count)
            return variance.squareRoot()
        }()

        // Deep+REM percent
        let deepREMPct: Double? = {
            let fractions: [Double] = bodies.compactMap { body -> Double? in
                guard let stages = body.sleep?.stages,
                      let deep = stages.deepMin, let rem = stages.remMin,
                      let core = stages.coreMin else { return nil }
                let total = Double(deep + rem + core)
                guard total > 0 else { return nil }
                return Double(deep + rem) / total
            }
            guard !fractions.isEmpty else { return nil }
            return fractions.reduce(0, +) / Double(fractions.count)
        }()

        // Weight delta — last minus first in period
        let weightDelta: Double? = {
            let weights = bodies.compactMap(\.weightLb)
            guard let first = weights.first, let last = weights.last, weights.count >= 2 else { return nil }
            let weeks = max(1.0, Date().timeIntervalSince(periodStart) / (7 * 24 * 3600))
            return (last - first) / weeks
        }()

        return HealthMetricsSnapshot(
            periodId: periodId, periodStart: periodStart, periodEnd: periodEnd,
            stepsPerDay: avgInt(\.steps),
            activeCalPerDay: avgInt(\.activeKcal),
            basalEnergyPerDay: avgInt(\.basalKcal),
            exerciseMinPerWeek: exerciseTotal,
            restingHR: avgInt(\.restingHRBpm),
            hrv: avgDouble(\.hrvSDNNms),
            walkingHR: avgInt(\.walkingHRBpm),
            respiratoryRate: avgDouble(\.respiratoryRateBpm),
            vo2Max: avgDouble(\.vo2MaxMlKgMin),
            sleepHoursPerNight: sleepHours,
            bedtimeSDminutes: bedtimeSD,
            deepPlusREMPercent: deepREMPct,
            weightLb: avgDouble(\.weightLb),
            weightDeltaLbPerWeek: weightDelta,
            trainingAlignmentScore: trainingAlignmentScore
        )
    }
}

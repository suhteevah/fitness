import Foundation
import HealthKit

/// All HealthKit access for the app. On-device only — HealthKit data NEVER leaves the device.
///
/// Auth flow:
/// 1. Check `HKHealthStore.isHealthDataAvailable()`
/// 2. Call `requestAuthorization` with all 7 read types
/// 3. Query per-type weekly aggregates
///
/// Nil handling: any metric the user declined returns nil; grading algorithm treats nil
/// as missing and may return `.incomplete` if >50% of inputs are nil.
public actor HealthKitService {
    public static let shared = HealthKitService()

    private let store = HKHealthStore()

    /// The 7 quantity types we read.
    public static let readTypes: Set<HKQuantityType> = {
        let ids: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .appleExerciseTime,
            .walkingHeartRateAverage,
            .basalEnergyBurned,
        ]
        return Set(ids.compactMap { HKQuantityType.quantityType(forIdentifier: $0) })
    }()

    public enum HealthKitError: Error {
        case notAvailable
        case authorizationDenied
        case queryFailed(String)
    }

    public var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    public func requestAuthorization() async throws {
        guard isAvailable else {
            Log.healthKit.error("HealthKit not available on this device")
            throw HealthKitError.notAvailable
        }
        Log.healthKit.info("Requesting HealthKit authorization for \(Self.readTypes.count) types")
        do {
            try await store.requestAuthorization(toShare: [], read: Self.readTypes)
            Log.healthKit.info("HealthKit authorization granted (or previously decided)")
        } catch {
            Log.healthKit.error("HealthKit auth failed: \(error.localizedDescription)")
            throw HealthKitError.authorizationDenied
        }
    }

    /// Fetch weekly aggregated metrics for the given period.
    /// Returns a Sendable snapshot — callers on `@MainActor` build the SwiftData @Model.
    public func fetchWeeklyMetrics(periodStart: Date, periodEnd: Date, periodId: String) async -> HealthMetricsSnapshot {
        Log.healthKit.info("Fetching HealthKit metrics for \(periodId) [\(periodStart)...\(periodEnd)]")

        async let steps       = sumPerDay(.stepCount, unit: .count(), start: periodStart, end: periodEnd)
        async let activeCal   = sumPerDay(.activeEnergyBurned, unit: .kilocalorie(), start: periodStart, end: periodEnd)
        async let rhr         = averageQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: periodStart, end: periodEnd)
        async let hrv         = averageQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: periodStart, end: periodEnd)
        async let exercise    = sumTotal(.appleExerciseTime, unit: .minute(), start: periodStart, end: periodEnd)
        async let walkingHR   = averageQuantity(.walkingHeartRateAverage, unit: HKUnit.count().unitDivided(by: .minute()), start: periodStart, end: periodEnd)
        async let basalCal    = sumPerDay(.basalEnergyBurned, unit: .kilocalorie(), start: periodStart, end: periodEnd)

        let snapshot = HealthMetricsSnapshot(
            periodId: periodId,
            periodStart: periodStart,
            periodEnd: periodEnd,
            stepsPerDay: await steps,
            activeCalPerDay: await activeCal,
            basalEnergyPerDay: await basalCal,
            exerciseMinPerWeek: await exercise,
            restingHR: await rhr,
            hrv: await hrv,
            walkingHR: await walkingHR
        )
        Log.healthKit.info("HealthKit fetch complete: available fields = \(snapshot.availableFieldCount)")
        return snapshot
    }

    // MARK: - Internal queries

    private func sumPerDay(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let total = await sumTotal(id, unit: unit, start: start, end: end) else { return nil }
        let days = max(1, Calendar.current.daysBetween(start, end))
        return total / Double(days)
    }

    private func sumTotal(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double?, Never>) in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, err in
                if let err {
                    Log.healthKit.error("Sum query failed for \(id.rawValue): \(err.localizedDescription)")
                    cont.resume(returning: nil); return
                }
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func averageQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double?, Never>) in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, err in
                if let err {
                    Log.healthKit.error("Average query failed for \(id.rawValue): \(err.localizedDescription)")
                    cont.resume(returning: nil); return
                }
                cont.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    /// Today's step count — for Watch quick view.
    public func stepsToday() async -> Int? {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Date.now
        guard let v = await sumTotal(.stepCount, unit: .count(), start: start, end: end) else { return nil }
        return Int(v)
    }
}

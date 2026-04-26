import Foundation
import SwiftData

/// A manually-entered data point. Keyed by date + kind.
@Model
public final class ManualEntry {
    public var kind: EntryKind.RawValue
    public var date: Date
    public var note: String?

    // Polymorphic payload (only one is set per entry, by kind)
    public var amountUSD: Double?        // revenue
    public var clientName: String?       // revenue
    public var source: String?           // revenue (paypal, stripe, direct, kalshi)
    public var mealPlanFollowed: Bool?   // meal plan
    public var workoutType: String?      // workout
    public var workoutDurationMin: Int?  // workout
    public var hoursWorked: Double?      // hours log

    public init(
        kind: EntryKind,
        date: Date = .now,
        note: String? = nil,
        amountUSD: Double? = nil,
        clientName: String? = nil,
        source: String? = nil,
        mealPlanFollowed: Bool? = nil,
        workoutType: String? = nil,
        workoutDurationMin: Int? = nil,
        hoursWorked: Double? = nil
    ) {
        self.kind = kind.rawValue
        self.date = date
        self.note = note
        self.amountUSD = amountUSD
        self.clientName = clientName
        self.source = source
        self.mealPlanFollowed = mealPlanFollowed
        self.workoutType = workoutType
        self.workoutDurationMin = workoutDurationMin
        self.hoursWorked = hoursWorked
    }

    public var entryKind: EntryKind {
        EntryKind(rawValue: kind) ?? .note
    }
}

public enum EntryKind: String, Codable, CaseIterable, Sendable {
    case revenue
    case mealPlan
    case workout
    case hoursWorked
    case kalshiPnL
    case clientMeeting
    case note
}

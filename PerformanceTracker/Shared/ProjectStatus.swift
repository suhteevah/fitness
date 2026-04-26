import Foundation

/// Daily project-status JSON (schema: `project-status.v1`).
/// Produced by the 11pm Claude routine. See docs/DAILY-DATA-ROUTINE.md.
public struct ProjectStatusDay: Codable, Sendable, Identifiable {
    public let schema: String
    public let date: String            // "YYYY-MM-DD"
    public let capturedAt: Date
    public let projects: [ProjectEntry]
    public let clients: [ClientEntry]
    public let strategicEvents: [StrategicEvent]?
    public let kalshiPnLUSD: Double?
    public let notes: String?

    public var id: String { date }

    enum CodingKeys: String, CodingKey {
        case schema, date, projects, clients, notes
        case capturedAt = "captured_at"
        case strategicEvents = "strategic_events"
        case kalshiPnLUSD = "kalshi_pnl_usd"
    }
}

public struct ProjectEntry: Codable, Sendable, Identifiable {
    public let name: String
    public let path: String
    public let languagePrimary: String?
    public let commitsToday: Int
    public let commitsThisWeek: Int
    public let linesChangedToday: Int
    public let linesChangedThisWeek: Int
    public let handoffExcerpt: String?
    public let milestonesHit: [String]
    public let blockers: [String]

    public var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, path, blockers
        case languagePrimary = "language_primary"
        case commitsToday = "commits_today"
        case commitsThisWeek = "commits_this_week"
        case linesChangedToday = "lines_changed_today"
        case linesChangedThisWeek = "lines_changed_this_week"
        case handoffExcerpt = "handoff_excerpt"
        case milestonesHit = "milestones_hit"
    }
}

public struct ClientEntry: Codable, Sendable, Identifiable {
    public let name: String
    public let contact: String?
    public let lastDeliverableDate: String?   // ISO date string
    public let lastContactDate: String?
    public let daysSinceContact: Int?
    public let invoiceTotalThisPeriodUSD: Double?
    public let statusNote: String?

    public var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, contact
        case lastDeliverableDate = "last_deliverable_date"
        case lastContactDate = "last_contact_date"
        case daysSinceContact = "days_since_contact"
        case invoiceTotalThisPeriodUSD = "invoice_total_this_period_usd"
        case statusNote = "status_note"
    }
}

public struct StrategicEvent: Codable, Sendable {
    public let date: String
    public let type: String
    public let detail: String
}

// MARK: - Weekly rollup helpers

public struct ProjectStatusPeriod: Sendable {
    public let periodStart: Date
    public let periodEnd: Date
    public let days: [ProjectStatusDay]

    /// Sum of commits across all projects in the period.
    public var commitsThisPeriod: Int {
        days.flatMap(\.projects).map(\.commitsToday).reduce(0, +)
    }

    /// Sum of lines changed across all projects in the period.
    public var linesChangedThisPeriod: Int {
        days.flatMap(\.projects).map(\.linesChangedToday).reduce(0, +)
    }

    /// Union of milestones hit across the period.
    public var milestonesHit: [String] {
        days.flatMap(\.projects).flatMap(\.milestonesHit)
    }

    /// Active engagements (clients with any activity in the period).
    public var activeEngagements: Int {
        Set(days.flatMap(\.clients).map(\.name)).count
    }

    /// Invoices sent — approximated by clients with invoice total > 0.
    public var invoicesSent: Int {
        days.flatMap(\.clients).filter { ($0.invoiceTotalThisPeriodUSD ?? 0) > 0 }.count
    }

    /// Revenue total across the period.
    public var totalRevenueUSD: Double {
        days.flatMap(\.clients).compactMap(\.invoiceTotalThisPeriodUSD).reduce(0, +)
    }

    public init(periodStart: Date, periodEnd: Date, days: [ProjectStatusDay]) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.days = days
    }
}

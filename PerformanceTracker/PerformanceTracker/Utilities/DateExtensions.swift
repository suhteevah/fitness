import Foundation

public extension Date {
    /// Start of ISO-week containing this date, in the current calendar.
    func startOfISOWeek(calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2  // Monday, per ISO 8601
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: comps) ?? self
    }

    /// End of ISO-week (exclusive).
    func endOfISOWeek(calendar: Calendar = .current) -> Date {
        let start = startOfISOWeek(calendar: calendar)
        return calendar.date(byAdding: .day, value: 7, to: start) ?? self
    }

    /// ISO period identifier like "2026-W17".
    var isoPeriodId: String {
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return String(format: "%04d-W%02d", comps.yearForWeekOfYear ?? 0, comps.weekOfYear ?? 0)
    }
}

public extension Calendar {
    /// Days between two dates (rounded down to full days).
    func daysBetween(_ start: Date, _ end: Date) -> Int {
        let s = startOfDay(for: start)
        let e = startOfDay(for: end)
        return dateComponents([.day], from: s, to: e).day ?? 0
    }
}

/// Convenience: build a Date from `YYYY-MM-DD` (UTC).
public func dateFrom(_ isoDay: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
    return formatter.date(from: isoDay) ?? .distantPast
}

import Foundation
import OSLog

/// Centralized loggers. Verbose by default — Matt's preference.
/// Subsystem: `com.ridgecellrepair.performancetracker`
public enum Log {
    public static let subsystem = "com.ridgecellrepair.performancetracker"

    public static let app         = Logger(subsystem: subsystem, category: "app")
    public static let healthKit   = Logger(subsystem: subsystem, category: "healthkit")
    public static let assessment  = Logger(subsystem: subsystem, category: "assessment")
    public static let rubric      = Logger(subsystem: subsystem, category: "rubric")
    public static let persistence = Logger(subsystem: subsystem, category: "persistence")
    public static let viewModel   = Logger(subsystem: subsystem, category: "viewmodel")
    public static let watch       = Logger(subsystem: subsystem, category: "watch")
    public static let oauth       = Logger(subsystem: subsystem, category: "oauth")
    public static let gmail       = Logger(subsystem: subsystem, category: "gmail")
    public static let github      = Logger(subsystem: subsystem, category: "github")
}

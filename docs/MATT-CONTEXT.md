# Matt-Context, Conventions, Tech Stack

Operational context for Claude Code sessions on PerformanceTracker. Everything that doesn't change often lives here so `CLAUDE.md` stays lean.

## Matt-Specific Context

- **Communication:** terse, single-sentence pivots, no preamble expected
- **Velocity:** extremely high. *"Last time you told me 10 years and I did it in a weekend."* Don't overestimate timelines.
- **Diet:** keto, animal-based, no pork. Safeway/Raley's in Chico. Rotates meal plans from Claude, sticks rock-solid.
- **Fitness goal:** muscle gain + cardio endurance (shifted from weight loss). Weight 196 lbs. Target 2,200 kcal/day. TDEE ~2,840. Zone 2 target 114-133 bpm.
- **HRV is the single most important health metric** — was in crisis at 42ms, recovered to 86ms through nutrition alone.
- **Recreation flags during crisis:** Factorio, WoW TBC Classic, VATSIM, MTG Commander, baking. Track but do not ignore.
- **Calendar has been historically empty** — persistent issue, itself a grading signal.
- **Financial situation is tight** — free-tier / self-hosted only. No paid APIs.
- **30-day homelessness deadline** was the original framing (~Feb 16 2026); still the pressure context.
- **Apple Fitness+ subscription** exists but not consistently used.

For clients, key projects, key repos, and historical periods, see `HISTORICAL-DATA.md`.

## Tech Stack (Phase 1)

- **Swift 6** strict concurrency, iOS 17+, watchOS 10+
- **SwiftUI + SwiftData + Swift Charts** — no third-party deps
- **HealthKit, WatchKit, WatchConnectivity** — native frameworks only
- **URLSession + ASWebAuthenticationSession** for OAuth (Phase 2)
- **os.Logger** with subsystem `com.ridgecellrepair.performancetracker` — verbose logging everywhere

See `ARCHITECTURE.md` for full file structure and rationale.

## Conventions

- `@Observable` macro for view models (not `ObservableObject`)
- `SwiftData` for persistence (not CoreData directly)
- `Swift Charts` for all visualizations
- VoiceOver labels on all grade displays and charts
- **Dark mode is the primary design target** (Matt uses dark mode)
- Grade colors: A=emerald, B=blue, C=amber, D=orange, F=red
- Deterministic grading — same metrics in, same grade out (enables unit tests)

## Testing Strategy

- Unit tests for grading engine — deterministic: given metrics, expect specific grade
- Unit tests for Gmail deduplication (Phase 2)
- Integration tests for HealthKit guarded by `HKHealthStore.isHealthDataAvailable()`
- Snapshot tests for `GradeRingView` across A/B/C/D/F color states
- Manual testing on Matt's actual devices before any release
- macOS host test target (`PerformanceTrackerHostTests`) runs pure-logic tests on iMac CPU — iOS Simulator unusable on this Haswell/OCLP iMac.

## Assessment Data Model (summary)

```swift
struct WeeklyAssessment {
    let periodId: String          // e.g., "2026-W17"
    let periodStart: Date
    let periodEnd: Date
    let overallGrade: Grade
    let overallGPA: Double
    let categories: [CategoryAssessment]
    let priorPeriodComparison: PeriodComparison?
    let recommendations: [String]
    let dataSourcesUsed: [DataSource]
    let generatedAt: Date
}
```

Full model + grading algorithm in `GRADING-RUBRIC.md`.

## Seed Data

Historical P1/P2/P3 assessments (see `HISTORICAL-DATA.md`) seed on first launch so Matt sees his trajectory from day one:
- P1 (Feb 16-22): C+ (2.3)
- P2 (Feb 23 – Mar 19): B+ (3.3)
- P3 (Mar 20 – Apr 8): A- (3.7)

## Phase Roadmap

**Phase 1 — MVP** (current). HealthKit auth + weekly aggregation, grade engine (health), SwiftData models, Dashboard, Health detail, manual entry, basic Watch app. See `HANDOFF.md` for live task list.

**Phase 2.** Gmail/GitHub integrations + full 7-category engine + Calendar.

**Phase 3.** Optional Rust backend (`BACKEND-SPEC.md`), push, export, trend analysis.

## SwiftData iOS 26 gotchas

- `[String: String]` and `[String]` stored `@Model` properties trap an internal assertion on read. Workaround: store as JSON-encoded `String`, decode lazily via computed property. Applied in `Assessment.swift`.
- `DataController` uses 3-step recovery: persistent → wipe + retry → in-memory fallback. Never let a stale schema brick the launch.

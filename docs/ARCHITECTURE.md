# Architecture

## System Diagram

```
┌─────────────────────────────────────────────────────────┐
│  iOS App (SwiftUI)                                      │
│  ┌──────────────┐ ┌────────────┐ ┌─────────────────┐    │
│  │  Dashboard   │ │  Category  │ │  Historical     │    │
│  │  (Overall    │ │  Detail    │ │  Trend          │    │
│  │   Grade)     │ │  Views     │ │  Charts         │    │
│  └──────────────┘ └────────────┘ └─────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │  HealthKit Integration                          │    │
│  │  (direct on-device, no API needed)              │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                         │
                         │  WCSession (WatchConnectivity)
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Apple Watch App (SwiftUI)                              │
│  ┌──────────────┐ ┌────────────┐ ┌─────────────────┐    │
│  │  Grade Ring  │ │  Health    │ │  Quick Actions  │    │
│  │  Complication│ │  Summary   │ │  (log walk)     │    │
│  └──────────────┘ └────────────┘ └─────────────────┘    │
└─────────────────────────────────────────────────────────┘

   ── PHASE 2 ────────────────────────────────────── REST API ──▶

┌─────────────────────────────────────────────────────────┐
│  Backend API (Rust + Axum) — Optional, Phase 3          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐       │
│  │  Gmail   │  │  GitHub  │  │  Assessment      │       │
│  │  Scanner │  │  Scanner │  │  Engine          │       │
│  └──────────┘  └──────────┘  └──────────────────┘       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐       │
│  │ Calendar │  │Anthropic │  │  Grading         │       │
│  │  Scanner │  │ API (opt)│  │  Rubric          │       │
│  └──────────┘  └──────────┘  └──────────────────┘       │
│         ▼                                               │
│  ┌─────────────────────┐                                │
│  │  SQLite DB          │                                │
│  │  (local-first)      │                                │
│  └─────────────────────┘                                │
└─────────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Language | Swift 6 strict concurrency | no data races, Matt prefers modern |
| UI | SwiftUI | iOS 17+, @Observable, Swift Charts |
| Min iOS | 17.0 | @Observable, latest Charts features |
| Min watchOS | 10.0 | Latest SwiftUI on Watch |
| Architecture | MVVM + Repository | testable, clean separation |
| Local Storage | SwiftData | CoreData successor, macro-driven |
| Health | HealthKit | on-device only — never leaves device |
| Charts | Swift Charts | native, no 3rd party |
| Watch | WatchKit + WatchConnectivity | native |
| Networking (Phase 2) | URLSession + async/await | native, no Alamofire |
| Auth (Phase 2) | OAuth 2.0 + PKCE via `ASWebAuthenticationSession` | secure, native |
| Notifications | Local notifications | no server push needed in MVP |
| Logging | `os.Logger` | native, persists to sysdiagnose |

## Screens — iOS

1. **Dashboard (Main)**
   - Large circular grade ring with overall letter grade (A=emerald, B=blue, C=amber, D=orange, F=red)
   - 7 category cards below with individual grades + sparkline trend
   - Period selector (swipe between weeks)
   - "Generate Report" button → triggers AssessmentEngine

2. **Category Detail**
   - Full grade history chart (line, all periods)
   - Current metrics vs baseline comparisons
   - Data points that drove the grade
   - Recommendations section

3. **Health Dashboard**
   - HealthKit metrics with Swift Charts (steps, HRV, RHR, active cal, exercise min)
   - Week-over-week comparison
   - Target zones highlighted (green=good, red=concern)
   - Meal plan adherence toggle (daily)
   - Workout log (daily)

4. **Job Search Dashboard** *(Phase 2)*
   - Applications this period
   - Grouped by company
   - Rejection / interview / offer pipeline
   - Quality score (% matching target roles)

5. **Revenue Dashboard**
   - Revenue this period vs prior
   - Active clients with last-contact date
   - Pipeline estimate
   - Kalshi P&L chart

6. **GitHub Activity** *(Phase 2)*
   - Commits this week
   - Repos updated
   - LoC estimate
   - Contribution graph

7. **Settings**
   - Gmail OAuth connection *(Phase 2)*
   - GitHub PAT entry *(Phase 2)*
   - Assessment period (weekly/biweekly/monthly)
   - Notification prefs
   - Manual data entry

## Apple Watch App

**Complication** — circular gauge with grade letter, updates weekly.

**Watch Screens**
1. Grade Ring — overall grade with color
2. Health Quick View — today's steps, HRV, RHR
3. Quick Actions — "Log Walk", "Log Meal Plan Followed", "Log Workout"
4. Category Summary — scrollable list of 7 categories with grades

**WatchConnectivity**
- Phone → Watch: assessment data via `WCSession`
- Watch → Phone: quick-log entries back to Phone
- Background refresh for complication updates

## File Structure

```
PerformanceTracker/
├── project.yml                      # xcodegen definition
├── PerformanceTracker/              # iOS app
│   ├── App/
│   │   ├── PerformanceTrackerApp.swift
│   │   └── ContentView.swift
│   ├── Models/
│   │   ├── Assessment.swift
│   │   ├── Category.swift
│   │   ├── Grade.swift
│   │   ├── HealthMetrics.swift
│   │   ├── GitHubActivity.swift       (Phase 2)
│   │   ├── JobSearchMetrics.swift     (Phase 2)
│   │   ├── RevenueMetrics.swift
│   │   └── ManualEntry.swift
│   ├── ViewModels/
│   │   ├── DashboardViewModel.swift
│   │   ├── HealthViewModel.swift
│   │   ├── JobSearchViewModel.swift   (Phase 2)
│   │   ├── RevenueViewModel.swift
│   │   └── GitHubViewModel.swift      (Phase 2)
│   ├── Views/
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift
│   │   │   ├── GradeRingView.swift
│   │   │   ├── CategoryCardView.swift
│   │   │   └── TrendSparklineView.swift
│   │   ├── Health/
│   │   │   ├── HealthDashboardView.swift
│   │   │   ├── HRVChartView.swift
│   │   │   └── MealPlanToggleView.swift
│   │   ├── JobSearch/                 (Phase 2)
│   │   ├── Revenue/
│   │   │   ├── RevenueView.swift
│   │   │   └── ClientListView.swift
│   │   ├── GitHub/                    (Phase 2)
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       └── OAuthSetupView.swift   (Phase 2)
│   ├── Services/
│   │   ├── HealthKitService.swift
│   │   ├── GmailService.swift         (Phase 2)
│   │   ├── GitHubService.swift        (Phase 2)
│   │   ├── AssessmentEngine.swift
│   │   └── GradingRubric.swift
│   ├── Persistence/
│   │   ├── DataController.swift
│   │   └── SeedData.swift
│   ├── Utilities/
│   │   ├── Logger.swift
│   │   ├── DateExtensions.swift
│   │   └── GradeColors.swift
│   ├── Resources/
│   │   ├── Info.plist
│   │   └── PerformanceTracker.entitlements
│   └── Assets.xcassets/
├── PerformanceTrackerWatch/          # Watch app
│   ├── App/
│   │   └── PerformanceTrackerWatchApp.swift
│   ├── Views/
│   │   ├── GradeRingWatchView.swift
│   │   ├── HealthQuickView.swift
│   │   ├── QuickActionsView.swift
│   │   └── CategorySummaryView.swift
│   ├── Complications/
│   │   └── GradeComplication.swift   (Phase 2)
│   ├── Connectivity/
│   │   └── WatchSessionManager.swift
│   └── Resources/
│       ├── Info.plist
│       └── PerformanceTrackerWatch.entitlements
├── Shared/                           # iOS + Watch
│   ├── GradeCalculation.swift
│   └── WatchMessage.swift
└── Tests/
    ├── AssessmentEngineTests.swift
    ├── GradingRubricTests.swift
    └── HealthGradingTests.swift
```

## Why xcodegen

Matt's dev box is Windows (kokonoe). `.xcodeproj` is a binary-ish plist that's unfriendly to generate from scripts. `xcodegen` takes a `project.yml` and emits an `.xcodeproj`. The repo checks in `project.yml` + Swift sources; on Mac, `brew install xcodegen && xcodegen` produces the Xcode project. Keeps the source of truth textual and cross-platform.

## Color Scheme

| Grade | Color | SwiftUI |
|-------|-------|---------|
| A+ / A / A- | emerald | `.green` (adjusted) |
| B+ / B / B- | blue | `.blue` |
| C+ / C / C- | amber | `.orange` (light) |
| D+ / D / D- | orange | `.orange` (dark) |
| F | red | `.red` |
| Incomplete | gray | `.gray` |

Dark mode is the primary design target. All colors must pass WCAG AA contrast against the default dark background.

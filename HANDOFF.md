# HANDOFF.md — Session State

**Last Updated:** 2026-04-24
**Status:** PHASE 1 BUILDS ON SIMULATOR — TESTS AWAITING iMac POWER-CYCLE

## Current State

PDFs converted to clean markdown. CLAUDE.md trimmed to 7.7K. Details split into `docs/`. Phase 1 Swift scaffold deployed to iMac and **`** BUILD SUCCEEDED **`** on iOS Simulator (iPhone 17 Pro, iOS 17+, Swift 6 strict concurrency). Watch target also built clean.

**Fixes made during first build:**
1. Introduced `HealthMetricsSnapshot` (Sendable struct) so `HealthKitService` (actor) can return data across MainActor — `@Model` classes aren't Sendable. Main actor builds the `@Model` from snapshot.
2. Disambiguated `Category` in tests from Obj-C's `objc_category *` typedef (`PerformanceTracker.Category`).
3. Explicit `Grade.a` in `XCTAssertEqual` where type inference failed.

**iMac network change:** DHCP moved iMac from `192.168.168.110` → `192.168.168.192` (MAC `0c:4d:e9:98:ac:f5`). Updated `~/.ssh/config` and wiki `fleet/iMac.md`.

**Toolchain:** xcodegen was not on iMac; bootstrapped from source via `swift build -c release` at `~/Developer/XcodeGen/.build/release/xcodegen`. No brew needed.

**Current blocker:** iMac crashed during test run (thermal — wiki warned this happens under heavy compile load on OCLP/Haswell). Needs physical power cycle. When back: `ssh imac && cd ~/Developer/PerformanceTracker && xcodebuild ... test` will run the fixed tests.

## Phase 1.5 — additions from this session (code complete, rebuild pending)

**New docs:**
- `docs/DESIGN-SYSTEM.md` — Soft Iris primary + Honey Gold + Sea Glass Teal accents
- `docs/TRAINING-INTELLIGENCE.md` — workout→meal feedback loop, TRIMP, meal templates
- `docs/DAILY-DATA-ROUTINE.md` — 11pm Claude routine spec + JSON schemas

**Grading rubric expanded:**
- Physical Health now uses 12 signals (HRV, RHR, sleep duration / consistency / stages, steps, exercise, meal plan, respiratory rate, VO2max, weight trend, training alignment) + HRV trend bonus
- Product Development gradeable in Phase 1.5 from project-status JSON (no GitHub API required)
- Client Work pulls both manual entries AND project-status harvest
- Strategy defaults to `.b` once project-status present

**New code (24 files changed/added):**
- `Shared/WorkoutProfile.swift` — DietProfile enum, WorkoutKind, WorkoutProfile, RecoveryScore, MattPhysiology
- `Shared/MealTemplate.swift` — MacroTotals, MealContextTag, MealTemplate
- `Shared/HealthDaily.swift` — Codable for `health-daily.v1` JSON
- `Shared/ProjectStatus.swift` — Codable for `project-status.v1` JSON + weekly rollup
- `Shared/Grade.swift` — new palette (Brand enum + GradeColorFamily refactor)
- `Services/TrainingLoad.swift` — TRIMP + acute:chronic + alignment score
- `Services/KetoAnimalTemplates.swift` — 12 seed meal templates
- `Services/MealRecommender.swift` — context classifier + deterministic recommender
- `Services/GradingRubric.swift` — expanded `gradeHealth` (12 signals) + new `gradeProductDevelopment`
- `Services/DailyDataLoader.swift` — loads daily JSON + `HealthAggregator.weeklySnapshot`
- `Services/AssessmentEngine.swift` — wired to prefer daily JSON, grade Product Dev + Strategy, compute alignment
- `Models/HealthMetrics.swift` — expanded with sleep / resp / VO2max / weight fields (+ snapshot)
- `Views/Health/TrainingLoadCard.swift` — new card + NextMealCard
- `Views/Health/HealthDashboardView.swift` — added Training Load + Next Meal + Sleep cards
- `ViewModels/HealthViewModel.swift` — training intelligence load path
- `App/ContentView.swift`, `Views/Revenue/RevenueView.swift` — palette updates
- `Assets.xcassets/AccentColor` (iOS + Watch) — Soft Iris
- `Tests/GradingRubricTests.swift` — expanded for new rubric + TrainingLoad + MealRecommender

**Data infrastructure:**
- `data/README.md` — directory contract + privacy note
- `data/ROUTINE-PROMPT.md` — copy-paste template for `/schedule` registration
- `data/meal-plans/keto-animal-templates.json` — same 12 templates, loadable at runtime
- `data/health-daily/` and `data/project-status/` — empty, waiting for first routine run
- `data/.gitignore` — privacy guidance for fork case

**Pending next time iMac is up:**
1. ✅ ~~tar + ssh changed files~~ — done
2. ✅ ~~Re-run xcodegen~~ — done, picked up all 9 new Swift files via globs
3. ✅ ~~xcodebuild build~~ — **`** BUILD SUCCEEDED **`** after fixing 3 minor issues:
    - `ISO8601DateFormatter` static needed `nonisolated(unsafe)` (Swift 6 strict)
    - `JSONDecoder` static did NOT need it (warning if applied — JSONDecoder IS Sendable)
    - SeedData + HealthKitService had to reorder named args to match new HealthMetrics declaration order
4. ❌ `xcodebuild test` — iMac thermal-crashed during test run. Need another power cycle.
5. After power cycle: try **build-for-testing then test-without-building** as separate ssh calls to spread thermal load. Use iPhone 16e sim instead of 17 Pro (smaller → less load).
6. If tests green, proceed to iPhone 17 Pro Max device deploy

**Update 2026-04-24 evening:** Tried split approach with iPhone 16e sim. Result:
- ✅ `** TEST BUILD SUCCEEDED **` — test bundle compiles
- ❌ Sim boot crashed iMac again (Connection reset by peer)
- Conclusion: the issue is **iOS Simulator boot itself** on Haswell+OCLP, not build load.

**Resolution — macOS host tests (no simulator):** ✅ **WORKING**
- Added `PerformanceTrackerHostTests` target to `project.yml` with `platform: macOS`
- Renamed `Category` enum → `GradeCategory` (avoided `<objc/runtime.h>` typedef collision that caused ambiguous-lookup errors on host)
- Build via `xcodebuild build-for-testing -scheme PerformanceTrackerHost`
- Run via `xcrun xctest <bundle>` (skips testmanagerd which doesn't work cleanly over headless SSH)

**Test result 2026-04-24 20:19 PT:**
```
Test Suite 'All tests' passed
Executed 23 tests, with 0 failures (0 unexpected) in 0.100 seconds
```

iMac uptime 23min, load 1.4, no thermal stress. Sim-free workflow works.

**iOS Simulator is dead to us going forward** — `project.yml` no longer has an iOS test target. Beta testing happens on the real iPhone 17 Pro Max + Watch Ultra 3.

## Next: device deploy

iPhone 17 Pro Max currently `unavailable` per `xcrun devicectl list devices` — needs USB + unlock. Watch Ultra 3 (Watch7,12) shows `available (paired)`. When Matt plugs in his phone:

```bash
ssh imac 'cd ~/Developer/PerformanceTracker && xcodebuild \
  -project PerformanceTracker.xcodeproj \
  -scheme PerformanceTracker \
  -sdk iphoneos \
  -configuration Debug \
  -destination "id=AED90991-6134-50E6-B973-450072EAEB35" \
  -allowProvisioningUpdates \
  -jobs 1 \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=PVDSP4G3L4 \
  CODE_SIGN_IDENTITY="Apple Development" \
  ONLY_ACTIVE_ARCH=YES \
  build'
```

Expect HealthKit entitlement to potentially block on free Apple ID — fall back to manual entry path if so. Watch app auto-installs to Watch Ultra 3 via WatchConnectivity pairing.

**Action item for Matt:**
- Paste your 4 meal prep plans + shop lists — I'll normalize them into `data/meal-plans/*.json` replacing the 12-template seed
- Register the 11pm routine via `/schedule` using the prompt in `data/ROUTINE-PROMPT.md` (continue in your existing health chat so connectors stay live)

## What's Been Done

- [x] Three complete manual performance assessments (P1/P2/P3) with Claude
- [x] Grading rubric defined and validated across 3 real assessment cycles
- [x] All data sources identified and access methods documented (`docs/DATA-SOURCES.md`)
- [x] Historical baseline data captured (`docs/HISTORICAL-DATA.md`)
- [x] iOS + Watch app architecture designed (`docs/ARCHITECTURE.md`)
- [x] File structure defined
- [x] Assessment engine data model specified (`docs/GRADING-RUBRIC.md`)
- [x] Health grading algorithm with real thresholds from actual data
- [x] PDFs converted to real `.md` files (originals in `pdf-backup/`)
- [x] `CLAUDE.md` trimmed to <40k, details moved into `docs/`

## Phase 1 — MVP Scaffold (Complete)

- [x] `project.yml` (xcodegen) defining iOS + Watch targets + Tests
- [x] Swift source scaffold (Models, ViewModels, Views, Services, Persistence)
- [x] HealthKit service — auth for 7 metrics, weekly aggregation
- [x] `Grade` enum + `GradingRubric` implementation
- [x] `AssessmentEngine` (health + revenue + client; Phase 2 categories → .incomplete)
- [x] SwiftData models: Assessment, HealthMetrics, ManualEntry
- [x] DashboardView + GradeRingView + CategoryCardView + TrendSparklineView
- [x] HealthDashboardView with metric cards + meal plan toggle + workout log
- [x] RevenueView with add-revenue sheet
- [x] SettingsView with HealthKit re-auth
- [x] Watch app: Grade Ring, Health Quick View, Quick Actions, Category Summary
- [x] WatchSessionManager (iOS + Watch sides of WCSession)
- [x] Unit tests: GradingRubricTests, AssessmentEngineTests
- [x] Seed data for P1/P2/P3 historical assessments (SeedData.historicalAssessments)
- [x] README with xcodegen + xcodebuild commands
- [x] Info.plist with HealthKit usage descriptions + ATS leaf pinning stubs
- [x] Entitlements files for iOS + Watch

## Phase 1 — Remaining (requires Mac / iMac online)

- [ ] Wake iMac — ping fails from gateway, probably needs power cycle per wiki
- [ ] `rsync` to `~/Developer/PerformanceTracker/` on iMac
- [ ] `brew install xcodegen` on iMac (one-time)
- [ ] `xcodegen` to produce `PerformanceTracker.xcodeproj`
- [ ] First-time: open `.xcodeproj` in Xcode GUI to generate provisioning profile (free Apple ID constraint)
- [ ] `xcodebuild` for iPhone 17 Pro Max (`AED90991-6134-50E6-B973-450072EAEB35`)
- [ ] **Risk:** HealthKit entitlement may be blocked on free Apple ID — if so, fall back to manual entry until paid enrollment
- [ ] Run `xcodebuild test` — watch for any type issues on real SwiftData/WatchConnectivity APIs
- [ ] Verify on-device: HealthKit auth prompt, dashboard shows P1/P2/P3 trajectory, manual entry works

## Phase 2 — API Integrations (deferred)

1. Gmail OAuth (PKCE) for `ridgecellrepair@gmail.com`
2. Gmail scanner — queries from `docs/DATA-SOURCES.md`, dedupe by company+role
3. GitHub API (PAT) — commits, repos, events
4. Full 7-category engine (not just health)
5. Watch complication with grade letter

## Phase 3 — Backend + Polish (deferred)

1. Optional Rust/Axum backend on kokonoe (`docs/BACKEND-SPEC.md`)
2. Push notifications for weekly report ready
3. Markdown + PDF export of assessments
4. Trend predictions — simple linear regression on grade trajectory

## Known Constraints

- Target devices unknown (iPhone + Apple Watch; assume watchOS 10+ for latest SwiftUI)
- Matt uses dark mode — primary design target
- kokonoe (i9-11900K + RTX 3070 Ti, Win10 Pro) available via Tailscale as backend host
- Gmail MCP OAuth tokens won't transfer → new Google Cloud OAuth client required
- `mmichels88@gmail.com` is a separate account, NOT connected — needs its own OAuth
- Most valuable GitHub repos are private → PAT with `repo` scope required
- Apple Health data cannot leave device per HealthKit guidelines
- Financial situation tight → free-tier / self-hosted only, no paid APIs

## Environment

- Xcode 16+ (Swift 6, iOS 17+, watchOS 10+)
- Native frameworks only initially (no CocoaPods/SPM deps)
- HealthKit, SwiftUI, SwiftData, Swift Charts, WatchKit, WatchConnectivity
- OAuth: native URLSession + ASWebAuthenticationSession for PKCE (Phase 2)
- Dev machine: kokonoe (Windows) — scaffold cross-platform via xcodegen; final build on Mac

## Testing Strategy

- Unit tests — grading engine (deterministic)
- Unit tests — Gmail dedupe (Phase 2) (Greenhouse sends 2+ per app)
- Integration tests — HealthKit guarded by `HKHealthStore.isHealthDataAvailable()`
- Snapshot tests — grade ring states (A/B/C/D/F colors)
- Manual testing on Matt's devices before any release

## Notes for Claude Code

- Matt communicates in very short, terse messages. Single-sentence pivots.
- Matt's velocity is extremely high — don't overestimate timelines.
- Verbose logging (`os.Logger`) everywhere — non-negotiable preference.
- Admin PowerShell available on Windows if build scripts needed.
- **The grading rubric in `docs/GRADING-RUBRIC.md` is SOURCE OF TRUTH.** If Matt asks to change grading criteria, update that file.
- All historical P1/P2/P3 data in `docs/HISTORICAL-DATA.md` should be seeded into the app.

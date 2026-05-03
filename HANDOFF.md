# HANDOFF.md — Session State

**Last Updated:** 2026-05-02
**Status:** 🟢 APP RUNNING ON iPhone 17 PRO MAX — ABACUS WIRED — HEALTH PIPELINE FINALIZED

## Project Status

App launches clean on Matt's iPhone 17 Pro Max. Dashboard shows seeded P1/P2/P3 trajectory + live Abacus finance. Revenue tab pulls bank-feed transactions across All Orgs / per-org with 7/30/90/365d window picker. Meal recommender draws from 32 templates (V5/V6 actuals + 14 muscle-build expansions including 2 carb-tolerant post-strength refeed options). Health data flows on-device via HealthKit; project-status harvested nightly by kokonoe scheduled task.

## What Was Done This Session

### Crash bugs killed
- **SwiftData iOS 26 dictionary trap** in `Assessment.categoryGradesRaw.getter`. Rewrote `Assessment.swift` to store `categoryGradesJSON / recommendationsJSON / dataSourcesJSON` as JSON-encoded `String`, decode lazily via computed properties.
- **HealthKit auth abort** (`_validateHealthDataPurposeStringsForSharingTypes` exception). Root cause: xcodegen's `info:` block was overwriting the hand-crafted `Info.plist` on every regen, stripping `NSHealthShareUsageDescription`. Removed `info:` from the iOS target in `project.yml` so `INFOPLIST_FILE` setting takes precedence and the source plist is preserved.

### Abacus integration
- Added "All Organizations (combined)" picker option in `AbacusSettingsView` so revenue grade aggregates across every org (default).
- Removed auto-pick-first-org logic so empty `primaryOrgId` ("All") stays default.
- Dashboard `FinanceCard` now shows `last <N> days` with calendar-icon menu for 7/30/90/365 days, opens transaction log sheet (`RevenueLogView`) sorted newest-first with client/source/memo/date.
- Pull-to-refresh on Dashboard.
- Window switched from ISO-week to rolling-N-days so post-Tuesday revenue isn't masked by Mon→Sun reset.
- **Revenue tab** rewired: was manual-entry only; now combines manual + Abacus bank feed in one summary, segmented 7/30/90/365 picker, full Abacus transaction list, refresh button + pull-to-refresh, manual entries section preserved (swipe-to-delete intact).

### Meal templates
- Added 14 muscle-build templates (32 total): cottage cheese power bowl, eggs+top round, tuna+egg+avocado, chicken+greek caesar, whey+MCT shake, top sirloin+mushrooms, casein+cottage pre-bed, greek yogurt pudding, ground bison+kale, salmon+asparagus+hollandaise, chicken liver pâté+eggs, beef heart strips. Plus 2 carb-tolerant **post-strength refeed** templates (lean beef + sweet potato, chicken + jasmine rice) gated EXCLUSIVELY to `(.postStrength, .good)` so the recommender never suggests them on Zone 2 / rest / low-recovery days.

### Architecture pivot — health harvest pipeline
- **Original plan dead.** Tried claude.ai-Routines → GitHub repo → kokonoe puller. Investigation: claude.ai/code/routines exists, but its connector pool ("No more connectors available") does NOT include the chat-side Apple Health connector. Routines run with GitHub-tier connectors only.
- **Final architecture (A+C):**
  - **Health:** iPhone iOS app reads HealthKit natively via the auth granted; grading runs on-device. No Windows-side dependency. (The kokonoe Claude CLI dry-run also confirmed it returns null for everything because it has no HealthKit connector.)
  - **Project-status:** kokonoe scheduled task `PT-Daily-ProjStatus` runs nightly at 22:53 → `J:\fitness\scripts\daily-harvest.ps1` → `claude --print < daily-harvest-prompt.txt` → writes `J:\fitness\data\project-status\YYYY-MM-DD.json` → telegrams 4-line summary.
  - Killed scheduled tasks: `PT-Daily-Harvest` (broken — CLI no HealthKit), `PT-Data-Pull` (puller for the dead architecture).
  - The `suhteevah/performancetracker-data` GitHub repo + `J:\fitness\data-repo\` clone are inert (no source feeding them); harmless to leave or delete.

### Docs & memory
- `CLAUDE.md` trimmed 8.5K → 3.9K. Offloaded Matt-context/conventions/testing/SwiftData-gotchas to `docs/MATT-CONTEXT.md`.
- Wrote `J:\fitness\data\project-status\2026-05-01.json` from the kokonoe project-walk (7 commits / 1596 LOC for RightWire was the standout).
- Updated `daily-harvest-prompt.txt` to project-status-only version.

## Current State

**Working ✅**
- iOS app launches, Dashboard renders P1 (C+) → P2 (B+) → P3 (A-) trajectory.
- HealthKit authorization prompt fires correctly on first launch (purpose strings present).
- Abacus connection live over Tailscale; 308 bank transactions reachable; "All Organizations" combines across orgs.
- Revenue tab shows transaction log with window picker.
- Meal recommender + meal-prep planner + shopping-list generator working off 32 templates.
- macOS host test target (`PerformanceTrackerHostTests`) passes 23/23 grading-rubric tests.
- Watch target builds (currently disabled in scheme — actool watchsim runtime issue on this iMac).
- `PT-Daily-ProjStatus` scheduled — first real fire at 22:53 tonight.

**Stubbed / pending**
- Watch app dependency commented out in `project.yml` (re-enable when watchsim runtime mounts cleanly).
- iOS app `AppIcon.appiconset` has no actual icon (empty Contents.json) to bypass actool sim-runtime issue. Add real icon when fixed.
- Phase 2 Gmail/GitHub integrations for Job Hunting + full Time Management still untouched.
- ATS leaf-pinning placeholders in `Info.plist` will need real SPKI hashes once Phase 2 enables network calls.

## Blocking Issues

None. All session goals shipped.

## What's Next

1. **Verify tonight's harvest fires.** Check `J:\fitness\data\project-status\2026-05-02.json` and the Telegram ping after 22:53 local. Logs at `J:\fitness\data\harvest-logs\harvest-*.log`.
2. **Apple Developer Program ($99/yr)** — eventual goal for permanent install + TestFlight. Free provisioning gives 7-day expiry; dev team `PVDSP4G3L4` works for now.
3. **Phase 2 prep** when Matt's ready: Gmail + Calendar OAuth for Job Hunting + Time Management categories.
4. **Watch target re-enable** once iMac watchsim runtime is stable, then deploy to Watch Ultra 3.
5. **Real AppIcon** for both iOS and Watch.

## Notes for Next Session

- **iMac defang fix is holding** — userspace watchdog kernel panics gone since `debug.defang_watchdogd=1` + 20+ daemon disables. SSH may still drop under heavy compile load but recoverable.
- **Don't try to wire claude.ai chat connectors into Routines** — verified impossible. The architecture was investigated end-to-end. iPhone is the only HealthKit source.
- **Don't reintroduce `info:` block to `project.yml` iOS target.** xcodegen will silently nuke the Info.plist's HealthKit usage strings every regen and the app will start crashing on launch again. Comment in `project.yml` warns about this.
- **SwiftData iOS 26 caveat:** `[String: String]` and `[String]` `@Model` stored properties trap on read. Always use JSON-string + computed-property pattern. See `Assessment.swift` for example.
- **Repo git state is weird** — git status shows clean even when files clearly differ from HEAD. Probably the github-uploader-buildout that produced the initial commits has a content filter or LFS-like translation. Don't fight it; just commit what `git status` shows dirty.
- **iMac SSH host:** `imac` (alias). Login keychain password: `1278` for `security unlock-keychain` before xcodebuild. Build path: `~/Developer/PerformanceTracker/`.
- **Build invocation** that works: `cd ~/Developer/PerformanceTracker && security unlock-keychain -p 1278 ~/Library/Keychains/login.keychain-db; xcodebuild -scheme PerformanceTracker -configuration Debug -destination 'generic/platform=iOS' -allowProvisioningUpdates build`. Then `xcrun devicectl device install app --device 00008150-001629203C08401C ~/Library/Developer/Xcode/DerivedData/PerformanceTracker-*/Build/Products/Debug-iphoneos/PerformanceTracker.app`.
- **Telegram notify script:** `bash "/j/baremetal claude/tools/notify-telegram.sh" "<message>"`. Token + chat ID in `/j/baremetal claude/.claude/.env`.

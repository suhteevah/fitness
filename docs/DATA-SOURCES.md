# Data Sources

## 1. Apple Health (HealthKit — on-device)

**Access:** HealthKit framework, directly on iOS. No API. Watch → iPhone via WatchConnectivity.

**Auth:** `HKHealthStore.requestAuthorization(toShare:read:)`. Read-only for all metrics in MVP.

**Required Info.plist keys:**
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription` (required even if read-only in some cases)

**Required entitlement:** `com.apple.developer.healthkit = true`

### Metrics to Query (Weekly Aggregation)

| Metric | HealthKit Identifier | Stat Type | Unit |
|--------|----------------------|-----------|------|
| Steps | `HKQuantityTypeIdentifier.stepCount` | sum | count |
| Active Calories | `HKQuantityTypeIdentifier.activeEnergyBurned` | sum | kcal |
| Resting Heart Rate | `HKQuantityTypeIdentifier.restingHeartRate` | average | count/min |
| HRV (SDNN) | `HKQuantityTypeIdentifier.heartRateVariabilitySDNN` | average | ms |
| Exercise Minutes | `HKQuantityTypeIdentifier.appleExerciseTime` | sum | min |
| Walking Heart Rate | `HKQuantityTypeIdentifier.walkingHeartRateAverage` | average | count/min |
| Basal Energy | `HKQuantityTypeIdentifier.basalEnergyBurned` | sum | kcal |

### Query Pattern (Swift)

```swift
let startOfWeek = Calendar.current.date(from:
    Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)!

let predicate = HKQuery.predicateForSamples(withStart: startOfWeek, end: endOfWeek)
let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                              options: .discreteAverage) { _, stats, _ in
    let value = stats?.averageQuantity()?.doubleValue(for: .count().unitDivided(by: .minute()))
    // ...
}
```

### Historical Baselines (from real 3-period data)

| Metric | P1 Baseline (Feb) | P2 Low (Mar) | P3 Recovery (Apr) | Target |
|--------|-------------------|--------------|-------------------|--------|
| Steps/day | ~7,800 | ~4,700 | ~4,900 | 7,500+ |
| Active Cal/day | ~640 | ~347 | ~470 | 600+ |
| Resting HR | 66 bpm | 73 bpm | 60–66 bpm | <65 bpm |
| HRV | 57 ms | 42 ms | 68–86 ms | >60 ms |
| Exercise min/wk | ~50 | 13 (crisis) | 20–86 | >150 |
| Walking HR | ~107 bpm | 117 bpm | 97–112 bpm | <110 bpm |

---

## 2. Gmail (ridgecellrepair@gmail.com) — Phase 2

**Access:** Gmail API (OAuth 2.0) or Gmail MCP server (`https://gmailmcp.googleapis.com/mcp/v1`).

**Important:** Gmail MCP OAuth tokens likely won't transfer to a standalone iOS app. Register separate OAuth client in Google Cloud Console for the app. Use PKCE flow via `ASWebAuthenticationSession`.

### Weekly Queries

```
# Job application confirmations (Greenhouse / Lever / Ashby)
subject:"thank you for applying" OR subject:"application received" OR subject:"security code"

# Rejections
subject:"not move forward" OR subject:"decided not" OR subject:"unfortunately" OR subject:"other candidates"

# Interview invitations
subject:"interview" OR subject:"next steps" OR subject:"phone screen" OR subject:"schedule a"

# Client communications
from:fiverr.com OR subject:invoice OR subject:payment OR from:stripe.com

# Revenue signals
from:paypal OR from:venmo OR subject:"payment received" OR from:kalshi
```

### Known Patterns & Quirks

- **Dedupe by company+role.** Greenhouse sends security code + application-received email per submission. Don't count twice.
- Job Hunter agent generates Greenhouse security codes that auto-resolve.
- Agent-drafted Upwork replies are signed `-a ridgecell` and may sit in Drafts.
- Fiverr messages = 100% scammers. Flag but do NOT count as client comms or pipeline.
- Upwork: ~200 connects burned, 0 contacts after Jake Brander.

### Second Inbox (mmichels88@gmail.com)

**Not connected.** Matt uses it for some job apps (WinCo, Hudson Manpower). Would need separate OAuth client. **Don't assume this inbox is accessible.** Note missing data when interview callbacks fail to appear in `ridgecellrepair@gmail.com`.

---

## 3. GitHub (suhteevah) — Phase 2

**Access:** GitHub REST API v3 or GraphQL v4. Public repos unauthenticated. **Private repos need a PAT with `repo` scope.**

**Store PAT in Keychain**, not UserDefaults.

### Weekly Queries

```
# Contribution events for the week
GET /users/suhteevah/events  (filter by date range)

# Repository list + recently updated
GET /users/suhteevah/repos?sort=updated&per_page=100

# Commit activity per repo
GET /repos/suhteevah/{repo}/commits?since={week_start}&until={week_end}

# New repos created this week
Filter /users/suhteevah/repos by created_at
```

### Key Repos (as of April 2026)

| Repo | Status | Language | Lines | Significance |
|------|--------|----------|-------|--------------|
| claudioos (private?) | Active | Rust | 294,710 | Bare-metal Rust OS — flagship |
| wraith-browser (private) | Active | Rust | 27,000+ | AI agent browser — commercial |
| kalshi-weather-trader (private) | Active | JavaScript | Unknown | Prediction market bot — 20x |
| kalshi-trader-v7 (private) | Active | Rust | Unknown | Rust rewrite of Kalshi trader |
| openclaw-admin-mcp (private?) | Active | Rust | 6,241 | Fleet admin MCP server |
| docsync | Public | Shell | Small | Doc drift — 2 stars |
| depguard | Public | Shell | Small | Dependency audit |
| mpvhq-win64 | Public | GLSL | Legacy | mpv build — 7 stars |

**Important:** Most valuable repos are private. Public GitHub profile **undersells** Matt's actual output. Assessment must note when it can only see public activity.

---

## 4. Google Calendar — Phase 2

**Access:** Google Calendar API or Calendar MCP server (`https://calendarmcp.googleapis.com/mcp/v1`).

**What to check:** scheduled events in the assessment period.

**Signal:** Historically empty → itself a grading signal (negative for Time Management).

---

## 5. Claude Conversation History — Phase 3 (optional)

**Access:** Claude conversation search API (if available), or manual summary injection.

**What to extract:** topics, projects worked on, client deliverables created, time distribution across categories.

---

## 6. Subject-Reported (manual, iOS app) — Phase 1

Non-automatable inputs Matt enters in the app:

| Input | Screen |
|-------|--------|
| Revenue received (amount, source, client) | Revenue tab |
| Client meetings held | Revenue → Client detail |
| Meals followed from plan (yes/no daily toggle) | Health → Meal Plan |
| Workout completed (yes/no + type) | Health → Workout Log |
| Kalshi trader P&L (weekly snapshot) | Revenue → Kalshi card |
| Hours worked estimate | Settings → Weekly summary |

Stored as `ManualEntry` records in SwiftData, keyed by date + type.

## Data Source Enum

```swift
enum DataSource {
    case healthKit
    case gmail
    case github
    case googleCalendar
    case manualEntry
    case claudeConversations
}
```

Each `WeeklyAssessment` records which sources were used to produce it — lets the UI show data completeness.

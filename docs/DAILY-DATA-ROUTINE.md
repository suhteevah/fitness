# Daily Data Routine (11pm cron)

> How real data flows into PerformanceTracker before (and while) the iOS app exists.

## Why this exists

PerformanceTracker's grades are only as real as the data they see. Phase 1's on-device HealthKit read only works after Matt installs the app on his iPhone. Until then — and in parallel after — we fill the gap with a **scheduled Claude routine** that runs every night at 23:00 local.

The routine does two jobs:

1. **Harvest health data** from Matt's existing connector-enabled health chat and write it to `data/health-daily/YYYY-MM-DD.json`.
2. **Harvest project status** from local repos (Obsidian vault, HANDOFF.md files, git log) and write it to `data/project-status/YYYY-MM-DD.json`.

Both artifacts are read by PerformanceTracker on launch (once installed) and during assessment generation.

## Why 11pm

- Captures the full day (workouts, steps, calories finalized after bedtime routine)
- Sleep from *previous* night is confirmed by Apple Health by this time
- Matt's typical bedtime is later, so routine can prompt him if clarification is needed

## Schedule setup

Matt runs `/schedule` once to register the routine:

```
/schedule
```

Then configures:
- **Name:** `performance-tracker-daily`
- **Cron:** `0 23 * * *` (every day at 23:00 local)
- **Continue in chat:** the existing health-tracking thread (so connectors stay warm)
- **Prompt:** see below

The `/schedule` skill is user-triggered — Claude Code can't invoke it. I'll write the prompt template; Matt wires it up.

## Routine prompt template

```
You are the PerformanceTracker daily data collector.

Step 1 — Health harvest
Use the health connectors available in this chat to pull Apple Health data for
today (${date}). Capture: steps, active kcal, basal kcal, resting HR, HRV
(SDNN), exercise minutes, walking HR, sleep duration, sleep stages (deep/REM
minutes), bedtime, wake time, respiratory rate, blood O2 (if available),
VO2max, body weight (latest). Any workouts logged: kind, duration, avg HR.
Any nutrition/meal logs: name, calories, macros if present.

Step 2 — Project status harvest
For each project directory in J:\, read HANDOFF.md and recent git activity.
Tracked projects: ClaudioOS, Wraith Browser, Kalshi Trader v7, OpenClaw,
PerformanceTracker (J:\fitness). For each, capture: commits this period,
lines changed, milestones hit, explicit blockers. Also scan for client
activity (Incognito, First Choice Plastics, Midnight Munitions) and strategic
events (IP filings, launches, hardware purchases, revenue events).

Step 3 — Write outputs
Write two JSON files:
  - /j/fitness/data/health-daily/${date}.json (schema: health-daily.v1)
  - /j/fitness/data/project-status/${date}.json (schema: project-status.v1)

Use the exact schemas in /j/fitness/docs/DAILY-DATA-ROUTINE.md. Do not invent
fields. Use null for missing data. Preserve integer vs float types.

Step 4 — Summary
Post a brief summary to this chat: 3-line health summary, 3-line project
summary, any flags.
```

## JSON schemas

### `health-daily.v1`

Path: `data/health-daily/YYYY-MM-DD.json`

```jsonc
{
  "schema": "health-daily.v1",
  "date": "2026-04-24",
  "captured_at": "2026-04-24T23:00:00-07:00",
  "source": "claude-routine",         // or "apple-health-xml-import" later
  "health": {
    "steps": 5_123,
    "active_kcal": 412,
    "basal_kcal": 1980,
    "resting_hr_bpm": 62,
    "hrv_sdnn_ms": 78.0,
    "exercise_min": 30,
    "walking_hr_bpm": 108,
    "respiratory_rate_bpm": 14,
    "blood_o2_pct": 97,
    "vo2max_ml_kg_min": 38.2,
    "weight_lb": 196.4,
    "sleep": {
      "duration_hours": 7.8,
      "bedtime": "2026-04-23T23:12:00-07:00",
      "wake_time": "2026-04-24T07:00:00-07:00",
      "stages": {
        "awake_min": 24,
        "core_min": 245,             // Apple's Light
        "deep_min": 62,
        "rem_min": 137
      }
    },
    "workouts": [
      {
        "kind": "zone2",
        "duration_min": 30,
        "avg_hr_bpm": 118,
        "est_kcal": 245,
        "start_time": "2026-04-24T06:30:00-07:00",
        "notes": "treadmill incline"
      }
    ],
    "meals_logged": [
      {
        "name": "Ribeye + Butter Eggs",
        "kcal": 640,
        "protein_g": 50,
        "fat_g": 45,
        "carb_g": 3,
        "time": "2026-04-24T12:15:00-07:00",
        "matched_template_id": "keto-animal-001"
      }
    ]
  },
  "notes": null                       // any Claude-written commentary
}
```

All numeric fields are nullable — use `null` when the underlying metric wasn't available. Never use 0 as "missing" — 0 means actually zero.

### `project-status.v1`

Path: `data/project-status/YYYY-MM-DD.json`

```jsonc
{
  "schema": "project-status.v1",
  "date": "2026-04-24",
  "captured_at": "2026-04-24T23:00:00-07:00",
  "projects": [
    {
      "name": "ClaudioOS",
      "path": "/j/baremetal claude/",
      "language_primary": "rust",
      "commits_today": 14,
      "commits_this_week": 87,
      "lines_changed_today": 3420,
      "lines_changed_this_week": 18_240,
      "handoff_excerpt": "Latest: OAuth stack integrated. Next: Vulkan 1.3 render path.",
      "milestones_hit": ["OAuth stack integrated"],
      "blockers": []
    },
    {
      "name": "PerformanceTracker",
      "path": "/j/fitness/",
      "language_primary": "swift",
      "commits_today": 0,
      "commits_this_week": 0,
      "lines_changed_today": 0,
      "lines_changed_this_week": 0,
      "handoff_excerpt": "Phase 1 builds on simulator; awaiting iMac power-cycle to run tests.",
      "milestones_hit": ["Simulator build succeeded"],
      "blockers": ["iMac thermal crash"]
    }
  ],
  "clients": [
    {
      "name": "Incognito Acquisitions",
      "contact": "Seth Barone",
      "last_deliverable_date": "2026-04-12",
      "last_contact_date": "2026-04-20",
      "days_since_contact": 4,
      "invoice_total_this_period_usd": 0,
      "status_note": "NDA signed, paid work TBD"
    },
    {
      "name": "First Choice Plastics",
      "contact": "Cory Sturgis",
      "last_deliverable_date": "2026-04-18",
      "last_contact_date": "2026-04-22",
      "days_since_contact": 2,
      "invoice_total_this_period_usd": 0,
      "status_note": "Active troubleshooting; no billing structure yet"
    }
  ],
  "strategic_events": [
    { "date": "2026-04-24", "type": "milestone", "detail": "Wraith Browser IP protection playbook drafted" }
  ],
  "kalshi_pnl_usd": null,
  "notes": null
}
```

## Backfill plan

For historical periods we don't have nightly snapshots for:

1. **Apple Health XML export** (one-time): Matt does `Export All Health Data` from iOS Health app → shares the zip. We write a Swift parser (`HealthXMLImporter`) that reads `export.xml`, aggregates daily, and writes backfill files matching `health-daily.v1`.
2. **Git log backfill for projects** (scripted): `git log --since="2026-02-01" --until="2026-04-24" --numstat --pretty=format:'%ad|%H'` per tracked repo → synthesize past `project-status.v1` files.
3. **Claude chat history**: If Matt has weekly health summaries scattered in prior conversations, a one-off Claude routine can scrape them into backfill files.

Backfill files live alongside live ones in `data/health-daily/` and `data/project-status/`; the loader doesn't care about source.

## Loader (Swift)

```swift
public final class DailyDataLoader {
    public static func loadHealthDay(_ date: Date) -> HealthDaily? { … }
    public static func loadProjectStatus(_ date: Date) -> ProjectStatusDay? { … }
    public static func loadHealthRange(_ start: Date, _ end: Date) -> [HealthDaily] { … }
    public static func loadProjectStatusRange(_ start: Date, _ end: Date) -> [ProjectStatusDay] { … }
}
```

Files bundled with the app + optionally merged from an iCloud Drive folder (later). Phase 1: hardcoded to read from the repo's `data/` dir during dev; ship with a sync mechanism in Phase 2.

## Privacy

- JSON files live in the git repo. That repo is private.
- Never commit an actual `health-daily/*.json` to a public fork.
- If the app ever gets a public repo spin-off, `data/` is gitignored.

## Failure modes

- **Connector fails at 11pm**: routine writes `{"schema":"...","date":"...","source":"claude-routine","health":null,"error":"connector_timeout"}`. Loader skips null days. Grade algorithm sees a gap, marks period Incomplete if too many gaps.
- **Matt didn't wear watch**: most fields null. Expected; grade handles.
- **Repo unreadable from routine's sandbox**: logs error, project status for that day is null. Loader falls back to prior day's status.

## Later enhancements

- Replace Claude routine with direct iOS Shortcut → iCloud Drive → app (Phase 3)
- Route health summary to Telegram for Matt to read before bed
- Emit weekly digest automatically on Sundays
- Feed meal template preference learning from `meals_logged[].matched_template_id` trends

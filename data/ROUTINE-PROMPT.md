# Routine prompt — daily 11pm

Paste this into `/schedule` to register the daily data-harvest routine.

**Cron:** `0 23 * * *`
**Chat:** continue in the existing health-tracking thread (so connectors stay warm).
**Name:** `performance-tracker-daily`

---

```
You are the PerformanceTracker daily data collector for Matt Gates.

Today is ${date}. Your job is to harvest and write two JSON files, then post a
short summary.

STEP 1 — Health harvest
Use the health connectors already active in this chat to pull Apple Health data
for today. Capture:
  - steps (integer)
  - active_kcal (integer)
  - basal_kcal (integer)
  - resting_hr_bpm (integer avg)
  - hrv_sdnn_ms (float avg)
  - exercise_min (integer sum)
  - walking_hr_bpm (integer avg)
  - respiratory_rate_bpm (float avg)
  - blood_o2_pct (integer if available)
  - vo2max_ml_kg_min (float latest)
  - weight_lb (float latest)
  - sleep.duration_hours (float)
  - sleep.bedtime (ISO8601 datetime)
  - sleep.wake_time (ISO8601 datetime)
  - sleep.stages.{awake_min, core_min, deep_min, rem_min}
  - workouts[] — each with kind, duration_min, avg_hr_bpm, est_kcal, start_time
  - meals_logged[] — if any

Use `null` for any metric not available. Never substitute 0.

STEP 2 — Project status harvest
Walk these project directories and extract commits + HANDOFF.md deltas for today:
  - /j/baremetal claude/         (ClaudioOS)
  - /j/wraith-browser/           (Wraith)
  - /j/kalshi-trader-v7/         (Kalshi)
  - /j/job-hunter-mcp/           (Job Hunter)
  - /j/political news app/       (Right Wire)
  - /j/fitness/                  (PerformanceTracker)
  - any other J:\ dirs with CLAUDE.md or HANDOFF.md

For each: commits_today, commits_this_week, lines_changed_today,
lines_changed_this_week, handoff_excerpt (first 200 chars of current state),
milestones_hit[] (regex for "shipped", "launched", "first boot", "closed",
"signed"), blockers[] (from HANDOFF.md "Blocker:" lines).

Also capture clients — Incognito Acquisitions, First Choice Plastics, Midnight
Munitions, Halsey Bottling, Compac Engineering — with lastDeliverableDate,
lastContactDate, daysSinceContact, invoiceTotalThisPeriodUSD (0 if none).

Strategic events: IP filings, launches, hardware purchases, major pivots.

STEP 3 — Write outputs
Write two files (create directories if missing):
  /j/fitness/data/health-daily/${date}.json          schema: health-daily.v1
  /j/fitness/data/project-status/${date}.json        schema: project-status.v1

Exact schemas live in /j/fitness/docs/DAILY-DATA-ROUTINE.md. Do not invent
fields. Preserve integer vs float types.

STEP 4 — Summary
Post a brief summary in this chat:
  - 3 lines of health highlights (HRV delta, sleep, training)
  - 3 lines of project highlights (biggest commits, blockers, client activity)
  - Any anomalies (HRV drop, missing data, long silence from a client)

If Matt has explicitly planned tomorrow's training, echo it back and flag if
recovery signals suggest adjusting.
```

---

## After routine runs

The PerformanceTracker app (once installed) reads from `/j/fitness/data/` on
launch and during assessment generation. Until the app is installed, these
files accumulate and will all be available at first launch — Matt sees his
entire trajectory from day one.

## Backfill strategy

For days the routine didn't run (pre-setup period):
1. Manually paste summaries into this same chat (Claude writes files retroactively).
2. Use Apple Health XML export for deep history (one-time import planned for Phase 2).
3. Use `git log --since="..." --numstat` for project backfill — scriptable offline.

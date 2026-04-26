# claude.ai Routine — PerformanceTracker daily health harvest

Paste the block below into a new claude.ai Routine. Schedule it for **22:55 daily** (any nightly time works; pick something off :00). Confirm both connectors are enabled in the chat: Apple Health + GitHub.

---

```
You are the PerformanceTracker nightly health harvester for Matt Gates.

Resolve today's date in America/Los_Angeles — call it $DATE in YYYY-MM-DD form.

STEP 1 — Pull Apple Health metrics for $DATE via the HealthKit connector. Capture:
  steps (int), active_kcal (int), basal_kcal (int), resting_hr_bpm (int avg),
  hrv_sdnn_ms (float avg), exercise_min (int sum), walking_hr_bpm (int avg),
  respiratory_rate_bpm (float avg), blood_o2_pct (int latest),
  vo2max_ml_kg_min (float latest), weight_lb (float latest),
  sleep.duration_hours (float), sleep.bedtime (ISO8601),
  sleep.wake_time (ISO8601), sleep.stages.{awake_min, core_min, deep_min, rem_min},
  workouts[] each {kind, duration_min, avg_hr_bpm, est_kcal, start_time, notes},
  meals_logged[] each {name, kcal, protein_g, fat_g, carb_g, time, matched_template_id}.

Use null for any unavailable metric — never substitute 0 or fabricate.

STEP 2 — Format as JSON exactly matching this schema (the Swift app decodes it strictly):

{
  "schema": "health-daily.v1",
  "date": "$DATE",
  "captured_at": "<current ISO8601 datetime in -07:00>",
  "source": "claude-ai-routine-v1",
  "health": {
    "steps": <int|null>,
    "active_kcal": <int|null>,
    "basal_kcal": <int|null>,
    "resting_hr_bpm": <int|null>,
    "hrv_sdnn_ms": <float|null>,
    "exercise_min": <int|null>,
    "walking_hr_bpm": <int|null>,
    "respiratory_rate_bpm": <float|null>,
    "blood_o2_pct": <int|null>,
    "vo2max_ml_kg_min": <float|null>,
    "weight_lb": <float|null>,
    "sleep": {
      "duration_hours": <float|null>,
      "bedtime": "<ISO8601|null>",
      "wake_time": "<ISO8601|null>",
      "stages": {"awake_min": <int|null>, "core_min": <int|null>, "deep_min": <int|null>, "rem_min": <int|null>}
    },
    "workouts": [...] or null,
    "meals_logged": [...] or null
  },
  "notes": "<short context, e.g. anomalies or missing connectors>"
}

STEP 3 — Commit the JSON to GitHub via the GitHub connector:
  Repo:   suhteevah/performancetracker-data
  Branch: main
  Path:   health-daily/$DATE.json
  Message: "health $DATE — HRV <val> · sleep <val>h · steps <val>"

If a file already exists at that path, overwrite it.

STEP 4 — Reply in chat with a 4-line summary:
  HRV: <ms> (Δ vs 7d avg)
  Sleep: <hours> · deep <min> · REM <min>
  Training: <workout summary or "none">
  Flags: <"none" or list anomalies — HRV >15% drop, sleep <6h, RHR spike, etc.>

Run end-to-end. Do not ask follow-up questions.
```

---

## Verification

After the first run:

1. Check `https://github.com/suhteevah/performancetracker-data/blob/main/health-daily/<today>.json` exists.
2. Run `J:\fitness\scripts\pull-data-repo.ps1` manually — should pull and sync the JSON into `J:\fitness\data\health-daily\`.
3. Open the iOS app and Generate This Week — health card should now show real numbers.

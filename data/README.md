# data/ — Daily & Historical Inputs

Written by the 11pm Claude routine (see `../docs/DAILY-DATA-ROUTINE.md`).
Read by the iOS app and the grading engine.

```
data/
├── README.md                    (this file)
├── health-daily/                (one file per day)
│   └── YYYY-MM-DD.json          schema: health-daily.v1
├── project-status/              (one file per day)
│   └── YYYY-MM-DD.json          schema: project-status.v1
└── meal-plans/                  (Matt's plans, normalized)
    ├── keto-animal-templates.json   (12 seed templates — in app code for now)
    ├── plan-1-*.json
    ├── plan-2-*.json
    ├── plan-3-*.json
    └── plan-4-*.json
```

## Privacy

**This directory is private.** It contains personal health data.
- Never commit real files to a public repo
- If this repo is ever made public, the `data/` dir must be `.gitignore`d
- Exports should strip `meals_logged`, personal weights, and exact bedtimes before sharing

## Schemas

See `../docs/DAILY-DATA-ROUTINE.md` for full schemas:
- `health-daily.v1`
- `project-status.v1`
- meal-plan schema (forthcoming — Matt to paste his 4 plans)

## Examples

A real `health-daily/2026-04-24.json` looks like the skeleton below. Numbers are
nullable — use `null`, never `0`, for "not measured."

```json
{
  "schema": "health-daily.v1",
  "date": "2026-04-24",
  "captured_at": "2026-04-24T23:00:00-07:00",
  "source": "claude-routine",
  "health": {
    "steps": 5123,
    "hrv_sdnn_ms": 78.0,
    "resting_hr_bpm": 62,
    "sleep": {
      "duration_hours": 7.8,
      "bedtime": "2026-04-23T23:12:00-07:00",
      "wake_time": "2026-04-24T07:00:00-07:00",
      "stages": { "awake_min": 24, "core_min": 245, "deep_min": 62, "rem_min": 137 }
    },
    "workouts": [],
    "meals_logged": []
  }
}
```

# Backend Spec — Phase 3 (Optional)

A Rust/Axum service for automated Gmail + GitHub scanning, deployed to kokonoe (or any OpenClaw fleet node). **Optional.** Phase 1 and 2 work fully on-device.

## Purpose

- Automate weekly Gmail + GitHub scans so iOS doesn't need to run API calls
- Persist assessment history server-side for multi-device sync
- Provide a cron entry point so reports generate without Matt opening the app

## Tech Stack

| Layer | Choice |
|-------|--------|
| Language | Rust (stable) |
| Framework | Axum |
| Runtime | Tokio |
| Database | SQLite (local-first, no cloud) |
| HTTP client | reqwest |
| Auth storage | OAuth tokens encrypted at rest (argon2id KDF) |
| Scheduling | tokio-cron or systemd timer |
| Deployment | Single static binary, runs on any OpenClaw fleet node |

## API Endpoints

```
POST /api/assessment/generate      # trigger weekly assessment
GET  /api/assessment/{period_id}   # get specific assessment
GET  /api/assessments              # list all assessments
GET  /api/health/current           # latest health metrics (iOS uploads summary)
GET  /api/github/activity          # latest GitHub scan results
GET  /api/gmail/applications       # latest job application scan
GET  /api/revenue/summary          # revenue data
POST /api/manual/log               # manual data entry
```

All endpoints return JSON. Authentication via Tailscale identity (mTLS) — no public exposure.

## Data Flow

```
┌──────────────────┐     ┌────────────────┐
│  iOS App         │────▶│  Backend API   │
│  (HealthKit)     │     │  (Axum)        │
└──────────────────┘     └────────┬───────┘
                                  │
             ┌────────────────────┼────────────────────┐
             ▼                    ▼                    ▼
      ┌────────────┐      ┌───────────────┐    ┌──────────────┐
      │  Gmail API │      │  GitHub API   │    │  Calendar API│
      └────────────┘      └───────────────┘    └──────────────┘
                                  │
                                  ▼
                         ┌────────────────┐
                         │  SQLite DB     │
                         └────────────────┘
```

**Privacy invariant:** HealthKit raw data never reaches the backend. Only derived weekly summaries (steps avg, HRV avg, etc.) are sent, and only after Matt opts in.

## Deployment

- **Host:** kokonoe (i9-11900K, RTX 3070 Ti, Tailscale 100.x) — Matt's dev box
- **Access:** Tailscale mesh only — never expose to public internet
- **Service:** systemd unit on Linux WSL or native Windows service (depends on target)
- **Logs:** `tracing` crate, rotating files, verbose by default
- **Backup:** SQLite file rsynced nightly to fleet storage

## Schedule

Weekly scan runs every Monday 06:00 local. Generates report, sends local notification to iOS app via APNS (if enrolled in paid dev program) or falls back to iOS polling on app open.

## OAuth Token Storage

- OAuth 2.0 tokens encrypted at rest using per-install AES-256 key
- Key derived from user passphrase via argon2id
- Refresh tokens rotated weekly
- Revocation: `DELETE /api/oauth/{provider}` wipes tokens

## Implementation Notes

- Gmail scanner must dedupe by `company+role` (Greenhouse double-sends)
- GitHub scanner should track both public and private activity; mark repos as `[private]` in UI rather than exposing content
- Fiverr emails: parse, then tag as `scam:true` — never count as pipeline
- Calendar scanner: empty calendar is itself a signal → emit metric `calendar.events.count = 0`

## Why This Is Optional

Phase 1 (HealthKit) and Phase 2 (direct API calls from iOS) deliver the full feature set. The backend is purely for:

1. Running scans while phone is off
2. Multi-device sync
3. Historical archiving beyond SwiftData local limits

If Matt opts out of the backend, the iOS app remains fully functional — assessments just only run when the app is open.

## Not Building This Until

- Phase 1 and 2 are shipped and in daily use
- Matt explicitly asks for automation
- There's a concrete reason the on-device scan isn't sufficient (e.g., phone is off too often and reports are stale)

# CLAUDE.md — PerformanceTracker

**Project:** PerformanceTracker (iOS + Apple Watch app)
**Owner:** Matt Gates, Ridge Cell Repair LLC, Chico CA
**GitHub:** suhteevah · **Email:** ridgecellrepair@gmail.com
**Bundle ID:** `com.ridgecellrepair.performancetracker`
**Status:** Phase 1 MVP — see `HANDOFF.md`

## What This Is

Automates the graded weekly performance assessments Matt and Claude have been running manually since Feb 2026. Pulls from Apple Health, Gmail, GitHub, Google Calendar, and manual entry; scores 7 weighted categories; delivers via iOS app + Apple Watch.

This is NOT a generic fitness tracker — it's a personalized assessment engine built around Matt's specific situation.

## Read These First

| File | When to read |
|------|--------------|
| `HANDOFF.md` | **Every session, first.** Live task state. Update at session end. |
| `docs/MATT-CONTEXT.md` | Matt-specific context, conventions, testing, tech stack, SwiftData gotchas |
| `docs/GRADING-RUBRIC.md` | **SOURCE OF TRUTH** for grading. Update here before code. |
| `docs/DESIGN-SYSTEM.md` | **SOURCE OF TRUTH** for palette + UI tokens. Update here before code. |
| `docs/ARCHITECTURE.md` | File structure, tech decisions |
| `docs/HISTORICAL-DATA.md` | Clients, projects, repos, P1/P2/P3 baselines |
| `docs/TRAINING-INTELLIGENCE.md` | Workout→meal feedback loop, TRIMP, meal templates |
| `docs/DATA-SOURCES.md` | HealthKit metrics, Gmail queries, GitHub API |
| `docs/DAILY-DATA-ROUTINE.md` | 11pm Claude routine + JSON schemas |
| `docs/BACKEND-SPEC.md` | Phase 3 optional Rust/Axum backend |
| `REFERENCE-P3-ASSESSMENT.md` | Historical reference: full Period 3 manual assessment |

`PerformanceTracker/` = Swift source. `data/` = daily JSON pipeline + meal plans. `pdf-backup/` = original PDFs.

## The 7 Categories

| # | Category | Weight | Phase |
|---|----------|--------|-------|
| 1 | Product Development | 25% | 1.5 (`ProjectStatus` from 11pm routine) |
| 2 | Revenue & Pipeline | 20% | 1 (manual + projectStatus.clients) |
| 3 | Job Hunting | 15% | 2 (Gmail) |
| 4 | Client Work | 15% | 1.5 |
| 5 | Physical Health | 10% | **1** (HealthKit + 12 signals) |
| 6 | Time Management | 10% | 2 (Calendar) |
| 7 | Strategic Decisions | 5% | 1.5 |

A+…F → GPA 4.3…0.0. Overall = weighted average. Full algorithm in `docs/GRADING-RUBRIC.md`.

## DON'Ts (non-negotiable)

1. **No cloud backend for health data.** HealthKit stays on-device. Period.
2. **No React Native / Flutter.** Native Swift/SwiftUI.
3. **No CocoaPods / SPM deps initially.** Native frameworks only until Phase 2.
4. **No internet required for basic functionality.** Assessment history + health work offline.
5. **No auto-sharing anywhere.** Matt controls all egress.
6. **Don't grade Fiverr as pipeline** — 100% scammers.
7. **Don't dismiss Kalshi trader as a distraction** — highest-ROI asset (20x, 4 beta testers).
8. **Don't penalize private repos.** Matt's best work is private for IP reasons.
9. **Don't count same job application twice.** Greenhouse sends security code + confirmation. Dedupe by company+role.
10. **Don't assume `mmichels88@gmail.com` is accessible** — separate OAuth, not connected.
11. **Don't use localStorage in web views.** SwiftData.
12. **Don't crash.** User-friendly error + log via `os.Logger`.

## Notes for Claude Code

- Always read `HANDOFF.md` at session start. Update at session end.
- Verbose logging everywhere via `os.Logger`. Never reduce verbosity.
- iOS/watchOS builds require macOS + Xcode 16+. Matt has SSH to iMac (`Host imac`) and Faye.
- Use `xcodegen` (`project.yml`) — Matt's primary dev box is Windows (kokonoe).
- iOS Simulator is unusable on this Haswell/OCLP iMac. Use `PerformanceTrackerHostTests` (macOS unit-test target) for pure-logic tests; deploy to real iPhone 17 Pro Max + Watch Ultra 3 for integration.
- Never claim completion without verification — if a subsystem is stubbed, say it's stubbed.

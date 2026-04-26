# Historical Data — P1 / P2 / P3

> Seed this into SwiftData on first launch so Matt sees his full trajectory from day one.

## Trajectory Summary

| Period | Dates | Overall | GPA |
|--------|-------|---------|-----|
| P1 | Feb 16–22, 2026 | C+ | 2.3 |
| P2 | Feb 23 – Mar 19, 2026 | B+ | 3.3 |
| P3 | Mar 20 – Apr 8, 2026 | A- | 3.7 |

**C+ → B+ → A-** in seven weeks. Consistent improvement grounded in real output escalation (not grade inflation).

---

## Period 1: February 16–22, 2026 — Overall: C+ (2.3)

| Category | Grade | Key Facts |
|----------|-------|-----------|
| Product Development | A- | 267 commits, 60 repos in Feb (volume, not depth) |
| Revenue & Pipeline | D- | $0 |
| Job Search | C- | 3 stretch applications (wrong industries) |
| Client Work | D | No visible deliverables |
| Physical Health | C | Steps ~7,800/day, HRV 57, RHR 66 |
| Time Management | D+ | 10+ simultaneous projects, empty calendar |
| Strategy | D | Building infrastructure instead of selling |

---

## Period 2: February 23 – March 19, 2026 — Overall: B+ (3.3)

| Category | Grade | Key Facts |
|----------|-------|-----------|
| Product Development | A | Wraith Browser 27K lines Rust, 348 tests |
| Revenue & Pipeline | C+ | Jake Brander $550 for Vox Spectre; Kalshi 20x w/4 beta testers; Fiverr=scammers; Upwork=200 connects, 0 contacts |
| Job Search | A- | Job Hunter blitzed 23 companies Mar 18–19 |
| Client Work | C | Vox Spectre delivered, NDA for Infrared Photonics |
| Physical Health | D+ | HRV crashed to 42ms, RHR rose to 73, exercise min/wk hit 13 |
| Time Management | C+ | Focused but Factorio/VATSIM/MTG during crisis |
| Strategy | A- | Products > services, correct pivots, Kalshi persistence vindicated |

---

## Period 3: March 20 – April 8, 2026 — Overall: A- (3.7)

| Category | Grade | Key Facts |
|----------|-------|-----------|
| Product Development | A+ | ClaudioOS 294,710 lines / 52 crates / 56 modules; Wraith commercialization; CAD tool for Incognito |
| Revenue & Pipeline | B | Active clients (Incognito + FCP), Kalshi ongoing, no new invoices visible |
| Job Search | A- | 6,000 total applications; needs quality filtering |
| Client Work | B+ | Two active engagements (Incognito Acquisitions, First Choice Plastics) |
| Physical Health | B- | HRV doubled 42→86 ms, RHR dropped 73→60–66 bpm, exercise slacking (20–22 min/wk) |
| Time Management | B | Consolidated to 4 focused tracks |
| Strategy | A | Every major decision correct |

See `REFERENCE-P3-ASSESSMENT.md` for the full narrative.

---

## Health Baselines (from real HealthKit data)

| Metric | P1 Baseline (Feb) | P2 Low (Mar) | P3 Recovery (Apr) | Target |
|--------|-------------------|--------------|-------------------|--------|
| Steps/day | ~7,800 | ~4,700 | ~4,900 | 7,500+ |
| Active Cal/day | ~640 | ~347 | ~470 | 600+ |
| Resting HR (bpm) | 66 | 73 | 60–66 | <65 |
| HRV (SDNN, ms) | 57 | 42 | 68–86 | >60 |
| Exercise min/wk | ~50 | 13 (crisis) | 20–86 | >150 |
| Walking HR (bpm) | ~107 | 117 | 97–112 | <110 |

**HRV is the single most important health metric.** Crashed from 57→42 during P2 stress, recovered to 86 during P3 through **meal plan discipline alone** (exercise minimal). HRV doubling from 42→86 is a dramatic recovery signal.

---

## P3 Weekly Health Detail

| Metric | P2 End (Mar 16) | Wk1 (Mar 20) | Wk2 (Mar 27) | Wk3 (Apr 3)* | Trend |
|--------|-----------------|--------------|--------------|--------------|-------|
| HRV (ms) | 42.3 | 73 | 68.1 | 86.0 | UP 103% |
| Resting HR (bpm) | 73 | 59.6 | 61.4 | 65.6 | DOWN 15% |
| Walking HR (bpm) | 117 | 112 | 97 | 112 | Improved |
| Steps/day avg | 4,877 | 5,326 | 4,709 | 4,495 | Stable-low |
| Active Cal/day | 399 | 496 | 574 | 413 | Roughly stable |
| Exercise min/wk | 53 | 86 | 20 | 22 | Wk 2–3 minimal |

*Week 3 partial — 5 days as of Apr 8.

---

## Clients (as of April 2026)

### Incognito Acquisitions — Seth Barone (Virginia Beach)
- **Engagement:** CAD measurement extraction tool (DXF/SVG/STEP/PDF → LightBurn .lbrn2 + Cricut Design Space SVG)
- **Delivered:** Full web UI (Flask, canvas viewer, pan/zoom, click-to-select, point-to-point measurement), Batch CLI, Windows PowerShell installer package, desktop shortcut, context menu
- **Legal:** Mutual NDA with ITAR/export control, Wraith commercial + gratis licenses
- **Products (ITAR-adjacent):** PEQ-15, MAWL, LA5 tactical accessories
- **Status:** Active; paid work unclear

### First Choice Plastics — Cory Sturgis (Oroville CA)
- **Engagement:** Injection molding support, Shibaura EC85SXIII-2A (Injectvisor V70 controller)
- **Delivered:** Diagnosed LS32 eject retraction alarm; flagged MIN-CUSH 0.000 requiring check ring diagnostic; identified overdue PM cycles (150-hr weekly + 2,000-hr quarterly)
- **Ongoing:** Hands-on troubleshooting; full injection molding skill installed
- **Identified:** Shibaura training class July 21, Rancho Cucamonga
- **Status:** Active; no billing structure visible

### Midnight Munitions — Christian Anderson (Nephi UT)
- NAS3 ammunition, veteran-owned. Technical content review (SBR load development article).

### Halsey Bottling (Napa CA)
- Mobile wine bottling. Status unclear.

### Compac Engineering — Greg Jones (Paradise CA)
- Industrial sensors. Status unclear.

### Jake Brander — Brander Group
- Vox Spectre: $550 (first product revenue, Upwork origin). Historical.

---

## Key Products / Repos

| Repo | Status | Lang | Lines | Significance |
|------|--------|------|-------|--------------|
| claudioos | Active (private?) | Rust | 294,710 | Bare-metal Rust OS — flagship moonshot |
| wraith-browser | Active (private) | Rust | 27,000+ | AI agent browser — commercial product, 130 MCP tools |
| kalshi-weather-trader | Active (private) | JS | ? | Prediction market bot — 20x returns |
| kalshi-trader-v7 | Active (private) | Rust | ? | Rust rewrite of Kalshi trader |
| openclaw-admin-mcp | Active (private?) | Rust | 6,241 | Fleet admin MCP server |
| docsync | Public | Shell | Small | Doc drift detection — 2 stars |
| depguard | Public | Shell | Small | Dependency audit |
| mpvhq-win64 | Public | GLSL | Legacy | mpv build — 7 stars |

### Wraith Browser Commercial (P3 milestones)
- Landing page + docs site launched (Vercel, Fumadocs/Next.js)
- Critical review complete — 20+ doc pages audited
- Fixes: tool count=130, clone URL corrected, `Servo-derived` → `html5ever`, dead enterprise link removed, MCP add corrected, README trimmed to 165 lines
- **IP protection playbook:** USPTO trademark (Class 9/42, $700), Harmony CLA, dual AGPL licensing
- **Enterprise pricing:** $497–$2,997/mo
- Remaining: OG image 404, zero releases/stars/forks, thin Getting Started pages, same-day blog post dates

### ClaudioOS (P3 moonshot)
Bare-metal Rust OS — no Linux kernel, no POSIX, no JS runtime. 294,710 lines, 52 crates, 56 kernel modules. Features:
- Windows binary compatibility
- Linux ELF compatibility
- 12 language runtimes
- Vulkan 1.3 graphics
- .NET CLR
- Post-quantum SSH
- WiFi + Bluetooth
- Vector database
- 35 published GitHub repos
- Web presence at claudioos.vercel.app

Scaffold → QEMU boot → OAuth stack in a single evening, then exploded to 294K lines.

---

## Target Companies (Job Hunting)

**Tier 1 (primary targets):** Anthropic, OpenAI, GitLab, Vercel, Discord, Figma, Tailscale, Chainguard, ClickHouse, PlanetScale, PagerDuty, LaunchDarkly, Netlify, Airtable

**Tier 2 (pipeline):** WinCo Foods (Sr Middleware Developer Phoenix), Hudson Manpower (GenAI/ML Data Scientist)

**Non-target flags (should be filtered by Job Hunter):**
- Geographic: APAC/Korea roles (GitLab Korea AE, Vercel Partner Lead APAC)
- Functional: Product Designer, People Business Partner, Account Executive non-tech

**Target roles:** Senior/Staff SWE, AI Engineer, MLOps, QA Engineering, DevOps

**LinkedIn headline:** *AI/LLM Infrastructure Engineer | MCP Server Builder | Python & Rust | DevOps & QA Automation*

---

## Seed Data — Swift

```swift
let seedAssessments: [Assessment] = [
    Assessment(
        periodId: "2026-W08-P1",
        periodStart: dateFrom("2026-02-16"),
        periodEnd: dateFrom("2026-02-22"),
        overallGrade: .cPlus,
        overallGPA: 2.3,
        categoryGrades: [
            .productDevelopment: .aMinus,
            .revenuePipeline: .dMinus,
            .jobHunting: .cMinus,
            .clientWork: .d,
            .physicalHealth: .c,
            .timeManagement: .dPlus,
            .strategyDecisions: .d,
        ],
        healthMetrics: HealthMetrics(
            stepsPerDay: 7800, activeCalPerDay: 640,
            restingHR: 66, hrv: 57, exerciseMinPerWeek: 50,
            walkingHR: 107, mealPlanDaysFollowed: nil
        ),
        notes: "Baseline period. 267 commits, 60 repos, $0 revenue."
    ),
    Assessment(
        periodId: "2026-W10-P2",
        periodStart: dateFrom("2026-02-23"),
        periodEnd: dateFrom("2026-03-19"),
        overallGrade: .bPlus,
        overallGPA: 3.3,
        categoryGrades: [
            .productDevelopment: .a,
            .revenuePipeline: .cPlus,
            .jobHunting: .aMinus,
            .clientWork: .c,
            .physicalHealth: .dPlus,
            .timeManagement: .cPlus,
            .strategyDecisions: .aMinus,
        ],
        healthMetrics: HealthMetrics(
            stepsPerDay: 4700, activeCalPerDay: 347,
            restingHR: 73, hrv: 42, exerciseMinPerWeek: 13,
            walkingHR: 117, mealPlanDaysFollowed: nil
        ),
        notes: "Health crisis. HRV 42. $550 Vox Spectre. Kalshi 20x. Job blitz 23 companies."
    ),
    Assessment(
        periodId: "2026-W12-P3",
        periodStart: dateFrom("2026-03-20"),
        periodEnd: dateFrom("2026-04-08"),
        overallGrade: .aMinus,
        overallGPA: 3.7,
        categoryGrades: [
            .productDevelopment: .aPlus,
            .revenuePipeline: .b,
            .jobHunting: .aMinus,
            .clientWork: .bPlus,
            .physicalHealth: .bMinus,
            .timeManagement: .b,
            .strategyDecisions: .a,
        ],
        healthMetrics: HealthMetrics(
            stepsPerDay: 4900, activeCalPerDay: 470,
            restingHR: 63, hrv: 76, exerciseMinPerWeek: 43,
            walkingHR: 107, mealPlanDaysFollowed: 6
        ),
        notes: "ClaudioOS 294K lines. HRV 42→86. Two active clients. 6K applications."
    ),
]
```

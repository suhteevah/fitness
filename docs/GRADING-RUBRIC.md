# Grading Rubric — Source of Truth

> This file is the authoritative source for grading criteria. If Matt asks to change grading, update this file.

## Letter → GPA

| Letter | GPA |
|--------|-----|
| A+ | 4.3 |
| A | 4.0 |
| A- | 3.7 |
| B+ | 3.3 |
| B | 3.0 |
| B- | 2.7 |
| C+ | 2.3 |
| C | 2.0 |
| C- | 1.7 |
| D+ | 1.3 |
| D | 1.0 |
| D- | 0.7 |
| F | 0.0 |
| Incomplete | — (excluded from weighted avg) |

**Overall grade** = weighted average of category GPAs, re-normalized for `Incomplete` categories (excluded from both numerator and denominator).

## 7 Categories + Weights

| # | Category | Weight |
|---|----------|--------|
| 1 | Product Development | 25% |
| 2 | Revenue & Pipeline | 20% |
| 3 | Job Hunting | 15% |
| 4 | Client Work | 15% |
| 5 | Physical Health | 10% |
| 6 | Time Management & Focus | 10% |
| 7 | Strategic Decision-Making | 5% |

Sum = 100%.

---

## 1. Product Development — 25%

Measures code output, project scope, technical ambition, test coverage, documentation.

**Source (Phase 1):** Daily project status harvest from local repos + HANDOFF.md deltas via the 11pm Claude routine (`docs/DAILY-DATA-ROUTINE.md`). GitHub API in Phase 2 enhances this.

| Grade | Criteria |
|-------|----------|
| A+ | 10K+ lines of production code OR completed full product launch |
| A | Significant features, 5K+ lines, tests passing |
| A- | Good output, some gaps in tests or docs |
| B+ | Solid work, 2K–5K lines, forward progress on key projects |
| B | Steady progress, smaller scope |
| C | Minimal progress, mostly maintenance |
| D | Scattered output, nothing shipped |
| F | No development activity |

**Matt-specific:** ClaudioOS, Wraith Browser, Kalshi trader, OpenClaw ecosystem, client tools (CAD extraction, injection molding skill) are the tracked products. Primary Rust; some TypeScript/Python/Shell.

**Signals the algorithm reads from `ProjectStatus` JSON:**
- `commitsThisPeriod` — total commits across all tracked projects this week
- `linesChangedThisPeriod` — diff lines touched
- `milestonesHit[]` — explicit milestones (first boot, feature ship, revenue event)
- `handoffDelta` — new "done" items in HANDOFF.md files vs prior week
- `testsPassingRatio` — if test output available

**Algorithm sketch:**
```swift
func gradeProductDevelopment(status: ProjectStatusPeriod) -> Grade {
    let commits = status.commitsThisPeriod
    let lines = status.linesChangedThisPeriod
    let milestones = status.milestonesHit.count
    if lines >= 10_000 || milestones >= 2 { return .aPlus }
    if lines >= 5_000  || milestones >= 1 { return .a }
    if lines >= 2_500                      { return .aMinus }
    if lines >= 1_000                      { return .bPlus }
    if lines >= 250                        { return .b }
    if lines > 0 || commits > 0            { return .c }
    return .f
}
```

---

## 2. Revenue & Pipeline — 20%

Measures money received, invoices sent, pipeline value, client engagement.

| Grade | Criteria |
|-------|----------|
| A | $2,000+ received OR multiple active paying clients |
| B | $500–$2,000 received OR strong pipeline with signed contracts |
| C | <$500 OR active client work without billing |
| D | No revenue, pipeline activity only |
| F | No revenue, no pipeline activity |

**Matt-specific:**
- Jake Brander paid $550 for Vox Spectre (first product revenue, Upwork origin)
- Kalshi trader: 20x, 4 beta testers (track weekly P&L)
- Fiverr: 100% scammers, DO NOT count as pipeline
- Upwork: ~200 connects burned, 0 contacts after Jake
- Wraith Browser enterprise pricing: $497–$2,997/mo
- Key clients: Jake Brander, Seth Barone, Cory Sturgis, Christian Anderson, Greg Jones

---

## 3. Job Hunting — 15%

Measures applications submitted, quality/fit, interview callbacks, offers.

| Grade | Criteria |
|-------|----------|
| A | Interview callbacks received OR offer(s) |
| A- | High volume + well-targeted applications |
| B | Good volume, mostly relevant roles |
| C | Low volume OR poorly targeted roles |
| D | Minimal activity |
| F | No job search activity |

**Matt-specific:**
- Job Hunter agent + Wraith Browser = 6,000+ total applications historically
- Target roles: Senior/Staff SWE, AI Engineer, MLOps, QA Eng, DevOps
- **Non-target flag:** geographic mismatches (APAC/Korea), functional mismatches (Product Designer, People BP, Account Executive non-tech)
- Key targets: Anthropic, OpenAI, GitLab, Vercel, Discord, Figma, Tailscale, Chainguard, ClickHouse, PlanetScale, PagerDuty, LaunchDarkly, Netlify, Airtable
- Censys = rejected same-day (normal at volume)
- WinCo Foods + Hudson Manpower in pipeline
- LinkedIn headline: *"AI/LLM Infrastructure Engineer | MCP Server Builder | Python & Rust | DevOps & QA Automation"*

---

## 4. Client Work — 15%

Measures deliverables shipped, communications, invoices sent, satisfaction.

**Source (Phase 1):** `ProjectStatus.clientActivity[]` produced by the daily routine. Each active client has `lastDeliverable`, `daysSinceContact`, `invoiceTotalThisPeriod`. Plus manual `ManualEntry.clientMeeting` entries.

| Grade | Criteria |
|-------|----------|
| A | Multiple deliverables shipped + invoiced |
| B | Deliverables shipped, light on invoicing |
| C | Active engagement but thin on deliverables |
| D | No visible client deliverables |
| F | No client activity |

**Matt-specific active clients:**
- **Incognito Acquisitions** (Seth Barone, Virginia Beach): CAD measurement extraction (DXF/SVG/STEP/PDF → LightBurn + Cricut). ITAR-adjacent NDA signed. Wraith gratis license. Products: PEQ-15, MAWL, LA5.
- **First Choice Plastics** (Cory Sturgis, Oroville CA): Injection molding support, Shibaura EC85SXIII-2A. Skill installed. Diagnosed LS32 eject retraction, flagged MIN-CUSH=0.000, overdue PM cycles.
- **Midnight Munitions** (Christian Anderson, Nephi UT): NAS3 ammunition, veteran-owned. Technical content review.
- **Halsey Bottling** (Napa CA): Mobile wine bottling. Status unclear.
- **Compac Engineering** (Greg Jones, Paradise CA): Industrial sensors. Status unclear.

---

## 5. Physical Health — 10%  ← **MVP anchor**

Measures HealthKit metrics vs baselines and targets, exercise consistency, meal plan adherence.

| Grade | Criteria |
|-------|----------|
| A | All metrics improving, exercise consistent, meal plan followed |
| B | Most metrics stable/improving, some exercise, meal plan followed |
| C | Metrics mixed, sporadic exercise |
| D | Metrics declining, minimal exercise |
| F | All metrics declining, no exercise, diet abandoned |

**Matt-specific context:**
- Diet: keto, animal-based, no pork. Safeway/Raley's in Chico.
- Meal plans via Claude — rotating them, sticking rock-solid.
- Apple Fitness+ subscription exists (workout plans, inconsistent use).
- **Goal:** muscle gain + cardiovascular endurance (shifted from weight loss).
- **Weight:** 196 lbs (last reported).
- **Calorie target:** 2,200 kcal/day for muscle building.
- **TDEE:** ~2,840 kcal/day.
- **HRV is the most important health metric.** Was in crisis at 42ms, recovered to 86ms through nutrition alone.
- **Zone 2 cardio:** 114–133 bpm sustained.

### Health Grading Algorithm (expanded)

Comprehensive signal set. Each signal has a weight (sum = 100%) and contributes a weighted score out of 4.3. Letter grade is derived from the final score.

#### Signal weights

| # | Signal | Source | Weight | Max points |
|---|--------|--------|--------|------------|
| 1 | HRV (SDNN) | HealthKit | 20% | 0.86 |
| 2 | Resting HR | HealthKit | 10% | 0.43 |
| 3 | Sleep duration | HealthKit `sleepAnalysis` | 15% | 0.65 |
| 4 | Sleep consistency (bedtime variance) | Derived | 5% | 0.22 |
| 5 | Sleep stages (deep + REM %) | HealthKit `sleepAnalysis` categorized | 5% | 0.22 |
| 6 | Steps | HealthKit | 8% | 0.34 |
| 7 | Exercise minutes | HealthKit | 8% | 0.34 |
| 8 | Meal plan adherence | Manual | 8% | 0.34 |
| 9 | Respiratory rate trend | HealthKit | 4% | 0.17 |
| 10 | VO2max / cardio fitness | HealthKit | 4% | 0.17 |
| 11 | Body weight trend | HealthKit | 3% | 0.13 |
| 12 | Training–recovery alignment | Derived (see Training Intelligence) | 10% | 0.43 |
| **Total** | | | **100%** | **~4.30** |

HRV bonus/penalty vs baseline (±10% of 4.3) still layered on top as a trend tiebreaker — crosses from B+ into A- or vice versa when baseline deviation is large.

#### Thresholds (per signal)

**HRV (SDNN, ms)** — 20% · max 0.86
- ≥60: 0.86 (good) · 50–59: 0.60 (acceptable) · 40–49: 0.26 (concerning) · <40: 0 (crisis)

**Resting HR (bpm)** — 10% · max 0.43
- ≤60: 0.43 · 61–65: 0.35 · 66–70: 0.22 · 71–75: 0.10 · >75: 0

**Sleep duration (hours/night avg)** — 15% · max 0.65
- 7.5–9.0: 0.65 (ideal) · 7.0–7.49 or 9.01–9.5: 0.45 · 6.0–6.99 or 9.51–10: 0.25 · <6 or >10: 0.05

**Sleep consistency (bedtime SD in minutes)** — 5% · max 0.22
- ≤30min: 0.22 (elite — bed same time within 30min) · 31–60: 0.15 · 61–90: 0.08 · >90: 0

**Sleep stages (deep% + REM% of total)** — 5% · max 0.22
- ≥35%: 0.22 (healthy architecture) · 25–34%: 0.15 · 15–24%: 0.08 · <15%: 0

**Steps/day avg** — 8% · max 0.34
- ≥7,500: 0.34 · 5,000–7,499: 0.21 · 3,000–4,999: 0.10 · <3,000: 0

**Exercise minutes/week** — 8% · max 0.34
- ≥150: 0.34 · 75–149: 0.21 · 30–74: 0.10 · <30: 0

**Meal plan adherence (days/week)** — 8% · max 0.34
- ≥6: 0.34 · 4–5: 0.20 · 2–3: 0.08 · <2: 0

**Respiratory rate trend (bpm)** — 4% · max 0.17
- 12–20 and stable (±1 bpm from baseline): 0.17 · stable outside range: 0.10 · trending up/down >1 bpm: 0.05 · >3 bpm deviation: 0

**VO2max (ml/kg/min)** — 4% · max 0.17
- ≥45 (excellent for age): 0.17 · 40–44: 0.13 · 35–39: 0.09 · 30–34: 0.05 · <30: 0

**Body weight trend** — 3% · max 0.13
- Moving toward muscle-gain target (196→210 goal, i.e. +0 to +0.5 lb/wk): 0.13 · stable ±0.2 lb/wk: 0.09 · drifting >0.5 lb/wk in wrong direction: 0

**Training–recovery alignment** — 10% · max 0.43
- Produced by `TrainingLoad.alignmentScore()` — see `TRAINING-INTELLIGENCE.md`.
- In short: did actual training match what HRV/sleep signaled Matt could handle?
  - Recommended hard day + hard training done + next-day HRV maintained: +0.43
  - Recommended easy day + easy training done: +0.35
  - Over-training (hard when recovery signals said easy) drops this to 0.15 or lower.
  - No training data: 0.15 (neutral, doesn't help or hurt much).

#### Algorithm

```swift
func gradeHealth(metrics: HealthMetrics, baseline: HealthBaseline) -> Grade {
    var score: Double = 0

    // 1. HRV — 20%
    if let hrv = metrics.hrv {
        switch hrv {
        case 60...:   score += 0.86
        case 50..<60: score += 0.60
        case 40..<50: score += 0.26
        default:      score += 0
        }
    }

    // 2. Resting HR — 10%
    if let rhr = metrics.restingHR {
        switch rhr {
        case ..<60.01: score += 0.43
        case ..<65.01: score += 0.35
        case ..<70.01: score += 0.22
        case ..<75.01: score += 0.10
        default:       score += 0
        }
    }

    // 3. Sleep duration — 15%
    if let hrs = metrics.sleepHoursPerNight {
        switch hrs {
        case 7.5...9.0:           score += 0.65
        case 7.0..<7.5, 9.0..<9.51: score += 0.45
        case 6.0..<7.0, 9.51..<10: score += 0.25
        default:                   score += 0.05
        }
    }

    // 4. Sleep consistency — 5%
    if let bedSD = metrics.bedtimeSDminutes {
        switch bedSD {
        case ..<30.01:   score += 0.22
        case ..<60.01:   score += 0.15
        case ..<90.01:   score += 0.08
        default:         score += 0
        }
    }

    // 5. Sleep stages — 5%
    if let stagesPct = metrics.deepPlusREMPercent {
        switch stagesPct {
        case 0.35...:    score += 0.22
        case 0.25..<0.35: score += 0.15
        case 0.15..<0.25: score += 0.08
        default:         score += 0
        }
    }

    // 6. Steps — 8%
    if let steps = metrics.stepsPerDay {
        switch steps {
        case 7_500...:     score += 0.34
        case 5_000..<7_500: score += 0.21
        case 3_000..<5_000: score += 0.10
        default:            score += 0
        }
    }

    // 7. Exercise — 8%
    if let mins = metrics.exerciseMinPerWeek {
        switch mins {
        case 150...:    score += 0.34
        case 75..<150:  score += 0.21
        case 30..<75:   score += 0.10
        default:        score += 0
        }
    }

    // 8. Meal plan — 8%
    if let days = metrics.mealPlanDaysFollowed {
        switch days {
        case 6...:   score += 0.34
        case 4...5:  score += 0.20
        case 2...3:  score += 0.08
        default:     score += 0
        }
    }

    // 9. Respiratory rate — 4%
    if let rr = metrics.respiratoryRate {
        let baselineRR = baseline.respiratoryRate
        let inHealthyRange = rr >= 12 && rr <= 20
        let deviation = abs(rr - baselineRR)
        if inHealthyRange && deviation <= 1 { score += 0.17 }
        else if inHealthyRange            { score += 0.10 }
        else if deviation <= 3            { score += 0.05 }
        else                              { score += 0 }
    }

    // 10. VO2max — 4%
    if let vo2 = metrics.vo2Max {
        switch vo2 {
        case 45...:  score += 0.17
        case 40..<45: score += 0.13
        case 35..<40: score += 0.09
        case 30..<35: score += 0.05
        default:     score += 0
        }
    }

    // 11. Body weight trend — 3%
    if let weeklyLbDelta = metrics.weightDeltaLbPerWeek {
        // Muscle gain target = 0 to +0.5 lb/week
        if (0 ... 0.5).contains(weeklyLbDelta)    { score += 0.13 }
        else if abs(weeklyLbDelta) <= 0.2         { score += 0.09 }
        else                                       { score += 0 }
    }

    // 12. Training-recovery alignment — 10% (see Training Intelligence)
    score += metrics.trainingAlignmentScore ?? 0.15  // neutral default

    // Trend bonus/penalty vs baseline HRV — ±10%
    if let hrv = metrics.hrv, baseline.hrv > 0 {
        if hrv > baseline.hrv * 1.1      { score += 0.43 }
        else if hrv < baseline.hrv * 0.9 { score -= 0.20 }
    }

    return Grade.fromScore(max(score, 0), maxScore: 4.30)
}
```

**Score → Grade mapping:**
```
>= 4.10 → A+
>= 3.85 → A
>= 3.55 → A-
>= 3.20 → B+
>= 2.85 → B
>= 2.55 → B-
>= 2.20 → C+
>= 1.85 → C
>= 1.55 → C-
>= 1.15 → D+
>= 0.85 → D
>= 0.50 → D-
else    → F
```

**Nil-handling:** Count nil HealthKit-sourced fields (excludes subject-reported meal plan + derived alignment score). If more than half of the *essential* inputs (HRV, RHR, Steps, ExerciseMin, Sleep duration) are nil, return `.incomplete` rather than a low grade. Log a warning via `os.Logger`.

**Note on the 4.30 max:** Sum of all signal maxes is exactly 4.30; the ±0.43 HRV trend bonus can push score above max or below 0, so algorithm clamps final score to `[0, ∞)` and lets grade-from-score bucketing handle scores over 4.30 as A+.

---

## 6. Time Management & Focus — 10%

Measures calendar usage, project focus vs scatter, context switching, recreation during crisis.

| Grade | Criteria |
|-------|----------|
| A | Calendar blocked, focused on 2–3 tracks, minimal recreation waste |
| B | Good focus, some calendar structure, minor diversions |
| C | Moderate scatter, no calendar, some recreation projects |
| D | High scatter, 5+ unrelated tracks, significant recreation during crisis |
| F | Complete scatter, no productive output |

**Matt-specific:**
- Calendar historically empty — persistent issue, itself a grading signal
- **Recreation flags:** Factorio (~20K hours total, Space Age completed), WoW TBC Classic, VATSIM flight sim, MTG Commander, baking (rough puff)
- Recreation during financial crisis is a specific red flag
- P1 had 10+ simultaneous projects; P3 consolidated to 4

---

## 7. Strategic Decision-Making — 5%

Measures resource-allocation decisions, correct pivots, business-owner thinking.

**Source:** Qualitative — derived from weekly `ProjectStatus` summary + Matt's own strategic notes. The daily routine can flag strategic events (e.g. "IP protection filing", "pivot to products", "hardware purchase during cash crisis") with a `strategicEvents[]` array on `ProjectStatusPeriod`. Until there's a clear rubric signal, default is `.b` with notes, and Matt can override.

| Grade | Criteria |
|-------|----------|
| A | Every major decision correct, IP protection, revenue-focused |
| B | Mostly correct decisions, minor misallocations |
| C | Mixed decisions, some resource waste |
| D | Strategically poor — building instead of selling, hardware spending during crisis |
| F | Actively destructive decisions |

**Matt-specific strategic history:**
- Key insight: Matt is a **product builder, not a freelance service provider**
- Fiverr/Upwork grind strategy **failed** — revenue came from products (Vox Spectre $550) + trading bot (Kalshi 20x)
- Kalshi trader was dismissed as a distraction for 2 periods — turned out to be the best-performing asset. **Don't repeat this mistake.**
- Hardware spending during cash crisis is a recurring flag (Supermicro chassis, Tesla P40s, Amazon cart)
- 30-day homelessness deadline was the original framing (~Feb 16 2026)

---

## Data Model (Swift)

```swift
struct WeeklyAssessment {
    let periodId: String              // e.g., "2026-W17"
    let periodStart: Date
    let periodEnd: Date
    let overallGrade: Grade
    let overallGPA: Double
    let categories: [CategoryAssessment]
    let priorPeriodComparison: PeriodComparison?
    let recommendations: [String]
    let dataSourcesUsed: [DataSource]
    let generatedAt: Date
}

struct CategoryAssessment {
    let category: Category
    let grade: Grade
    let gpa: Double
    let weight: Double
    let metrics: [Metric]
    let vsBaseline: [BaselineComparison]
    let vsPriorPeriod: GradeChange?
    let notes: [String]
}

enum Category {
    case productDevelopment, revenuePipeline, jobHunting
    case clientWork, physicalHealth, timeManagement, strategyDecisions
}

enum Grade {
    case aPlus, a, aMinus
    case bPlus, b, bMinus
    case cPlus, c, cMinus
    case dPlus, d, dMinus
    case f
    case incomplete
}
```

## Grading Pipeline

1. **Collect** data from all sources (HealthKit, Gmail, GitHub, Calendar, manual)
2. **Compute** metrics per category (see rubric above)
3. **Compare** to baselines and prior period
4. **Apply** rubric to assign letter grade per category
5. **Weight-average** to overall grade (excluding `.incomplete`)
6. **Generate** recommendations from lowest-scoring categories + trend direction
7. **Store** in SwiftData
8. **Notify** iOS/Watch via local notification

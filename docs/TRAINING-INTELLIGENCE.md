# Training Intelligence

> Closes the loop between workouts, recovery, and meal planning. Makes meal suggestions *responsive* to what Matt actually did and what his body tells us it can handle next.

## Principles

1. **Training stresses the body; meals + sleep repair it.** Meal recommendations must adapt to the day's training demand.
2. **HRV + sleep are the recovery ground truth.** If HRV is low or sleep was short, the app recommends easier training and a higher-fat / lower-stress meal.
3. **Deterministic, auditable.** Given the same inputs, the recommender returns the same output. No black-box ML.
4. **Diet-profile pluggable.** Animal-based / no-pork is the locked primary (`DietProfile.ketoAnimalBasedNoPork`). `.normal` stub exists for later.
5. **Everything a feedback loop.** Each workout → load → suggested meal → meal followed? → next-day HRV → next recommendation. The system learns whether the templates actually work for Matt.

## Core types

```swift
public enum DietProfile: String, Codable, Sendable {
    case ketoAnimalBasedNoPork   // Primary — Matt's locked diet
    case normal                  // Future: balanced macro, not yet implemented
}

public enum WorkoutKind: String, Codable, Sendable, CaseIterable {
    case walk                    // light, aerobic, Zone 1
    case zone2                   // steady cardio, 114–133 bpm for Matt
    case zone4                   // high-intensity cardio
    case strength                // resistance training
    case mobility                // yoga / stretch / rehab
    case sport                   // unstructured (basketball, hike, etc.)
    case rest                    // explicit rest
}

public struct WorkoutProfile: Codable, Sendable, Hashable {
    public let kind: WorkoutKind
    public let durationMin: Int
    public let rpe: Int?         // 1–10 rate of perceived exertion
    public let avgHR: Int?       // if logged
    public let estKcal: Int?     // computed if not provided
    public let date: Date
    public let notes: String?
}
```

## Load model — TRIMP (Training Impulse)

Banister-style TRIMP scales workout stress:

```
TRIMP = duration × intensityFactor × HRreserveRatio
```

We don't have power meters; HR-based suffices. For Matt (age 37, est max HR ~183, resting ~63):

```swift
// Intensity factor per kind
let intensity: [WorkoutKind: Double] = [
    .walk:     0.25,
    .zone2:    0.55,
    .zone4:    0.90,
    .strength: 0.75,
    .mobility: 0.15,
    .sport:    0.60,
    .rest:     0.0,
]

func trimp(workout: WorkoutProfile) -> Double {
    let i = intensity[workout.kind] ?? 0.5
    let minutes = Double(workout.durationMin)
    let hrFactor: Double
    if let hr = workout.avgHR {
        let hrReserve = (Double(hr) - 63) / (183 - 63)   // 0...1
        hrFactor = max(0.2, min(1.0, hrReserve))
    } else {
        // Fallback: RPE or intensity table alone
        hrFactor = i
    }
    return minutes * i * hrFactor
}
```

**Weekly load** = sum of TRIMPs across 7 days.
**Acute:Chronic load ratio** = (last 7d) / (last 28d average) — sweet spot 0.8–1.3. Outside that range, we flag over-reach or under-training.

## Recovery signals

At grade time we look at three recovery dimensions:

| Signal | Source | Good | Concerning |
|--------|--------|------|------------|
| HRV trend | HealthKit 7-day rolling | rising or stable near baseline | >10% drop week-over-week |
| Sleep trend | HealthKit 7-day | 7.5–9 h/night, consistent bedtime | <7h or high variance |
| Resting HR trend | HealthKit 7-day | ≤65 bpm, flat or falling | rising >5 bpm week-over-week |

**Recovery score** = 0.4×HRV + 0.4×Sleep + 0.2×RHR, each signal normalized to 0–1. Recovery is `good` ≥ 0.7, `moderate` 0.4–0.7, `poor` < 0.4.

## Training-recovery alignment

The 10% signal that flows into the Physical Health grade:

```swift
func alignmentScore(workouts: [WorkoutProfile], recovery: RecoveryScore) -> Double {
    let weeklyTRIMP = workouts.map(trimp(workout:)).reduce(0, +)

    switch (recovery, weeklyTRIMP) {
    case (.good, 250...500):       return 0.43  // great: trained appropriately hard
    case (.good, 100..<250):       return 0.30  // could have pushed more
    case (.good, 500...):          return 0.30  // risking overtraining
    case (.good, 0..<100):         return 0.10  // recovered but didn't use it
    case (.moderate, 100...300):   return 0.35  // sensible given moderate recovery
    case (.moderate, 300...):      return 0.15  // too much given signals
    case (.moderate, 0..<100):     return 0.25  // conservative, fine
    case (.poor, 0..<150):         return 0.30  // correctly easy
    case (.poor, 150...):          return 0.05  // ignored poor recovery signals
    default:                       return 0.15  // neutral
    }
}
```

## Meal recommendation engine

Inputs:
- `todayWorkouts: [WorkoutProfile]` — what Matt already did today
- `tomorrowPlannedKind: WorkoutKind?` — what's coming tomorrow (optional)
- `recovery: RecoveryScore` — HRV/sleep/RHR synthesis
- `dietProfile: DietProfile` — currently only `.ketoAnimalBasedNoPork`
- `weeklyMacrosSoFar: MacroTotals` — what Matt's eaten this week
- `weeklyMacroTargets: MacroTotals` — from meal plan

Outputs:
- Recommended meal (from templates) for the next meal slot
- Optional warning ("HRV dropped 15%; consider a light day tomorrow")
- Estimated macro adjustment ("+20g protein vs yesterday")

### Algorithm

```
def recommend_meal(context):
    recovery_context = classify_recovery(context.recovery)
    training_context = classify_today(context.todayWorkouts, context.tomorrowPlannedKind)

    # Combine into meal context tag
    tag = (training_context, recovery_context)
    # e.g. ("post_strength", "good") or ("rest_day", "poor")

    templates = keto_animal_templates.filter { $0.contexts.contains(tag) }
    if templates is empty:
        templates = keto_animal_templates.filter { $0.isFallback }

    ranked = templates.sorted_by:
        1. macros needed vs eaten today (highest deficit first)
        2. variety (haven't eaten this in N days)
        3. ingredients on hand (from shopping list)

    return ranked.first
```

### Contexts (tag tuples)

| Training context | Recovery | Meal intent |
|------------------|----------|-------------|
| `post_strength` | any | **higher protein (40g+), some carb (berries OK on keto)** |
| `post_zone2` | any | **moderate protein, fat-forward, low carb** |
| `post_zone4` | any | **protein + electrolytes + slight carb** |
| `rest_day` | good | **lean protein, fat-forward, anti-inflammatory** |
| `rest_day` | poor | **nutrient-dense, liver, eggs, bone broth** |
| `pre_hard_tomorrow` | moderate | **fuel up: protein + fat, hydration focus** |
| `pre_hard_tomorrow` | poor | **skip hard plan; recovery meal** |

## Meal templates (first 12 — `.ketoAnimalBasedNoPork`)

All use Safeway/Raley's-available ingredients. No pork. Animal-based.

| # | Name | Context | Macros (protein/fat/carb g) | Kcal |
|---|------|---------|-----------------------------|------|
| 1 | Ribeye + Butter Eggs | post_strength | 50/45/3 | 640 |
| 2 | Ground Beef Bowl | post_strength | 45/38/5 | 560 |
| 3 | Sirloin + Ghee + Berries | post_zone4 | 42/28/10 | 440 |
| 4 | Chicken Thighs + Bone Broth | post_zone2 | 38/30/2 | 420 |
| 5 | Eggs + Avocado + Beef Breakfast Sausage | rest_good | 30/42/4 | 520 |
| 6 | Liver + Onion + Butter | rest_poor | 35/22/6 | 360 |
| 7 | Ribeye + Eggs + Sardines | rest_poor | 55/48/1 | 660 |
| 8 | Chicken + Butter-Fried Zucchini | post_zone2 | 40/28/5 | 420 |
| 9 | Lamb Chops + Bone Broth | post_strength | 38/45/2 | 560 |
| 10 | Beef Tallow Egg Scramble + Cheese | rest_good | 34/40/3 | 500 |
| 11 | Grass-Fed Beef Bowl + Greek Yogurt | post_strength | 48/32/9 | 520 |
| 12 | Seared Steak + Grass-Fed Butter + Greens | pre_hard_tomorrow | 46/40/3 | 570 |

**Seed source:** Matt has 4 complete meal prep plans + shop lists to paste — this seed list stays until those arrive, then it gets replaced with his normalized plans.

Templates live in `data/meal-plans/keto-animal-templates.json` so they can evolve without recompiling the app. See `DAILY-DATA-ROUTINE.md` for the JSON schema.

## Integration points

- **Health tab** gets a new "Training Load" card: weekly TRIMP, acute:chronic ratio, recovery color dot.
- **Health tab** gets a "Next Meal" card: recommended template, quick "Log this meal" button.
- **Watch Quick Actions** adds "What should I eat?" → shows top 1 recommendation.
- **Assessment generation** pulls `trainingAlignmentScore` from the engine and feeds it into the Physical Health grade.

## Later (not Phase 1.5)

- `.normal` diet profile with full macro templates
- ML-ranked template selection based on what Matt actually ate vs what we recommended (preference learning)
- Integration with grocery delivery APIs to auto-generate shopping lists
- Recipe steps / plating photos

import Foundation

/// Deterministic meal recommender. Given a context, returns the best-fitting
/// meal template. Source: docs/TRAINING-INTELLIGENCE.md § Meal recommendation engine.
public enum MealRecommender {

    public struct Context: Sendable {
        public let todayWorkouts: [WorkoutProfile]
        public let tomorrowPlannedKind: WorkoutKind?
        public let recovery: RecoveryScore
        public let dietProfile: DietProfile
        public let weeklyMacrosSoFar: MacroTotals
        public let weeklyMacroTargets: MacroTotals
        public let recentlyEatenTemplateIds: [String]   // to encourage variety
        public let now: Date                            // for time-of-day slot selection

        public init(
            todayWorkouts: [WorkoutProfile],
            tomorrowPlannedKind: WorkoutKind? = nil,
            recovery: RecoveryScore,
            dietProfile: DietProfile = .ketoAnimalBasedNoPork,
            weeklyMacrosSoFar: MacroTotals = MacroTotals(),
            weeklyMacroTargets: MacroTotals = MacroTotals(kcal: 15_400, proteinG: 1_050, fatG: 1_050, carbG: 140),
            recentlyEatenTemplateIds: [String] = [],
            now: Date = .now
        ) {
            self.todayWorkouts = todayWorkouts
            self.tomorrowPlannedKind = tomorrowPlannedKind
            self.recovery = recovery
            self.dietProfile = dietProfile
            self.weeklyMacrosSoFar = weeklyMacrosSoFar
            self.weeklyMacroTargets = weeklyMacroTargets
            self.recentlyEatenTemplateIds = recentlyEatenTemplateIds
            self.now = now
        }

        /// Compute the meal slot for `now`. Considers whether a hard workout is
        /// planned tonight (uses tomorrowPlannedKind as a proxy for late-day fueling).
        public var mealSlot: MealSlot {
            let hardLater = (tomorrowPlannedKind == .strength || tomorrowPlannedKind == .zone4)
            return MealSlot.current(now: now, hasHardWorkoutTonight: hardLater)
        }
    }

    public struct Recommendation: Sendable {
        public let template: MealTemplate
        public let mealSlot: MealSlot
        public let reason: String           // human-readable "why"
        public let warning: String?         // optional ("HRV dropped — recovery-first meal")
    }

    /// Classify today's training context from logged workouts + tomorrow's plan.
    public static func classifyTraining(todayWorkouts: [WorkoutProfile],
                                        tomorrowPlannedKind: WorkoutKind?) -> MealContextTag.Training {
        // Tomorrow signals take precedence if there was no meaningful training today
        let didSomethingToday = todayWorkouts.contains { $0.kind != .rest && $0.durationMin >= 10 }

        if didSomethingToday {
            let hardest = todayWorkouts
                .filter { $0.kind != .rest }
                .max(by: { $0.kind.intensityFactor < $1.kind.intensityFactor })
            switch hardest?.kind {
            case .strength:   return .postStrength
            case .zone4:      return .postZone4
            case .zone2:      return .postZone2
            case .walk:       return .postZone2          // treat as light cardio recovery context
            case .sport:      return .postZone2
            case .mobility:   return .restDay
            case .rest, .none: return .restDay
            }
        }

        // Nothing done today → does tomorrow need fueling?
        switch tomorrowPlannedKind {
        case .strength, .zone4: return .preHardTomorrow
        default:                return .restDay
        }
    }

    /// Recommend the best meal template for the given context.
    /// Uses composite weighted scoring (slot fit + context match + variety) rather
    /// than strict tiered filtering, so a perfect-context-but-wrong-time-of-day
    /// template doesn't lock out a slightly-broader-context-but-perfect-time pick.
    public static func recommend(context: Context,
                                 templates: [MealTemplate] = KetoAnimalTemplates.all) -> Recommendation? {
        let trainingTag = classifyTraining(todayWorkouts: context.todayWorkouts,
                                           tomorrowPlannedKind: context.tomorrowPlannedKind)
        let slot = context.mealSlot

        Log.assessment.debug("Meal rec: slot=\(slot.rawValue) training=\(trainingTag.rawValue) recovery=\(context.recovery.rawValue)")

        // Candidate pool: same diet profile only.
        let pool = templates.filter { $0.dietProfile == context.dietProfile }
        guard !pool.isEmpty else { return nil }

        let proteinDeficit = max(0, context.weeklyMacroTargets.proteinG - context.weeklyMacrosSoFar.proteinG)

        // Compose a score for each template. Higher = better.
        // Scale: 0..100 each component, weighted.
        let scored = pool.map { tpl -> (MealTemplate, Double, String) in
            // Component 1 — slot fit. CONTINUOUS scoring (no plateau): every kcal off
            // target costs 0.4 points. So 600 kcal at lunch = 100; 500 kcal = 60; 350 = 0.
            let kcalDistance = Double(abs(tpl.macros.kcal - slot.targetKcal))
            let slotFit: Double = max(0, 100.0 - kcalDistance * 0.4)

            // Component 2 — context match.
            //   - exact (training+recovery): 100
            //   - training-only match:        70
            //   - fallback flag:              50
            //   - none:                       30
            let contextScore: Double = {
                if tpl.contexts.contains(MealContextTag(trainingTag, context.recovery)) { return 100 }
                if tpl.contexts.contains(where: { $0.training == trainingTag }) { return 70 }
                if tpl.isFallback { return 50 }
                return 30
            }()

            // Component 3 — variety. Recently eaten = penalty.
            let varietyScore: Double = context.recentlyEatenTemplateIds.contains(tpl.id) ? 30 : 100

            // Component 4 — macro fit. Reward higher protein when deficit.
            let macroScore: Double = proteinDeficit > 0
                ? min(100, Double(tpl.macros.proteinG) * 2)
                : 70

            // Weighted composite — slot fit dominates so the rec ACTUALLY changes
            // throughout the day. Context still matters but doesn't lock in a single
            // template when an exact match exists.
            //   slot 50% · context 20% · variety 20% · macro 10%
            let composite = slotFit * 0.5 + contextScore * 0.2 + varietyScore * 0.2 + macroScore * 0.1

            let why = "slot=\(Int(slotFit)) ctx=\(Int(contextScore)) var=\(Int(varietyScore)) mac=\(Int(macroScore))"
            return (tpl, composite, why)
        }

        // Log top 3 for debugging
        let top3 = scored.sorted { $0.1 > $1.1 }.prefix(3)
        for (i, entry) in top3.enumerated() {
            Log.assessment.debug("Meal rec #\(i+1): \(entry.0.name) score=\(entry.1, format: .fixed(precision: 1)) [\(entry.2)]")
        }

        guard let best = scored.max(by: { $0.1 < $1.1 }) else { return nil }
        let chosen = best.0

        let reason = "\(slot.displayName) · \(trainingTag.rawValue) · \(context.recovery.rawValue) recovery"
        let warning: String? = {
            if context.recovery == .poor && trainingTag == .preHardTomorrow {
                return "Recovery is poor. Consider postponing tomorrow's hard session."
            }
            if slot == .lateSnack && chosen.macros.kcal > 400 {
                return "Heavy meal this late may impact tomorrow's HRV."
            }
            if slot == .earlyMorning {
                return "Eating in the small hours — consider whether you actually need to."
            }
            return nil
        }()

        Log.assessment.info("Recommended meal: \(chosen.name) [\(chosen.id)] slot=\(slot.rawValue) score=\(best.1, format: .fixed(precision: 1)) (\(best.2))")
        return Recommendation(template: chosen, mealSlot: slot, reason: reason, warning: warning)
    }
}

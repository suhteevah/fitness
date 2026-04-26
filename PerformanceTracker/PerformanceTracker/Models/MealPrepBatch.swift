import Foundation
import SwiftData

/// A batch of meal prep — Matt cooks N templates on prep day, eats them across 3-5 days.
@Model
public final class MealPrepBatch {
    public var prepDate: Date
    public var coverDays: Int             // 3, 4, or 5
    public var templateIdsCSV: String     // comma-separated MealTemplate.id values
    public var notes: String?

    public init(prepDate: Date = .now, coverDays: Int, templateIds: [String], notes: String? = nil) {
        self.prepDate = prepDate
        self.coverDays = coverDays
        self.templateIdsCSV = templateIds.joined(separator: ",")
        self.notes = notes
    }

    public var templateIds: [String] {
        templateIdsCSV.split(separator: ",").map(String.init)
    }

    public var endDate: Date {
        Calendar.current.date(byAdding: .day, value: coverDays, to: prepDate) ?? prepDate
    }

    public var isActive: Bool {
        let now = Date.now
        return now >= prepDate && now <= endDate
    }
}

/// Pure-logic helper: given a coverage window and constraints, pick a balanced
/// set of templates spanning meal slots and varied proteins.
public enum MealPrepPlanner {

    /// Plan meals for a prep batch.
    /// - Parameters:
    ///   - days: number of days the prep should cover (3–5)
    ///   - dietProfile: which template pool to use
    ///   - templates: full template pool
    /// - Returns: ordered array of templates appropriate for batch-cooking.
    ///
    /// Strategy:
    ///   - Pick `days * 2` slot-anchor meals (lunch + dinner per day).
    ///   - Maximize protein variety: avoid two consecutive picks sharing the
    ///     primary protein keyword (rough heuristic on ingredients[0]).
    ///   - Bias toward kcal in 500–650 range (reheats well, fits both lunch and dinner).
    public static func plan(
        days: Int,
        dietProfile: DietProfile = .ketoAnimalBasedNoPork,
        templates: [MealTemplate] = KetoAnimalTemplates.all
    ) -> [MealTemplate] {
        let coverage = max(3, min(5, days))
        let mealCount = coverage * 2  // lunch + dinner per day

        // Eligible: reheatable mains. Filter to lunch/dinner kcal range (500–700).
        let eligible = templates.filter {
            $0.dietProfile == dietProfile &&
            (500...700).contains($0.macros.kcal)
        }
        guard !eligible.isEmpty else { return [] }

        // Greedy: pick variety by primary protein. Track used proteins.
        var picked: [MealTemplate] = []
        var lastProtein: String? = nil
        var usedIds = Set<String>()

        // Sort by descending kcal so the heaviest mains anchor early
        let sorted = eligible.sorted { $0.macros.kcal > $1.macros.kcal }

        // Round-robin attempt: prefer un-picked + different-protein candidates each step
        while picked.count < mealCount {
            let candidate = sorted.first { tpl in
                if usedIds.contains(tpl.id) { return false }
                if let last = lastProtein,
                   let primary = tpl.ingredients.first?.lowercased(),
                   primary.contains(last) || last.contains(primary) {
                    return false
                }
                return true
            } ?? sorted.first { !usedIds.contains($0.id) }    // fallback: any unused
              ?? sorted.first                                  // last resort: repeat

            guard let chosen = candidate else { break }
            picked.append(chosen)
            usedIds.insert(chosen.id)
            lastProtein = chosen.ingredients.first?.lowercased().split(separator: " ").last.map(String.init)
        }

        return picked
    }
}

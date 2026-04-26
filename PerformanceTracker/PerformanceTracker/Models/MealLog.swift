import Foundation
import SwiftData

/// A logged meal — when Matt taps "I made this" on a recommendation, or
/// adds a meal manually. Drives variety logic in MealRecommender.
@Model
public final class EatenMealLog {
    public var date: Date
    public var templateId: String?       // optional — manual entries may have no template
    public var name: String
    public var slot: String              // MealSlot.rawValue
    public var kcal: Int
    public var proteinG: Int
    public var fatG: Int
    public var carbG: Int

    public init(
        date: Date = .now,
        templateId: String? = nil,
        name: String,
        slot: MealSlot,
        kcal: Int,
        proteinG: Int,
        fatG: Int,
        carbG: Int
    ) {
        self.date = date
        self.templateId = templateId
        self.name = name
        self.slot = slot.rawValue
        self.kcal = kcal
        self.proteinG = proteinG
        self.fatG = fatG
        self.carbG = carbG
    }

    public var mealSlot: MealSlot { MealSlot(rawValue: slot) ?? .lunch }

    /// Build from a MealRecommender.Recommendation.
    @MainActor
    public static func from(recommendation: MealRecommender.Recommendation, date: Date = .now) -> EatenMealLog {
        EatenMealLog(
            date: date,
            templateId: recommendation.template.id,
            name: recommendation.template.name,
            slot: recommendation.mealSlot,
            kcal: recommendation.template.macros.kcal,
            proteinG: recommendation.template.macros.proteinG,
            fatG: recommendation.template.macros.fatG,
            carbG: recommendation.template.macros.carbG
        )
    }
}

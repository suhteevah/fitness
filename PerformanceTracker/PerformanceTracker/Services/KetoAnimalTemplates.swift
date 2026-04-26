import Foundation

/// Real meal templates derived from Matt's V5 (current primary) and V6 (rotation
/// alternate) meal plans, plus approved variations. NO PORK. LOW GREASE.
///
/// Source: meal-plan-handoff.zip (April 8, 2026):
///   - DIETARY_RULES.md — non-negotiables
///   - MEAL_PLANS.md — V5 / V6 detailed
///   - SHOPPING_LISTS.md — actual store quantities
///
/// Macro target: 2,200 kcal/day · 165g protein · 145g fat · <12g carbs
/// Goal: muscle building + body recomposition
public enum KetoAnimalTemplates {

    public static let all: [MealTemplate] = [

        // ── V5 (CURRENT PRIMARY) ──────────────────────────────────────────
        MealTemplate(
            id: "v5-breakfast",
            name: "V5 Breakfast: Eggs + 90/10 Ground Beef + Pepper Jack",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 500, proteinG: 38, fatG: 35, carbG: 2),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate),
                .init(.restDay, .good), .init(.restDay, .moderate),
                .init(.postZone2, .good)
            ],
            ingredients: [
                "4 pastured eggs",
                "3 oz 90/10 ground beef",
                "1 oz pepper jack cheese",
                "1 tbsp ghee",
                "smoked paprika",
                "garlic powder",
                "black pepper"
            ],
            source: "v5"
        ),
        MealTemplate(
            id: "v5-lunch",
            name: "V5 Lunch: Baked Chicken Breast + Gouda + Hard-Boiled Eggs",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 600, proteinG: 70, fatG: 30, carbG: 2),
            contexts: [
                .init(.postZone2, .good), .init(.postZone2, .moderate),
                .init(.restDay, .good), .init(.restDay, .moderate),
                .init(.postStrength, .good)
            ],
            ingredients: [
                "8 oz chicken breast",
                "2 oz gouda cheese",
                "2 hard-boiled pastured eggs",
                "everything bagel seasoning",
                "onion powder",
                "dried thyme",
                "salt"
            ],
            source: "v5"
        ),
        MealTemplate(
            id: "v5-postworkout",
            name: "V5 Post-Workout: Hard-Boiled Eggs + Chomps Beef Stick",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 250, proteinG: 25, fatG: 15, carbG: 2),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate), .init(.postStrength, .poor),
                .init(.postZone4, .good), .init(.postZone4, .moderate), .init(.postZone4, .poor),
                .init(.postZone2, .good), .init(.postZone2, .moderate)
            ],
            ingredients: [
                "3 hard-boiled pastured eggs",
                "1 Chomps beef stick"
            ],
            source: "v5"
        ),
        MealTemplate(
            id: "v5-dinner-strip",
            name: "V5 Dinner: NY Strip + Herb Butter + Blue Cheese",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 650, proteinG: 55, fatG: 45, carbG: 2),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate),
                .init(.postZone4, .good), .init(.postZone4, .moderate)
            ],
            ingredients: [
                "8 oz NY strip steak",
                "1 tbsp herb butter (butter + rosemary + garlic)",
                "2 oz blue cheese crumbles",
                "coarse salt",
                "cracked pepper"
            ],
            source: "v5"
        ),
        MealTemplate(
            id: "v5-dinner-chuck",
            name: "V5 Dinner: Chuck Steak + Herb Butter + Blue Cheese",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 640, proteinG: 52, fatG: 46, carbG: 2),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate), .init(.postStrength, .poor),
                .init(.restDay, .good)
            ],
            ingredients: [
                "8 oz chuck steak (markdown bin if available)",
                "1 tbsp herb butter",
                "2 oz blue cheese crumbles",
                "coarse salt",
                "cracked pepper",
                "dried rosemary"
            ],
            source: "v5"
        ),
        MealTemplate(
            id: "v5-evening-snack",
            name: "V5 Evening Snack: Macadamia Nuts + Cheese Stick",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 200, proteinG: 7, fatG: 20, carbG: 3),
            contexts: [
                .init(.restDay, .good), .init(.restDay, .moderate), .init(.restDay, .poor),
                .init(.postStrength, .good), .init(.postZone2, .good)
            ],
            ingredients: [
                "1 oz macadamia nuts",
                "1 mozzarella or colby jack cheese stick"
            ],
            source: "v5"
        ),

        // ── V6 (ROTATION ALTERNATE) ───────────────────────────────────────
        MealTemplate(
            id: "v6-breakfast",
            name: "V6 Breakfast: Eggs + Turkey Sausage 93/7 + Sharp Cheddar",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 480, proteinG: 36, fatG: 35, carbG: 2),
            contexts: [
                .init(.restDay, .good), .init(.restDay, .moderate),
                .init(.postZone2, .good)
            ],
            ingredients: [
                "3 pastured eggs",
                "2 oz turkey sausage 93/7 (no pork)",
                "1 oz sharp cheddar",
                "1 tbsp ghee",
                "oregano",
                "garlic powder"
            ],
            source: "v6"
        ),
        MealTemplate(
            id: "v6-lunch",
            name: "V6 Lunch: Chicken Breast + Havarti + Hard-Boiled Eggs",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 540, proteinG: 60, fatG: 28, carbG: 2),
            contexts: [
                .init(.postZone2, .good), .init(.postZone2, .moderate), .init(.postZone2, .poor),
                .init(.restDay, .good), .init(.restDay, .moderate)
            ],
            ingredients: [
                "6 oz chicken breast",
                "2 oz havarti or provolone",
                "2 hard-boiled pastured eggs",
                "rosemary",
                "black pepper"
            ],
            source: "v6"
        ),
        MealTemplate(
            id: "v6-dinner",
            name: "V6 Dinner: Sirloin + Herb Butter + Feta",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 580, proteinG: 50, fatG: 40, carbG: 2),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate), .init(.postStrength, .poor),
                .init(.postZone4, .good), .init(.postZone4, .moderate)
            ],
            ingredients: [
                "6-8 oz sirloin steak (3-4 min/side, pull at 130-135°F)",
                "1 tbsp herb butter (butter + rosemary + garlic)",
                "2 oz feta crumbles",
                "garlic powder",
                "oregano",
                "coarse salt",
                "extra ghee for cooking (lean meat)"
            ],
            source: "v6"
        ),
        MealTemplate(
            id: "v6-snack-pack",
            name: "V6 Snack Pack: Beef Stick + Macadamias + Cheese Stick",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 280, proteinG: 12, fatG: 22, carbG: 3),
            contexts: [
                .init(.postStrength, .poor), .init(.restDay, .poor),
                .init(.postZone4, .poor)
            ],
            ingredients: [
                "1 Chomps beef stick",
                "1 oz macadamia nuts",
                "1 cheese stick"
            ],
            source: "v6"
        ),

        // ── APPROVED VARIATIONS / EXTRAS ─────────────────────────────────
        MealTemplate(
            id: "salmon-dinner",
            name: "Salmon + Butter + Asparagus",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 480, proteinG: 38, fatG: 30, carbG: 4),
            contexts: [
                .init(.postZone2, .good), .init(.postZone2, .moderate), .init(.postZone2, .poor),
                .init(.restDay, .good)
            ],
            ingredients: [
                "5 oz salmon (skin-on)",
                "1 tbsp butter",
                "asparagus",
                "lemon",
                "salt"
            ],
            source: "approved"
        ),
        MealTemplate(
            id: "turkey-burger-lunch",
            name: "Turkey Burger + Feta + Ghee",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 500, proteinG: 45, fatG: 30, carbG: 2),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate),
                .init(.restDay, .good)
            ],
            ingredients: [
                "6 oz ground turkey 93/7 (1 patty)",
                "2 oz feta crumbles",
                "ghee for cooking",
                "garlic powder",
                "oregano"
            ],
            source: "approved"
        ),
        MealTemplate(
            id: "greek-yogurt-postwork",
            name: "Greek Yogurt (Fage/Chobani) + Small Berries",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 220, proteinG: 18, fatG: 8, carbG: 12),
            contexts: [
                .init(.postZone2, .good), .init(.postZone2, .moderate),
                .init(.postZone4, .good), .init(.postStrength, .good)
            ],
            ingredients: [
                "1 cup Fage Total or Chobani Whole Milk Plain (NOT flavored, NOT low-fat)",
                "small handful blueberries"
            ],
            source: "approved"
        ),
        MealTemplate(
            id: "corned-beef-dinner",
            name: "Corned Beef + Butter Cabbage",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 540, proteinG: 45, fatG: 35, carbG: 4),
            contexts: [
                .init(.restDay, .good), .init(.restDay, .moderate),
                .init(.postStrength, .poor)
            ],
            ingredients: [
                "6 oz corned beef (slow-simmered)",
                "1 cup cabbage, butter-wilted",
                "1 tbsp butter",
                "black pepper"
            ],
            source: "approved"
        ),
        MealTemplate(
            id: "chuck-pot-roast",
            name: "Chuck Pot Roast (Slow Cooker) + Butter Onions",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 580, proteinG: 50, fatG: 38, carbG: 4),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate), .init(.postStrength, .poor),
                .init(.postZone4, .poor),
                .init(.restDay, .moderate)
            ],
            ingredients: [
                "6 oz chuck pot roast (slow cooker, 8h low)",
                "caramelized onion",
                "1 tbsp butter",
                "rosemary",
                "garlic"
            ],
            source: "approved",
            isFallback: true
        ),

        // ── PRE-WORKOUT ──────────────────────────────────────────────────
        MealTemplate(
            id: "preworkout-eggs-stick",
            name: "Pre-Workout: 2 Eggs + Beef Stick",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 250, proteinG: 22, fatG: 15, carbG: 3),
            contexts: [
                .init(.preHardTomorrow, .good), .init(.preHardTomorrow, .moderate)
            ],
            ingredients: [
                "2 hard-boiled pastured eggs",
                "1 Chomps beef stick"
            ],
            source: "approved"
        ),
        MealTemplate(
            id: "preworkout-shake",
            name: "Pre-Workout: Whey Isolate + Almond Butter",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 280, proteinG: 30, fatG: 15, carbG: 8),
            contexts: [
                .init(.preHardTomorrow, .good)
            ],
            ingredients: [
                "1 scoop grass-fed whey isolate",
                "1 tbsp almond butter",
                "water",
                "ice"
            ],
            source: "approved"
        ),

        // ── POOR-RECOVERY / NUTRIENT-DENSE ───────────────────────────────
        MealTemplate(
            id: "bone-broth-egg",
            name: "Bone Broth + Hard-Boiled Egg (Recovery)",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 150, proteinG: 14, fatG: 9, carbG: 2),
            contexts: [
                .init(.restDay, .poor),
                .init(.preHardTomorrow, .poor)
            ],
            ingredients: [
                "1 large mug beef bone broth",
                "1 hard-boiled pastured egg",
                "sea salt"
            ],
            source: "approved"
        ),

        // ── MUSCLE-BUILDING EXPANSION (keto-animal-no-pork) ──────────────
        // High-protein, low-grease, anabolic-leaning. Designed for the
        // muscle-gain phase Matt entered Apr 2026 (TDEE ~2,840, target 165g
        // protein). All respect: no pork, low-grease cuts only, animal-based.
        MealTemplate(
            id: "cottage-cheese-power-bowl",
            name: "Cottage Cheese Power Bowl + Walnuts + Berries",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 480, proteinG: 38, fatG: 28, carbG: 10),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate),
                .init(.restDay, .good)
            ],
            ingredients: [
                "1 cup full-fat cottage cheese",
                "1 oz raw walnuts",
                "2 tbsp hemp seeds",
                "1/4 cup blueberries",
                "cinnamon"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "eggs-top-round-breakfast",
            name: "3 Eggs + Top Round Steak Strips",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 540, proteinG: 52, fatG: 32, carbG: 1),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate),
                .init(.postZone2, .good), .init(.restDay, .good)
            ],
            ingredients: [
                "3 pastured eggs",
                "5 oz top round steak (sliced)",
                "1 tbsp grass-fed butter",
                "Maldon salt",
                "black pepper"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "tuna-egg-avocado-stack",
            name: "Albacore Tuna + Hard-Boiled Eggs + Avocado",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 580, proteinG: 55, fatG: 38, carbG: 6),
            contexts: [
                .init(.postZone2, .good), .init(.restDay, .good),
                .init(.restDay, .moderate), .init(.postStrength, .moderate)
            ],
            ingredients: [
                "1 can albacore tuna in olive oil (drained)",
                "2 hard-boiled pastured eggs",
                "1/2 avocado",
                "lemon",
                "everything bagel seasoning"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "chicken-greek-caesar",
            name: "Chicken + Greek Yogurt Caesar Bowl",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 620, proteinG: 70, fatG: 32, carbG: 5),
            contexts: [
                .init(.postZone2, .good), .init(.postZone2, .moderate),
                .init(.restDay, .good), .init(.postStrength, .good)
            ],
            ingredients: [
                "8 oz grilled chicken breast",
                "1/2 cup full-fat Greek yogurt",
                "2 tbsp parmesan",
                "2 cups romaine",
                "1 anchovy fillet (mashed)",
                "lemon",
                "garlic powder"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "whey-mct-shake",
            name: "Whey + MCT Anabolic Shake",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 380, proteinG: 40, fatG: 22, carbG: 3),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate),
                .init(.postStrength, .poor)
            ],
            ingredients: [
                "1 scoop grass-fed whey isolate",
                "1 tbsp MCT oil",
                "2 tbsp heavy cream",
                "8 oz unsweetened almond milk",
                "ice",
                "cinnamon"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "sirloin-mushrooms-butter",
            name: "Top Sirloin + Sautéed Mushrooms + Butter",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 640, proteinG: 60, fatG: 42, carbG: 4),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate),
                .init(.restDay, .good)
            ],
            ingredients: [
                "8 oz top sirloin steak",
                "6 oz cremini mushrooms",
                "2 tbsp grass-fed butter",
                "fresh thyme",
                "garlic clove",
                "salt"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "casein-cottage-stack",
            name: "Casein + Cottage Cheese Pre-Bed Stack",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 320, proteinG: 38, fatG: 16, carbG: 6),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate),
                .init(.restDay, .good), .init(.preHardTomorrow, .good),
                .init(.preHardTomorrow, .moderate)
            ],
            ingredients: [
                "1 scoop casein protein",
                "1/2 cup full-fat cottage cheese",
                "1 oz raw almonds",
                "cinnamon",
                "1 tbsp heavy cream"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "greek-yogurt-pudding",
            name: "Greek Yogurt Protein Pudding",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 340, proteinG: 32, fatG: 20, carbG: 8),
            contexts: [
                .init(.postZone2, .good), .init(.restDay, .good),
                .init(.restDay, .moderate)
            ],
            ingredients: [
                "1 cup full-fat Greek yogurt",
                "1/2 scoop casein protein",
                "1 tbsp almond butter",
                "1 tsp cocoa powder",
                "stevia (optional)"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "ground-bison-skillet",
            name: "Lean Ground Bison + Kale Skillet",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 580, proteinG: 50, fatG: 38, carbG: 5),
            contexts: [
                .init(.postStrength, .good), .init(.postZone2, .good),
                .init(.restDay, .good)
            ],
            ingredients: [
                "8 oz lean ground bison",
                "2 cups chopped kale",
                "1 tbsp ghee",
                "garlic clove",
                "smoked paprika",
                "salt"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "salmon-asparagus-hollandaise",
            name: "Wild Salmon + Asparagus + Hollandaise",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 660, proteinG: 52, fatG: 46, carbG: 6),
            contexts: [
                .init(.postStrength, .good), .init(.postStrength, .moderate),
                .init(.postZone2, .good), .init(.restDay, .good)
            ],
            ingredients: [
                "8 oz wild-caught salmon fillet",
                "8 spears asparagus",
                "2 pastured egg yolks",
                "3 tbsp grass-fed butter",
                "lemon juice",
                "Dijon mustard",
                "salt"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "chicken-liver-pate-eggs",
            name: "Chicken Liver Pâté + Hard-Boiled Eggs",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 420, proteinG: 36, fatG: 28, carbG: 4),
            contexts: [
                .init(.restDay, .poor), .init(.preHardTomorrow, .poor),
                .init(.restDay, .moderate)
            ],
            ingredients: [
                "4 oz pastured chicken livers",
                "2 hard-boiled pastured eggs",
                "2 tbsp grass-fed butter",
                "fresh thyme",
                "salt",
                "Dijon (optional)"
            ],
            source: "muscle-build"
        ),
        MealTemplate(
            id: "beef-heart-steak-strips",
            name: "Grass-Fed Beef Heart Steak Strips",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 460, proteinG: 58, fatG: 22, carbG: 2),
            contexts: [
                .init(.restDay, .good), .init(.postStrength, .good),
                .init(.postZone2, .good)
            ],
            ingredients: [
                "6 oz grass-fed beef heart (sliced thin)",
                "1 tbsp grass-fed butter",
                "Maldon salt",
                "garlic powder",
                "black pepper"
            ],
            source: "muscle-build"
        ),

        // ── CARB-TOLERANT POST-STRENGTH REFEED ───────────────────────────
        // EXCEPTION to strict keto. Targeted glycogen-replenishment window
        // ONLY immediately after heavy strength sessions when recovery is
        // good. Tagged exclusively with (.postStrength, .good) so the
        // recommender will never suggest these on Zone 2, rest, or low-rec
        // days. Keep these as conscious cycling, not daily defaults.
        MealTemplate(
            id: "lean-beef-sweet-potato",
            name: "Lean Ground Beef + Sweet Potato (Post-Strength Refeed)",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 620, proteinG: 50, fatG: 22, carbG: 38),
            contexts: [
                .init(.postStrength, .good)
            ],
            ingredients: [
                "6 oz 90/10 ground beef",
                "1 small sweet potato (~150 g, baked)",
                "1 tbsp ghee",
                "salt",
                "black pepper",
                "rosemary"
            ],
            source: "muscle-build-refeed"
        ),
        MealTemplate(
            id: "chicken-rice-bowl",
            name: "Chicken Breast + Jasmine Rice Bowl (Post-Strength Refeed)",
            dietProfile: .ketoAnimalBasedNoPork,
            macros: MacroTotals(kcal: 660, proteinG: 60, fatG: 18, carbG: 50),
            contexts: [
                .init(.postStrength, .good)
            ],
            ingredients: [
                "6 oz grilled chicken breast",
                "3/4 cup cooked jasmine rice",
                "1 tbsp grass-fed butter",
                "everything bagel seasoning",
                "salt"
            ],
            source: "muscle-build-refeed"
        ),
    ]
}

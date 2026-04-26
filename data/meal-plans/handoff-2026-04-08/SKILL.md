---
name: meal-prep-planner
description: >
  Full-service meal preparation planning, shopping list generation, recipe creation, and nutritional analysis skill.
  Use this skill whenever the user mentions meal prep, meal planning, grocery shopping, shopping lists, weekly meals,
  cooking plans, recipes with nutrition info, macro tracking, calorie counting, diet plans, keto meals, bulking meals,
  cutting meals, food budgeting, or anything related to planning what to eat. Also trigger when user says
  'what should I eat', 'plan my meals', 'grocery run', 'shopping list', 'cook this week', 'meal ideas',
  'food prep', 'batch cooking', 'cookbook', 'recipe collection', or mentions combining meals into a reusable collection.
  Even if the user just says 'I need to eat better' or 'help me with food', use this skill. This skill supports
  dietary restrictions (keto, vegan, paleo, gluten-free, etc.), budget constraints, store-specific shopping,
  and persistent cookbook building across sessions.
---

# Meal Prep Planner

A comprehensive skill for generating meal plans, shopping lists, recipes, full nutritional breakdowns, and
persistent cookbook collections. Default plan length is **4 days** unless the user specifies otherwise.

---

## Workflow Overview

```
1. PROFILE  → Gather user dietary profile, location, preferred stores
2. PLAN     → Generate a 4-day (default) meal plan with all meals + snacks
3. SHOP     → Produce store-optimized shopping lists
4. COOK     → Output detailed recipes with step-by-step instructions
5. ANALYZE  → Full macro + micronutrient breakdown per meal and per day
6. COLLECT  → Save meals to a persistent "Cookbook" for mix-and-match reuse
```

---

## Step 1: User Profile Gathering

**ALWAYS start here if no profile exists in memory or conversation context.**

Use the `ask_user_input_v0` tool to gather preferences interactively. Collect the following:

### Required Information

| Field | How to Gather | Notes |
|---|---|---|
| **Location** | Ask directly or use `user_location_v0` | City/region for seasonal produce awareness |
| **Preferred Grocery Stores** | Ask user (multi-select common chains + freetext) | Used for store-specific aisle mapping |
| **Dietary Mode** | Single-select: Keto, Paleo, Vegan, Vegetarian, Mediterranean, Standard, Custom | Drives macro targets |
| **Daily Calorie Target** | Ask or calculate from goals | Default: 2000 kcal |
| **Allergies / Exclusions** | Freetext | Critical safety info |
| **Budget Preference** | Single-select: Budget, Moderate, No Limit | Affects ingredient choices |
| **Cooking Skill Level** | Single-select: Beginner, Intermediate, Advanced | Affects recipe complexity |
| **Household Size** | Ask (default: 1) | Scales all quantities |

### Dietary Mode Macro Targets (defaults, user can override)

```
Standard:       40C / 30P / 30F  (2000 kcal)
Keto:           5C  / 30P / 65F  (2000 kcal, <25g net carbs)
Paleo:          25C / 35P / 40F  (2000 kcal)
Vegan:          50C / 20P / 30F  (2000 kcal)
Vegetarian:     45C / 25P / 30F  (2000 kcal)
Mediterranean:  45C / 25P / 30F  (2000 kcal)
High-Protein:   30C / 40P / 30F  (2200 kcal)
Cutting:        35C / 40P / 25F  (1600 kcal)
Bulking:        45C / 30P / 25F  (3000 kcal)
```

### Memory Integration

After gathering the profile, offer to save it to Claude's memory using `memory_user_edits` so it persists
across conversations. Store as a compact string like:
`"Meal prep profile: [diet], [calories]kcal, shops at [stores], [city], [allergies], [household_size] servings"`

If a profile already exists in `userMemories`, confirm it's still accurate before proceeding.

---

## Step 2: Meal Plan Generation

### Structure

Generate a **4-day meal plan** (default) with this structure per day:

```
Day N: [Theme Name - e.g., "Mediterranean Monday"]
├── Breakfast     (target: ~25% daily calories)
├── Lunch         (target: ~35% daily calories)
├── Dinner        (target: ~30% daily calories)
└── Snack(s)      (target: ~10% daily calories)
```

### Plan Generation Rules

1. **Variety**: No repeated main proteins across consecutive days. Rotate protein sources.
2. **Prep Efficiency**: Flag meals that share ingredients. Identify batch-cook opportunities.
3. **Leftovers Strategy**: Dinner portions can be sized for next-day lunch repurposing.
4. **Seasonal Awareness**: Prefer in-season produce for the user's region when possible.
5. **Realistic Timing**: Tag each meal with estimated prep + cook time.
6. **Keto-Specific**: If keto mode, track net carbs (total carbs - fiber) and flag any meal >8g net carbs.

### Plan Output Format

Present the plan as a **clean, scannable React artifact** (`.jsx`) or **styled HTML** (`.html`):
- Day-by-day cards with meal names, brief descriptions, and calorie counts
- Color-coded macro indicators (protein=blue, carbs=amber, fat=green)
- Prep time badges
- Expandable sections for full recipes
- Daily totals bar at the bottom of each day card
- Running 4-day average summary

If the user prefers printable output, generate a **styled `.html`** file optimized for print media queries.

---

## Step 3: Shopping List Generation

### Organization Strategy

Shopping lists should be organized by **store section/aisle** for efficient shopping:

```
🥩 MEAT & SEAFOOD
  ☐ Chicken thighs, bone-in skin-on — 3 lbs ($X.XX est.)
  ☐ Ground beef 80/20 — 2 lbs ($X.XX est.)

🥬 PRODUCE
  ☐ Broccoli crowns — 2 heads
  ☐ Avocados — 4 ($X.XX est.)

🧀 DAIRY & EGGS
  ☐ Large eggs — 1 dozen
  ☐ Heavy cream — 1 pint

🥫 PANTRY / CANNED
  ☐ Coconut aminos — 1 bottle (if not stocked)
  ☐ Diced tomatoes 14oz — 2 cans

❄️ FROZEN
  ☐ Frozen cauliflower rice — 2 bags

💊 SPECIALTY / SUPPLEMENTS
  ☐ (Only if diet requires)
```

### Shopping List Rules

1. **Consolidate**: Combine identical ingredients across all meals into single line items with total quantities.
2. **Unit Standardization**: Convert everything to practical shopping units (don't say "227g chicken" — say "½ lb chicken").
3. **Pantry Check**: Mark items as "(if not stocked)" for common pantry staples (oils, spices, salt, pepper).
4. **Cost Estimates**: Provide rough per-item cost estimates based on typical US grocery pricing. Note these are estimates.
5. **Store-Specific Notes**: If user named specific stores, add notes like "Costco bulk option: 5lb bag saves ~30%".
6. **Total Estimate**: Sum all items for a trip total estimate.

### Shopping List Output

Generate as a **React artifact** with:
- Checkboxes for each item (interactive)
- Section headers with store aisle grouping
- Quantity + estimated cost columns
- "Pantry staples" collapsible section
- Total cost estimate at bottom
- Print button that triggers clean print layout

Also offer to export as a **plain text** file for phone notes apps.

---

## Step 4: Recipe Output

### Recipe Format

Each recipe should include:

```
═══════════════════════════════════════════
📖 [RECIPE NAME]
═══════════════════════════════════════════
Serves: X  |  Prep: XXmin  |  Cook: XXmin  |  Total: XXmin
Difficulty: ⭐⭐☆ (Intermediate)
Diet Tags: [Keto] [Gluten-Free] [Dairy-Free]

INGREDIENTS
───────────────────────────────────────────
• 2 lbs chicken thighs, bone-in
• 1 tbsp avocado oil
• ...

INSTRUCTIONS
───────────────────────────────────────────
1. Preheat oven to 400°F (204°C).
2. Pat chicken dry with paper towels. Season generously...
3. ...

PRO TIPS
───────────────────────────────────────────
💡 Dry-brining overnight improves texture dramatically.
💡 Internal temp target: 165°F (74°C) at thickest part.

STORAGE
───────────────────────────────────────────
Fridge: 4 days | Freezer: 3 months
Reheat: 350°F oven 15min or microwave 2min
```

### Recipe Rules

1. **Precise Measurements**: Always include both volume and weight where practical.
2. **Temperature Duals**: Provide both °F and °C.
3. **Substitutions**: Note 1-2 substitutions for key ingredients where possible.
4. **Timing Cues**: Use sensory cues alongside times ("cook until golden brown, about 5-7 minutes").
5. **Batch Scaling**: Note if recipe scales well for meal prep.

---

## Step 5: Nutritional Analysis

### Per-Meal Breakdown

Every meal gets a **complete nutritional panel**:

#### Macronutrients
| Nutrient | Amount | % Daily Value | % of Meal Calories |
|---|---|---|---|
| Calories | XXX kcal | XX% | 100% |
| Protein | XXg | XX% | XX% |
| Total Fat | XXg | XX% | XX% |
| — Saturated Fat | XXg | XX% | — |
| — Monounsaturated | XXg | — | — |
| — Polyunsaturated | XXg | — | — |
| — Trans Fat | XXg | — | — |
| Total Carbs | XXg | XX% | XX% |
| — Dietary Fiber | XXg | XX% | — |
| — Net Carbs | XXg | — | — |
| — Sugars | XXg | — | — |
| — Added Sugars | XXg | XX% | — |

#### Micronutrients
| Nutrient | Amount | % Daily Value | Status |
|---|---|---|---|
| Vitamin A | XXX mcg RAE | XX% | ✅/⚠️/❌ |
| Vitamin C | XX mg | XX% | ✅/⚠️/❌ |
| Vitamin D | XX mcg | XX% | ✅/⚠️/❌ |
| Vitamin E | XX mg | XX% | ✅/⚠️/❌ |
| Vitamin K | XX mcg | XX% | ✅/⚠️/❌ |
| Thiamin (B1) | XX mg | XX% | ✅/⚠️/❌ |
| Riboflavin (B2) | XX mg | XX% | ✅/⚠️/❌ |
| Niacin (B3) | XX mg | XX% | ✅/⚠️/❌ |
| Vitamin B6 | XX mg | XX% | ✅/⚠️/❌ |
| Folate (B9) | XX mcg DFE | XX% | ✅/⚠️/❌ |
| Vitamin B12 | XX mcg | XX% | ✅/⚠️/❌ |
| Calcium | XXX mg | XX% | ✅/⚠️/❌ |
| Iron | XX mg | XX% | ✅/⚠️/❌ |
| Magnesium | XXX mg | XX% | ✅/⚠️/❌ |
| Phosphorus | XXX mg | XX% | ✅/⚠️/❌ |
| Potassium | XXX mg | XX% | ✅/⚠️/❌ |
| Sodium | XXX mg | XX% | ✅/⚠️/❌ |
| Zinc | XX mg | XX% | ✅/⚠️/❌ |
| Selenium | XX mcg | XX% | ✅/⚠️/❌ |
| Copper | XX mg | XX% | ✅/⚠️/❌ |
| Manganese | XX mg | XX% | ✅/⚠️/❌ |
| Omega-3 (EPA+DHA) | XX mg | — | ✅/⚠️/❌ |

**Status Icons**: ✅ = >50% DV | ⚠️ = 25-50% DV | ❌ = <25% DV

#### Per-Day Totals

Aggregate all meals for the day and show a summary dashboard with:
- Total calories vs target (with over/under indicator)
- Macro split pie chart (use Recharts in React artifact)
- Micronutrient coverage heatmap (green/yellow/red)
- Flags for any nutrients consistently below 50% DV across the plan

#### 4-Day Plan Summary

At the end of a full plan, show:
- Average daily intake across all 4 days
- Nutrients that are consistently deficient → suggest supplementation or ingredient swaps
- Nutrients that are excessive → flag potential concerns
- Overall diet quality score (simple 1-100 based on coverage of DV targets)

### Nutritional Data Sources

Claude should use its training knowledge of USDA FoodData Central nutritional values. Note in output:
> ⚠️ Nutritional values are estimates based on USDA reference data for standard ingredients.
> Actual values vary by brand, source, and preparation method. For clinical dietary needs,
> consult a registered dietitian.

For more precise lookups when available, use `web_search` to query USDA FoodData Central
(fdc.nal.usda.gov) for specific ingredients the user asks about.

---

## Step 6: Cookbook Collection System

The Cookbook is a **persistent, growing collection** of meals the user has liked, allowing mix-and-match
meal planning without monotony.

### Cookbook Storage

Use the **artifact persistent storage API** (`window.storage`) to save and retrieve cookbook entries:

```javascript
// Save a meal to the cookbook
await window.storage.set(`cookbook:${mealId}`, JSON.stringify({
  id: mealId,
  name: "Garlic Butter Chicken Thighs",
  category: "dinner",           // breakfast | lunch | dinner | snack
  dietTags: ["keto", "gluten-free"],
  prepTime: 10,
  cookTime: 35,
  calories: 485,
  macros: { protein: 42, fat: 32, netCarbs: 3, fiber: 1 },
  rating: 5,                     // user rating 1-5
  timesUsed: 3,
  lastUsed: "2026-02-20",
  ingredients: [...],
  instructions: [...],
  micronutrients: {...},
  notes: "User note: add extra garlic next time"
}), false);  // personal data, not shared

// List all cookbook entries
const keys = await window.storage.list('cookbook:');

// Retrieve a specific meal
const meal = await window.storage.get('cookbook:garlic-butter-chicken');
```

### Cookbook Features

1. **Add to Cookbook**: After generating any meal plan, offer "Save to Cookbook?" for each meal.
   User can rate meals 1-5 stars and add personal notes.

2. **Browse Cookbook**: Present a searchable/filterable React artifact showing all saved meals.
   Filter by: category, diet tags, prep time, rating, macro ranges.

3. **Mix-and-Match Planning**: When generating a new plan, offer to pull favorites from the cookbook.
   "Use 2 cookbook favorites + 2 new recipes" as a default mix option.

4. **Anti-Monotony Engine**: Track `lastUsed` dates and `timesUsed` counts.
   When pulling from cookbook, prefer meals not used in the last 2 weeks.
   Suggest new recipes that complement existing cookbook gaps (e.g., "Your cookbook is heavy on
   chicken — try this salmon recipe to diversify omega-3 intake").

5. **Cookbook Export**: Generate a beautifully formatted `.html` or `.docx` cookbook document
   with all saved recipes, organized by category, with full nutritional panels.
   Use the `docx` skill (read `/mnt/skills/public/docx/SKILL.md`) for Word document generation.

### Cookbook Artifact

The main cookbook browser should be a **React artifact** with:
- Grid/list toggle view
- Category tabs (Breakfast / Lunch / Dinner / Snacks)
- Star rating display
- Quick-filter chips for diet tags
- Search bar for recipe names/ingredients
- "Generate Plan from Cookbook" button that creates a random 4-day plan from saved meals
- Nutrition summary panel when meals are selected

---

## Output Artifacts Strategy

| Deliverable | Format | Tool |
|---|---|---|
| Meal Plan Overview | React `.jsx` artifact | Interactive cards with expand/collapse |
| Shopping List | React `.jsx` artifact | Checkboxes, print button, cost totals |
| Individual Recipe | Styled `.html` or inline | Print-optimized |
| Nutritional Dashboard | React `.jsx` with Recharts | Pie charts, heatmaps, bar charts |
| Full Plan Document | `.docx` via docx skill | For printing/sharing |
| Cookbook Browser | React `.jsx` with storage | Persistent collection manager |
| Quick Shopping List | Plain `.txt` file | For phone notes/SMS |

### Verbose Logging

All scripts and artifacts created by this skill should include verbose console logging:

```javascript
console.log('[MealPrep] Generating 4-day plan...');
console.log('[MealPrep] Diet mode:', dietMode);
console.log('[MealPrep] Calorie target:', calorieTarget);
console.log('[MealPrep] Calculating Day 1 macros...');
// ... etc
```

This aids debugging and lets the user see what's happening under the hood.

---

## Edge Cases & Error Handling

1. **No location provided**: Default to US national averages for pricing/seasonal produce.
2. **Conflicting diet + allergies**: Flag conflicts (e.g., "Keto + nut allergy limits fat sources — here's how we'll compensate").
3. **Extreme calorie targets**: Warn if target is <1200 or >4000 kcal and ask to confirm.
4. **Missing nutritional data**: If a specialty ingredient lacks USDA data, estimate from similar items and mark with "~" prefix.
5. **Budget constraints**: If "Budget" mode, avoid expensive proteins (salmon, grass-fed beef) and suggest alternatives.

---

## Quick Reference: File Locations

When generating documents, always read the relevant skill first:
- Word documents → Read `/mnt/skills/public/docx/SKILL.md`
- PDF output → Read `/mnt/skills/public/pdf/SKILL.md`
- Spreadsheets → Read `/mnt/skills/public/xlsx/SKILL.md`
- Presentations → Read `/mnt/skills/public/pptx/SKILL.md`
- Beautiful UI → Read `/mnt/skills/public/frontend-design/SKILL.md`

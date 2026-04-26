# Design System

> Source of truth for colors, typography, and UI tokens. Primary design target is dark mode.

## Brand

Performance tracking for Ridge Cell Repair LLC — serious but calm. Soft purple establishes identity without being aggressive or candy-pastel. Gold + teal accents supply the semantic "wins" and "steady" dimensions without fighting the primary.

## Palette

### Core

| Role | Name | Hex | HSL | Use |
|------|------|-----|-----|-----|
| **Primary** | Soft Iris | `#8B7FC9` | 250°, 41%, 64% | app identity — tab tint, nav, primary buttons, selected states |
| **Accent Warm** | Honey Gold | `#E2B657` | 43°, 70%, 62% | achievements, A-range grades, positive deltas, "improving" trends |
| **Accent Cool** | Sea Glass Teal | `#65C4B8` | 172°, 48%, 58% | informational, B-range grades, "steady" trends |

**Why this works (color theory):**
- Soft Iris sits at 250° (blue-purple).
- Honey Gold at 43° is ~27° off the true complement (70°) — close enough to pop against purple (classic royal gold + purple pairing) without clashing.
- Sea Glass Teal at 172° sits analogous-to-complement — cooler companion to gold, harmonizes with primary on the cool side.
- This is a **split-complementary + warm pop** scheme — more dynamic than analogous, less jarring than triadic.

### Grade ramp

Sequential warm→cool with clear semantic gaps. All tested at WCAG AA against `#111` dark background.

| Grade | Name | Hex | Reasoning |
|-------|------|-----|-----------|
| A+ / A / A- | Honey Gold | `#E2B657` | celebration |
| B+ / B / B- | Sea Glass Teal | `#65C4B8` | calm positive |
| C+ / C / C- | Soft Amber | `#E0A558` | neutral warning — darker relative of gold |
| D+ / D / D- | Warm Coral | `#E18664` | concern |
| F | Deep Red | `#C44D4D` | crisis |
| Incomplete | Cool Gray | `#8A8A95` | neutral, low-contrast placeholder |

Within each tier, the `+` variant lightens by ~8% and `-` darkens by ~8% for micro-distinction.

### Neutrals (dark mode)

| Token | Hex | Use |
|-------|-----|-----|
| `background.primary` | `#0E0E12` | page background |
| `background.card` | `rgba(255,255,255,0.05)` | card/surface |
| `background.elevated` | `rgba(255,255,255,0.08)` | modals, elevated surfaces |
| `text.primary` | `#EAEAF0` | body text |
| `text.secondary` | `rgba(234,234,240,0.65)` | supporting text |
| `divider` | `rgba(255,255,255,0.08)` | separators |

### Neutrals (light mode — future)

| Token | Hex |
|-------|-----|
| `background.primary` | `#F8F7FB` |
| `background.card` | `#FFFFFF` |
| `text.primary` | `#1A1A22` |
| `text.secondary` | `rgba(26,26,34,0.65)` |

Light mode ships after dark mode is polished. Soft Iris `#8B7FC9` also needs a darker light-mode variant (`#6B5FA8`) for AA contrast against `#FFFFFF`.

## Typography

All system fonts (no custom font files):

| Role | Font | Size | Weight |
|------|------|------|--------|
| Display (grade letter) | SF Pro Rounded | 44–80pt | Heavy |
| Title | SF Pro | 28pt | Bold |
| Headline | SF Pro | 17pt | Semibold |
| Body | SF Pro | 15pt | Regular |
| Caption | SF Pro | 12pt | Regular |

Rounded used **only** for the large grade letter inside `GradeRingView` — feels friendlier/less clinical for a personal app. Everything else is standard SF Pro.

## Iconography

SF Symbols exclusively. No custom art in Phase 1. Category icons already locked in (`docs/GRADING-RUBRIC.md` implied mapping):

| Category | Symbol |
|----------|--------|
| Product Development | `hammer.fill` |
| Revenue & Pipeline | `dollarsign.circle.fill` |
| Job Hunting | `briefcase.fill` |
| Client Work | `person.2.fill` |
| Physical Health | `heart.fill` |
| Time Management | `calendar` |
| Strategy | `brain.head.profile` |

## Spacing

8pt grid: `[4, 8, 12, 16, 20, 24, 32, 48]`. No off-grid spacing.

## Component tokens

### GradeRingView
- Ring stroke: 18pt (main), 10pt (watch), 6pt (sparkline avatar)
- Background ring: `rgba(255,255,255,0.08)`
- Fill ring: grade's `colorFamily.color`
- Center letter: 35% of diameter, Heavy Rounded
- GPA subtext: 12pt, `text.secondary`

### CategoryCardView
- Padding: 14
- Corner radius: 14
- Background: `background.card`
- Icon: 15pt, grade color
- Grade label: 20pt Heavy, grade color
- Sparkline: 26pt height, grade color, 2pt stroke

### Button primary
- Background: `primary` at 20% alpha
- Foreground: `primary`
- Corner radius: 14
- Padding: 14 vertical

## Accessibility

- Minimum contrast: WCAG AA (4.5:1 for body, 3:1 for large/graphical)
- VoiceOver labels on all grade displays ("Overall grade A-minus, 3.7 GPA")
- Dynamic Type supported for all body/caption text
- Don't encode meaning in color alone — always pair grade color with the letter label

## Implementation notes

- Colors defined in `Shared/Grade.swift` (`GradeColorFamily` enum with `.color` computed property)
- Asset catalog `AccentColor.colorset` holds the primary Soft Iris
- Semantic colors (background/text) read from system when possible (`.primary`, `.secondary`) and fall back to hex only where needed for brand consistency
- When adding a new color, update this doc first, then the Swift code

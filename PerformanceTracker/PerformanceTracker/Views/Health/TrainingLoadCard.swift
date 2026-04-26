import SwiftUI

/// Summary of weekly training load + recovery state + next-meal rec.
public struct TrainingLoadCard: View {
    public let weeklyTRIMP: Double
    public let acuteChronicRatio: Double?
    public let recovery: RecoveryScore

    public init(weeklyTRIMP: Double, acuteChronicRatio: Double?, recovery: RecoveryScore) {
        self.weeklyTRIMP = weeklyTRIMP
        self.acuteChronicRatio = acuteChronicRatio
        self.recovery = recovery
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "flame.fill").foregroundStyle(Brand.honeyGold)
                Text("Training Load").font(.subheadline.weight(.semibold))
                Spacer()
                recoveryBadge
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(weeklyTRIMP))")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(Brand.honeyGold)
                Text("TRIMP this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let acr = acuteChronicRatio {
                Text(acrDescription(acr))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Need 28 days of history for acute:chronic ratio.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    private var recoveryBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(recoveryColor)
                .frame(width: 8, height: 8)
            Text(recovery.rawValue.capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(recoveryColor)
        }
    }

    private var recoveryColor: Color {
        switch recovery {
        case .good: return Brand.seaGlassTeal
        case .moderate: return Brand.honeyGold
        case .poor: return Color(red: 0.882, green: 0.525, blue: 0.392)
        }
    }

    private func acrDescription(_ ratio: Double) -> String {
        switch ratio {
        case ..<0.8: return String(format: "Undertraining (ACR %.2f — below 0.8).", ratio)
        case 0.8...1.3: return String(format: "In the sweet spot (ACR %.2f).", ratio)
        case 1.3...1.5: return String(format: "Pushing it (ACR %.2f — watch for fatigue).", ratio)
        default: return String(format: "Overreaching (ACR %.2f > 1.5).", ratio)
        }
    }
}

/// Recommended-meal card that shows the top template for current context.
public struct NextMealCard: View {
    public let recommendation: MealRecommender.Recommendation?
    public let onMadeThis: ((MealRecommender.Recommendation) -> Void)?

    public init(
        recommendation: MealRecommender.Recommendation?,
        onMadeThis: ((MealRecommender.Recommendation) -> Void)? = nil
    ) {
        self.recommendation = recommendation
        self.onMadeThis = onMadeThis
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "fork.knife").foregroundStyle(Brand.softIris)
                Text("Next Meal").font(.subheadline.weight(.semibold))
                if let slot = recommendation?.mealSlot {
                    Text("· \(slot.displayName)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            if let rec = recommendation {
                Text(rec.template.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.softIris)
                HStack(spacing: 10) {
                    macroPill("P", rec.template.macros.proteinG, color: Brand.seaGlassTeal)
                    macroPill("F", rec.template.macros.fatG, color: Brand.honeyGold)
                    macroPill("C", rec.template.macros.carbG, color: Color(red: 0.878, green: 0.647, blue: 0.345))
                    Spacer()
                    Text("\(rec.template.macros.kcal) kcal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(rec.reason)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let warning = rec.warning {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text(warning).font(.caption)
                    }
                    .foregroundStyle(Color(red: 0.882, green: 0.525, blue: 0.392))
                }
                if onMadeThis != nil {
                    Button {
                        onMadeThis?(rec)
                    } label: {
                        Label("I made this", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Brand.softIris.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(Brand.softIris)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            } else {
                Text("No recommendation — log a workout or wait for the daily routine.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    private func macroPill(_ label: String, _ grams: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label).font(.caption2.weight(.bold)).foregroundStyle(color)
            Text("\(grams)g").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.15), in: Capsule())
    }
}

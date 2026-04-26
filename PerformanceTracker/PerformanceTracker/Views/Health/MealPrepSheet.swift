import SwiftUI
import SwiftData

public struct MealPrepSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var coverDays: Double = 4
    @State private var plan: [MealTemplate] = []
    @State private var showShoppingList = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    daysSlider
                    safetyNote
                    planPreview
                    confirmButton
                }
                .padding()
            }
            .navigationTitle("Meal Prep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .sheet(isPresented: $showShoppingList) {
                ShoppingListView(templates: plan)
            }
            .onAppear { regeneratePlan() }
            .onChange(of: coverDays) { _, _ in regeneratePlan() }
        }
    }

    private var daysSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Cover").font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(coverDays)) days").font(.title3.weight(.heavy)).foregroundStyle(Brand.softIris)
            }
            Slider(value: $coverDays, in: 3...5, step: 1)
                .tint(Brand.softIris)
            HStack {
                Text("3").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("4").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("5").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var safetyNote: some View {
        let note: (icon: String, text: String, color: Color) = {
            switch Int(coverDays) {
            case 3: return ("checkmark.shield.fill", "Safe — well within USDA fridge guidance for cooked meat.", Brand.seaGlassTeal)
            case 4: return ("checkmark.shield.fill", "Safe — USDA hard ceiling for cooked meat in fridge below 40°F.", Brand.seaGlassTeal)
            case 5: return ("exclamationmark.triangle.fill", "Day 5 pushes USDA limits — vacuum-seal portions OR freeze portions for days 4–5 and thaw.", Brand.honeyGold)
            default: return ("info.circle", "—", Color.gray)
            }
        }()
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: note.icon).foregroundStyle(note.color)
            Text(note.text).font(.caption).foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(note.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private var planPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Planned meals (\(plan.count))")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Re-roll") { regeneratePlan() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.softIris)
            }
            ForEach(Array(plan.enumerated()), id: \.offset) { idx, tpl in
                HStack(alignment: .top) {
                    Text("\(idx + 1).")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 22, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tpl.name).font(.subheadline.weight(.medium))
                        Text("\(tpl.macros.kcal) kcal · \(tpl.macros.proteinG)P / \(tpl.macros.fatG)F / \(tpl.macros.carbG)C")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var confirmButton: some View {
        VStack(spacing: 10) {
            Button {
                showShoppingList = true
            } label: {
                Label("Generate Shopping List", systemImage: "cart.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Brand.honeyGold.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Brand.honeyGold)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)

            Button {
                save()
                dismiss()
            } label: {
                Text("Confirm Prep Plan")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Brand.softIris.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Brand.softIris)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
        }
    }

    private func regeneratePlan() {
        plan = MealPrepPlanner.plan(days: Int(coverDays))
    }

    private func save() {
        let batch = MealPrepBatch(
            coverDays: Int(coverDays),
            templateIds: plan.map(\.id)
        )
        context.insert(batch)
        try? context.save()
        Log.viewModel.info("Saved meal prep batch: \(batch.coverDays) days, \(batch.templateIds.count) meals")
    }
}

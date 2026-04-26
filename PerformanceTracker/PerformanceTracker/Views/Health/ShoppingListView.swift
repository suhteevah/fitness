import SwiftUI

public struct ShoppingListView: View {
    @Environment(\.dismiss) private var dismiss
    public let templates: [MealTemplate]

    @State private var checked: Set<String> = []
    @State private var showShareSheet = false

    public init(templates: [MealTemplate]) {
        self.templates = templates
    }

    /// Aggregate ingredients across all templates: count occurrences so the user
    /// knows "you need 2× ribeye, 1× butter, etc." Free-text matching is rough
    /// (no quantity normalization yet); merging is by lowercase exact match.
    private var aggregatedItems: [(name: String, count: Int, mealNames: [String])] {
        var map: [String: (count: Int, mealNames: [String])] = [:]
        for tpl in templates {
            for ingredient in tpl.ingredients {
                let key = ingredient.lowercased()
                let existing = map[key] ?? (count: 0, mealNames: [])
                map[key] = (
                    count: existing.count + 1,
                    mealNames: existing.mealNames + [tpl.name]
                )
            }
        }
        return map
            .map { (name: $0.key.capitalized(with: .current), count: $0.value.count, mealNames: $0.value.mealNames) }
            .sorted { $0.count > $1.count }
    }

    /// Group items into rough Safeway/Raley's shopping aisles.
    private enum Aisle: String, CaseIterable {
        case meat = "Meat & Seafood"
        case dairy = "Dairy & Eggs"
        case produce = "Produce"
        case pantry = "Pantry"
        case other = "Other"
    }

    private func aisle(for ingredient: String) -> Aisle {
        let lc = ingredient.lowercased()
        let meatTerms = ["ribeye", "sirloin", "lamb", "chicken", "beef", "salmon", "sardines", "tuna", "liver", "heart", "marrow", "brisket", "tartare", "tenderloin", "sausage", "jerky", "pâté", "stick", "shank"]
        let dairyTerms = ["egg", "butter", "ghee", "yogurt", "cheese", "feta", "cottage", "cream", "whey"]
        let produceTerms = ["spinach", "kale", "berries", "blueber", "avocado", "onion", "zucchini", "asparagus", "cauliflower", "lemon", "garlic", "rosemary", "dill", "thyme", "chard"]
        let pantryTerms = ["broth", "tallow", "olive oil", "salt", "salt", "pepper", "almond butter", "honey", "cinnamon", "wasabi", "soy", "aminos", "horseradish", "capers", "mustard", "tomato"]

        if meatTerms.contains(where: lc.contains) { return .meat }
        if dairyTerms.contains(where: lc.contains) { return .dairy }
        if produceTerms.contains(where: lc.contains) { return .produce }
        if pantryTerms.contains(where: lc.contains) { return .pantry }
        return .other
    }

    private var byAisle: [(Aisle, [(name: String, count: Int, mealNames: [String])])] {
        var grouped: [Aisle: [(name: String, count: Int, mealNames: [String])]] = [:]
        for item in aggregatedItems {
            let a = aisle(for: item.name)
            grouped[a, default: []].append(item)
        }
        return Aisle.allCases.compactMap { aisle in
            guard let items = grouped[aisle], !items.isEmpty else { return nil }
            return (aisle, items)
        }
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(byAisle, id: \.0) { aisle, items in
                    Section(aisle.rawValue) {
                        ForEach(items, id: \.name) { item in
                            row(item: item)
                        }
                    }
                }
                if templates.isEmpty {
                    Text("No meals planned yet — pick a coverage range first.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [exportText])
            }
        }
    }

    @ViewBuilder
    private func row(item: (name: String, count: Int, mealNames: [String])) -> some View {
        Button {
            if checked.contains(item.name) {
                checked.remove(item.name)
            } else {
                checked.insert(item.name)
            }
        } label: {
            HStack {
                Image(systemName: checked.contains(item.name) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checked.contains(item.name) ? Brand.seaGlassTeal : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.name)
                            .strikethrough(checked.contains(item.name))
                            .foregroundStyle(checked.contains(item.name) ? .secondary : .primary)
                        if item.count > 1 {
                            Text("× \(item.count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Brand.softIris)
                        }
                    }
                    Text(item.mealNames.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var exportText: String {
        var lines: [String] = ["# Shopping List", "", "Meals planned: \(templates.count)", ""]
        for (aisle, items) in byAisle {
            lines.append("## \(aisle.rawValue)")
            for item in items {
                let qty = item.count > 1 ? " × \(item.count)" : ""
                lines.append("- [ ] \(item.name)\(qty)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

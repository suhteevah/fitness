import SwiftUI

public struct CategoryCardView: View {
    public let category: GradeCategory
    public let grade: Grade
    public let trend: [Grade]     // oldest → newest

    public init(category: GradeCategory, grade: Grade, trend: [Grade] = []) {
        self.category = category
        self.grade = grade
        self.trend = trend
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: category.systemImageName)
                    .foregroundStyle(grade.colorFamily.color)
                Text(category.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(grade == .incomplete ? "—" : grade.rawValue)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(grade.colorFamily.color)
            }
            TrendSparklineView(trend: trend, tint: grade.colorFamily.color)
                .frame(height: 26)
            Text("\(Int(category.weight * 100))% weight")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}

public struct TrendSparklineView: View {
    public let trend: [Grade]
    public let tint: Color

    public init(trend: [Grade], tint: Color) {
        self.trend = trend
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            if trend.isEmpty {
                Text("No history yet").font(.caption2).foregroundStyle(.secondary)
            } else {
                let points: [Double] = trend.map { $0.gpa ?? 0 }
                let maxV: Double = max(points.max() ?? 1, 1)
                let minV: Double = 0
                let range = max(maxV - minV, 0.001)

                Path { p in
                    for (i, v) in points.enumerated() {
                        let x = geo.size.width * CGFloat(i) / CGFloat(max(points.count - 1, 1))
                        let y = geo.size.height - CGFloat((v - minV) / range) * geo.size.height
                        if i == 0 { p.move(to: .init(x: x, y: y)) }
                        else { p.addLine(to: .init(x: x, y: y)) }
                    }
                }
                .stroke(tint, lineWidth: 2)
            }
        }
    }
}

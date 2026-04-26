import SwiftUI

/// Large circular grade ring. Shows the letter in the center with a colored arc.
public struct GradeRingView: View {
    public let grade: Grade
    public let gpa: Double?
    public let diameter: CGFloat
    public let lineWidth: CGFloat

    public init(grade: Grade, gpa: Double? = nil, diameter: CGFloat = 220, lineWidth: CGFloat = 18) {
        self.grade = grade
        self.gpa = gpa
        self.diameter = diameter
        self.lineWidth = lineWidth
    }

    /// 0.0...1.0 fill fraction based on GPA / 4.3.
    private var fillFraction: Double {
        guard let gpa else { return grade == .incomplete ? 0 : 1 }
        return max(0, min(1, gpa / 4.3))
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fillFraction)
                .stroke(grade.colorFamily.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: fillFraction)

            VStack(spacing: 4) {
                Text(grade == .incomplete ? "—" : grade.rawValue)
                    .font(.system(size: diameter * 0.35, weight: .heavy, design: .rounded))
                    .foregroundStyle(grade.colorFamily.color)
                    .contentTransition(.numericText())
                if let gpa, grade != .incomplete {
                    Text(String(format: "%.2f GPA", gpa))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if grade == .incomplete { return "Grade incomplete" }
        if let gpa { return "Overall grade \(grade.rawValue), \(String(format: "%.2f", gpa)) GPA" }
        return "Overall grade \(grade.rawValue)"
    }
}

#Preview {
    VStack(spacing: 24) {
        GradeRingView(grade: .aMinus, gpa: 3.7)
        GradeRingView(grade: .bPlus, gpa: 3.3, diameter: 140, lineWidth: 12)
        GradeRingView(grade: .incomplete, diameter: 140, lineWidth: 12)
    }
    .padding()
    .preferredColorScheme(.dark)
}

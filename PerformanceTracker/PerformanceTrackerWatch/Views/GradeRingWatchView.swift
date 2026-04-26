import SwiftUI

struct GradeRingWatchView: View {
    @Environment(WatchSessionManager.self) private var session

    var body: some View {
        VStack(spacing: 8) {
            if let payload = session.latestPayload {
                ringForGrade(payload.overallGrade, gpa: payload.overallGPA)
                Text(payload.periodId).font(.caption2).foregroundStyle(.secondary)
            } else {
                ringForGrade(.incomplete, gpa: 0)
                Text("Tap to refresh").font(.caption2).foregroundStyle(.secondary)
            }
            Button("Refresh") { session.requestLatest() }
                .font(.caption2)
                .buttonStyle(.bordered)
        }
        .padding()
    }

    @ViewBuilder
    private func ringForGrade(_ grade: Grade, gpa: Double) -> some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0, min(1, gpa / 4.3)))
                .stroke(grade.colorFamily.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(grade == .incomplete ? "—" : grade.rawValue)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(grade.colorFamily.color)
        }
        .frame(width: 110, height: 110)
    }
}

import SwiftUI

struct HealthQuickView: View {
    @Environment(WatchSessionManager.self) private var session

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today").font(.headline)
            row(icon: "figure.walk", color: .blue,
                label: "Steps",
                value: session.latestPayload?.stepsToday.map(String.init) ?? "—")
            row(icon: "waveform.path.ecg", color: .purple,
                label: "HRV",
                value: session.latestPayload?.hrvLatest.map { String(format: "%.0f ms", $0) } ?? "—")
            row(icon: "heart.fill", color: .red,
                label: "RHR",
                value: session.latestPayload?.restingHRLatest.map { String(format: "%.0f bpm", $0) } ?? "—")
        }
        .padding()
    }

    @ViewBuilder
    private func row(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color)
            Text(label).font(.caption)
            Spacer()
            Text(value).font(.caption.weight(.bold))
        }
    }
}

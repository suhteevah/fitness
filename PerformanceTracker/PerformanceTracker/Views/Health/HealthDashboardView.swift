import SwiftUI
import SwiftData
import Charts

public struct HealthDashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var vm: HealthViewModel?
    @State private var showMealPrep = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let vm {
                        TrainingLoadCard(
                            weeklyTRIMP: vm.weeklyTRIMP,
                            acuteChronicRatio: vm.acuteChronicRatio,
                            recovery: vm.recovery
                        )
                        NextMealCard(
                            recommendation: vm.mealRecommendation,
                            onMadeThis: { rec in vm.logEatenMeal(rec) }
                        )
                        mealPrepButton
                    }
                    mealPlanCard
                    hrvCard
                    sleepCard
                    restingHRCard
                    stepsCard
                    exerciseCard
                    workoutLogCard
                }
                .padding()
            }
            .navigationTitle("Health")
            .background(Color.black.ignoresSafeArea())
            .refreshable { await vm?.load() }
        }
        .task {
            if vm == nil { vm = HealthViewModel(context: context) }
            await vm?.load()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // App came back to foreground — refresh meal rec so time-of-day updates
                Task { await vm?.load() }
            }
        }
        .sheet(isPresented: $showMealPrep) {
            MealPrepSheet()
        }
    }

    private var mealPrepButton: some View {
        Button {
            showMealPrep = true
        } label: {
            HStack {
                Image(systemName: "calendar.badge.plus").foregroundStyle(Brand.softIris)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meal Prep Day").font(.subheadline.weight(.semibold))
                    Text("Plan 3–5 days · auto shopping list").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: Cards

    private var mealPlanCard: some View {
        HStack {
            Image(systemName: "leaf.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading) {
                Text("Meal Plan Today").font(.subheadline.weight(.semibold))
                Text(vm?.mealPlanFollowedToday == true ? "Followed ✓" : "Not logged")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { vm?.mealPlanFollowedToday ?? false },
                set: { _ in vm?.toggleMealPlanToday() }
            ))
            .labelsHidden()
            .tint(Brand.seaGlassTeal)
        }
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    private var hrvCard: some View {
        metricCard(
            title: "HRV (SDNN)",
            value: vm?.snapshot?.hrv.map { String(format: "%.1f ms", $0) } ?? "—",
            baseline: HealthBaseline.p1Baseline.hrv,
            current: vm?.snapshot?.hrv,
            target: ">60 ms",
            tint: Brand.softIris,
            systemImage: "waveform.path.ecg"
        )
    }

    private var sleepCard: some View {
        metricCard(
            title: "Sleep / Night (avg)",
            value: vm?.snapshot?.sleepHoursPerNight.map { String(format: "%.1f h", $0) } ?? "—",
            baseline: HealthBaseline.p1Baseline.sleepHoursPerNight,
            current: vm?.snapshot?.sleepHoursPerNight,
            target: "7.5–9 h",
            tint: Brand.seaGlassTeal,
            systemImage: "bed.double.fill"
        )
    }

    private var restingHRCard: some View {
        metricCard(
            title: "Resting Heart Rate",
            value: vm?.snapshot?.restingHR.map { String(format: "%.0f bpm", $0) } ?? "—",
            baseline: HealthBaseline.p1Baseline.restingHR,
            current: vm?.snapshot?.restingHR,
            target: "<65 bpm",
            tint: .red,
            systemImage: "heart.fill",
            lowerIsBetter: true
        )
    }

    private var stepsCard: some View {
        metricCard(
            title: "Steps / Day",
            value: vm?.snapshot?.stepsPerDay.map { String(format: "%.0f", $0) } ?? "—",
            baseline: HealthBaseline.p1Baseline.stepsPerDay,
            current: vm?.snapshot?.stepsPerDay,
            target: "7,500+",
            tint: .blue,
            systemImage: "figure.walk"
        )
    }

    private var exerciseCard: some View {
        metricCard(
            title: "Exercise Minutes / Week",
            value: vm?.snapshot?.exerciseMinPerWeek.map { String(format: "%.0f min", $0) } ?? "—",
            baseline: HealthBaseline.p1Baseline.exerciseMinPerWeek,
            current: vm?.snapshot?.exerciseMinPerWeek,
            target: "150+",
            tint: .orange,
            systemImage: "figure.run"
        )
    }

    private var workoutLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill").foregroundStyle(.orange)
                Text("Log Workout").font(.subheadline.weight(.semibold))
                Spacer()
            }
            HStack {
                Button { vm?.logWorkout(type: "Walk", durationMin: 20) } label: {
                    Text("Walk 20m").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Button { vm?.logWorkout(type: "Strength", durationMin: 30) } label: {
                    Text("Lift 30m").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Button { vm?.logWorkout(type: "Zone 2", durationMin: 30) } label: {
                    Text("Z2 30m").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Helpers

    @ViewBuilder
    private func metricCard(
        title: String,
        value: String,
        baseline: Double,
        current: Double?,
        target: String,
        tint: Color,
        systemImage: String,
        lowerIsBetter: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage).foregroundStyle(tint)
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                if let current {
                    let delta = lowerIsBetter ? baseline - current : current - baseline
                    let pct = baseline == 0 ? 0 : (delta / baseline) * 100
                    Text(String(format: "%@%.0f%% vs P1", delta >= 0 ? "+" : "", pct))
                        .font(.caption2)
                        .foregroundStyle(delta >= 0 ? .green : .red)
                }
            }
            Text(value).font(.title2.weight(.heavy)).foregroundStyle(tint)
            Text("Target: \(target)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}

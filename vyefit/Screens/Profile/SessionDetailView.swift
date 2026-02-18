//
//  SessionDetailView.swift
//  vyefit
//
//  Detailed view for a completed workout session.
//

import SwiftUI
import Charts

struct SessionDetailView: View {
    let workoutSession: WorkoutSessionRecord

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    private var sessionName: String { workoutSession.name }
    private var sessionDate: Date { workoutSession.date }
    private var location: String { workoutSession.location }
    private var duration: TimeInterval { workoutSession.duration }
    private var calories: Int { workoutSession.calories }
    private var heartRateAvg: Int { workoutSession.heartRateAvg }
    private var heartRateMax: Int { workoutSession.heartRateMax }
    private var heartRateData: [HeartRateDataPoint] { workoutSession.heartRateData }
    private var wasPaused: Bool { workoutSession.wasPaused }
    private var totalElapsedTime: TimeInterval? { workoutSession.totalElapsedTime }
    private var workingTime: TimeInterval? { workoutSession.workingTime }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                if wasPaused, let total = totalElapsedTime, let working = workingTime {
                    pauseInfoSection(total: total, working: working)
                }

                mainStatsSection
                heartRateSection
                workoutSessionSection(session: workoutSession)
            }
            .padding(.vertical, 20)
        }
        .background(Theme.background)
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete")
                }
            }
        }
        .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSession()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the session from Vyefit and attempt to delete it from Apple Health.")
        }
    }

    private func deleteSession() {
        HistoryStore.shared.deleteWorkout(id: workoutSession.id)
        HealthKitManager.shared.deleteWorkout(uuid: workoutSession.id) { _ in }
        dismiss()
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sessionName)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Label(sessionDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)

                Label(sessionDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)

                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 14))
                Text("Workout")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(Theme.terracotta)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.terracotta.opacity(0.15))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    private func pauseInfoSection(total: TimeInterval, working: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pause.circle.fill")
                    .foregroundStyle(Theme.stone)
                Text("Session Paused")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Time")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Text(formatDuration(total))
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Working Time")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Text(formatDuration(working))
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.sage)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Paused")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Text(formatDuration(total - working))
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.stone)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private var mainStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(title: "Duration", value: formatDuration(duration), icon: "clock", color: Theme.terracotta)
            StatCard(title: "Calories", value: "\(calories)", unit: "kcal", icon: "flame.fill", color: Theme.terracotta)
            StatCard(title: "Avg HR", value: "\(heartRateAvg)", unit: "bpm", icon: "heart.fill", color: Theme.terracotta)
        }
        .padding(.horizontal, 20)
    }

    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if #available(iOS 16.0, *), !heartRateData.isEmpty {
                let minHRValue = heartRateData.map { $0.heartRate }.min() ?? 60
                let maxHRValue = heartRateData.map { $0.heartRate }.max() ?? 180
                let startTime = sessionDate
                let chartData = heartRateData.map { point in
                    (time: startTime.addingTimeInterval(point.timestamp), hr: point.heartRate)
                }

                GeometryReader { geometry in
                    Chart(chartData, id: \.time) { dataPoint in
                        RuleMark(
                            x: .value("Time", dataPoint.time),
                            yStart: .value("Min", max(minHRValue - 5, 0)),
                            yEnd: .value("HR", dataPoint.hr)
                        )
                        .foregroundStyle(Theme.terracotta)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisValueLabel(anchor: .top) {
                                if let date = value.as(Date.self) {
                                    Text(date, format: .dateTime.hour().minute())
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                    }
                    .chartYScale(domain: (max(minHRValue - 10, 0))...(maxHRValue + 10))
                    .frame(width: geometry.size.width, height: 140)
                }
                .frame(height: 140)

                HStack {
                    Text("Avg \(heartRateAvg) bpm")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.terracotta)
                    Spacer()
                    Text("Max \(heartRateMax) bpm")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.terracotta)
                }
            } else {
                Text("No heart rate data")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private func workoutSessionSection(session: WorkoutSessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Info")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 16) {
                SessionStatItem(title: "Exercises", value: "\(session.exerciseCount)")
                SessionStatItem(title: "Template", value: session.workoutTemplateName ?? "Unknown")
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var unit: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                if let unit {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SessionStatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(
            workoutSession: WorkoutSessionRecord(
                id: UUID(),
                date: Date(),
                name: "Upper Body",
                location: "Indoor",
                duration: 1800,
                calories: 250,
                exerciseCount: 6,
                heartRateAvg: 120,
                heartRateMax: 160,
                heartRateData: [],
                workoutTemplateName: "Upper Body",
                wasPaused: false,
                totalElapsedTime: 1800,
                workingTime: 1800
            )
        )
    }
}

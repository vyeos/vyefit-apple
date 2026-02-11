//
//  DashboardView.swift
//  vyefit
//
//  Today tab — greeting, daily focus, wellness stats, week strip, recent sessions.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Greeting
                        VStack(alignment: .leading, spacing: 6) {
                            Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                            Text("Hello, Rudra")
                                .font(.system(size: 28, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    .padding(.horizontal, 20)

                    // Daily intention
                    DailyFocusCard()

                    // Wellness cards
                    HStack(spacing: 14) {
                        WellnessCard(icon: "flame.fill", value: "4", label: "Workouts\nthis week", color: Theme.terracotta)
                        WellnessCard(icon: "heart.fill", value: "152", label: "Avg Heart\nRate", color: Theme.sage)
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 14) {
                        WellnessCard(icon: "figure.run", value: "25.8", label: "km Run\nthis month", color: Theme.stone)
                        WellnessCard(icon: "bolt.fill", value: "12", label: "Day\nStreak", color: Theme.terracotta)
                    }
                    .padding(.horizontal, 20)

                    // Week calendar
                    WeekStripView()

                    // Recent
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recent Sessions")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 20)

                        ForEach(SampleData.runSessions.prefix(2)) { run in
                            SessionRow(run: run)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    DashboardView()
}

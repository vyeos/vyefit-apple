//
//  DashboardView.swift
//  vyefit
//
//  Today tab — greeting, daily focus, wellness stats, week strip, recent sessions.
//

import SwiftUI

struct DashboardView: View {
    private var recentRuns: [MockRunSession] {
        HistoryStore.shared.mockRunSessions.sorted { $0.date > $1.date }.prefix(2).map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
									
									// Daily intention
                    DailyFocusCard()

                    // Wellness cards
                    HStack(spacing: 14) {
                        WellnessCard(icon: "flame.fill", value: "4", label: "Workouts\nthis week", color: Theme.terracotta)
												WellnessCard(icon: "figure.run", value: "25.8", label: "km Run\nthis month", color: Theme.stone)
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 14) {
												WellnessCard(icon: "heart.fill", value: "152", label: "Avg Heart\nRate", color: Theme.sage)
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

                        VStack(spacing: 8) {
                            ForEach(recentRuns) { run in
                                SessionRow(run: run)
                                    .padding(.horizontal, 20)
                            }
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

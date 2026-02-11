//
//  JournalView.swift
//  vyefit
//
//  Journal tab — weekly reflection and milestone tracking.
//

import SwiftUI

struct JournalView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly summary
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Weekly Reflection")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)

                        VStack(spacing: 10) {
                            JournalEntryRow(day: "Monday", activity: "Push Day - Bench Press, OHP", mood: "energized")
                            JournalEntryRow(day: "Tuesday", activity: "Rest Day", mood: "recovered")
                            JournalEntryRow(day: "Wednesday", activity: "Pull Day - Deadlift, Pull-ups", mood: "strong")
                            JournalEntryRow(day: "Thursday", activity: "5.2 km Run", mood: "focused")
                        }
                    }
                    .padding(20)
                    .background(Theme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)

                    // Achievements
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Milestones")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 20)

                        ForEach(SampleData.achievements.prefix(4)) { a in
                            MilestoneRow(achievement: a)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    JournalView()
}

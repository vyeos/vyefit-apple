//
//  AllSessionsView.swift
//  vyefit
//
//  List of all past workout sessions.
//

import SwiftUI

struct AllSessionsView: View {
    private var allWorkouts: [WorkoutSessionRecord] {
        HistoryStore.shared.workoutSessionRecords.sorted { $0.date > $1.date }
    }
    
    private var groupedSessions: [(String, [WorkoutSessionRecord])] {
        let sessions = allWorkouts
        let uniqueMonths: [Date] = Set(
            sessions.compactMap { item in
                Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: item.date))
            }
        ).sorted(by: >)
        
        return uniqueMonths.map { monthDate in
            let key = monthDate.formatted(.dateTime.month(.wide).year())
            let sessionsInMonth = sessions.filter {
                Calendar.current.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }
            return (key, sessionsInMonth)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVStack(spacing: 24) {
                    ForEach(groupedSessions, id: \.0) { month, sessions in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(month)
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                ForEach(sessions) { workout in
                                    WorkoutSessionRow(session: workout)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(Theme.background)
        .navigationTitle("All Sessions")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            HealthKitManager.shared.importLatestWorkoutsIfNeeded(force: true)
        }
    }
}

#Preview {
    NavigationStack {
        AllSessionsView()
    }
}

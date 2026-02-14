//
//  AllSessionsView.swift
//  vyefit
//
//  List of all past sessions (workouts and runs) with filters.
//

import SwiftUI

struct AllSessionsView: View {
    @State var filter: SessionFilter
    
    init(filter: SessionFilter = .all) {
        _filter = State(initialValue: filter)
    }
    
    private var allRuns: [MockRunSession] {
        HistoryStore.shared.mockRunSessions.sorted { $0.date > $1.date }
    }
    
    private var allWorkouts: [MockWorkoutSession] {
        HistoryStore.shared.mockWorkoutSessions.sorted { $0.date > $1.date }
    }
    
    private var filteredSessions: [(session: Any, type: SessionType, date: Date)] {
        var result: [(session: Any, type: SessionType, date: Date)] = []
        
        if filter == .all || filter == .run {
            for run in allRuns {
                result.append((run, .run, run.date))
            }
        }
        
        if filter == .all || filter == .workout {
            for workout in allWorkouts {
                result.append((workout, .workout, workout.date))
            }
        }
        
        return result.sorted { $0.date > $1.date }
    }
    
    private var groupedSessions: [(String, [(session: Any, type: SessionType, date: Date)])] {
        let sessions = filteredSessions
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
                Picker("Filter", selection: $filter) {
                    Text("All").tag(SessionFilter.all)
                    Text("Train").tag(SessionFilter.workout)
                    Text("Run").tag(SessionFilter.run)
                }
                .pickerStyle(.segmented)
                .tint(Theme.terracotta)
                .padding(.horizontal, 20)
                
                LazyVStack(spacing: 24) {
                    ForEach(groupedSessions, id: \.0) { month, sessions in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(month)
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(sessions.enumerated()), id: \.offset) { _, item in
                                    if item.type == .run, let run = item.session as? MockRunSession {
                                        SessionRow(run: run)
                                            .padding(.horizontal, 20)
                                    } else if item.type == .workout, let workout = item.session as? MockWorkoutSession {
                                        WorkoutSessionRow(session: workout)
                                            .padding(.horizontal, 20)
                                    }
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
    }
}

enum SessionFilter {
    case all
    case workout
    case run
}

#Preview {
    NavigationStack {
        AllSessionsView()
    }
}

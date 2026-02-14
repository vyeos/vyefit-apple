//
//  AllRunsView.swift
//  vyefit
//
//  List of all past run sessions, grouped by month.
//

import SwiftUI

struct AllRunsView: View {
    var runs: [MockRunSession] { HistoryStore.shared.mockRunSessions.sorted { $0.date > $1.date } }
    
    var groupedRuns: [(String, [MockRunSession])] {
        let uniqueMonths = Set(runs.map {
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: $0.date))!
        }).sorted(by: >)
        
        return uniqueMonths.map { monthDate in
            let key = monthDate.formatted(.dateTime.month(.wide).year())
            let runsInMonth = runs.filter {
                Calendar.current.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }
            return (key, runsInMonth)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(groupedRuns, id: \.0) { month, runs in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(month)
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            ForEach(runs) { run in
                                SessionRow(run: run)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(Theme.background)
        .navigationTitle("All Runs")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        AllRunsView()
    }
}

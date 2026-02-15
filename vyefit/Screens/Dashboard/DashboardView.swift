//
//  DashboardView.swift
//  vyefit
//
//  Today tab — greeting, daily focus, wellness stats, week strip, recent sessions.
//

import SwiftUI

struct DashboardView: View {
    @State private var scheduleStore = ScheduleStore()
    @State private var workoutStore = WorkoutStore()
    @AppStorage("distanceUnit") private var distanceUnit = "Kilometers"
    
    // MARK: - Computed Properties
    
    private var isMetric: Bool {
        distanceUnit == "Kilometers"
    }
    
    private var distanceUnitLabel: String {
        isMetric ? "km" : "mi"
    }
    
    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let workoutsThisWeek = HistoryStore.shared.workoutSessionRecords.filter { $0.date >= startOfWeek }
        return workoutsThisWeek.count
    }
    
    private var distanceThisMonth: Double {
        let calendar = Calendar.current
        let monthRuns = HistoryStore.shared.runSessionRecords.filter { 
            calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) 
        }
        let totalKm = monthRuns.reduce(0) { $0 + $1.distance }
        return isMetric ? totalKm : totalKm * 0.621371
    }
    
    private var dayStreak: Int {
        let allSessions = (HistoryStore.shared.workoutSessionRecords.map { $0.date } + 
                          HistoryStore.shared.runSessionRecords.map { $0.date })
            .sorted(by: >)
        
        guard !allSessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        // Check if there's a session today
        let hasSessionToday = allSessions.contains { calendar.isDate($0, inSameDayAs: checkDate) }
        if !hasSessionToday {
            // Check if there was one yesterday to continue streak
            let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            let hasSessionYesterday = allSessions.contains { calendar.isDate($0, inSameDayAs: yesterday) }
            if !hasSessionYesterday {
                return 0
            }
            checkDate = yesterday
        }
        
        // Count consecutive days with sessions
        while true {
            let hasSession = allSessions.contains { calendar.isDate($0, inSameDayAs: checkDate) }
            if hasSession {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var avgHeartRate: Int {
        let allSessions = HistoryStore.shared.workoutSessionRecords + 
                         HistoryStore.shared.runSessionRecords.map { 
                             WorkoutSessionRecord(
                                 id: $0.id,
                                 date: $0.date,
                                 name: $0.name,
                                 location: $0.location,
                                 duration: $0.duration,
                                 calories: $0.calories,
                                 exerciseCount: 0,
                                 heartRateAvg: $0.heartRateAvg,
                                 heartRateMax: $0.heartRateMax,
                                 heartRateData: $0.heartRateData,
                                 workoutTemplateName: nil,
                                 wasPaused: $0.wasPaused,
                                 totalElapsedTime: $0.totalElapsedTime,
                                 workingTime: $0.workingTime
                             )
                         }
        
        let sessionsWithHR = allSessions.filter { $0.heartRateAvg > 0 }
        guard !sessionsWithHR.isEmpty else { return 0 }
        
        let totalHR = sessionsWithHR.reduce(0) { $0 + $1.heartRateAvg }
        return totalHR / sessionsWithHR.count
    }
    
    private var thisWeekSessions: [(session: Any, type: SessionType, date: Date)] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        
        var result: [(session: Any, type: SessionType, date: Date)] = []
        
        let weekRuns = HistoryStore.shared.runSessionRecords.filter { $0.date >= startOfWeek }
        let weekWorkouts = HistoryStore.shared.workoutSessionRecords.filter { $0.date >= startOfWeek }
        
        for run in weekRuns {
            result.append((run, .run, run.date))
        }
        
        for workout in weekWorkouts {
            result.append((workout, .workout, workout.date))
        }
        
        return result.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Today Title
                    HStack {
                        Text("Today")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Daily Focus - Today's workout/rest from schedule
                    DailyFocusCard(
                        scheduleStore: scheduleStore
                    )

                    // Wellness cards
                    HStack(spacing: 14) {
                        WellnessCard(icon: "flame.fill", value: "\(workoutsThisWeek)", label: "Workouts\nthis week", color: Theme.terracotta)
                        WellnessCard(icon: "figure.run", value: String(format: "%.1f", distanceThisMonth), label: "\(distanceUnitLabel)\nthis month", color: Theme.stone)
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 14) {
                        WellnessCard(icon: "heart.fill", value: avgHeartRate > 0 ? "\(avgHeartRate)" : "--", label: "Avg Heart\nRate", color: Theme.sage)
                        WellnessCard(icon: "bolt.fill", value: "\(dayStreak)", label: "Day\nStreak", color: Theme.terracotta)
                    }
                    .padding(.horizontal, 20)

                    // This Week's Sessions
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("This Week's Sessions")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.textPrimary)
                            
                            Spacer()
                            
                            // Link to You page - All Sessions
                            NavigationLink {
                                ProfileView()
                            } label: {
                                HStack(spacing: 4) {
                                    Text("View All")
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                }
                                .foregroundStyle(Theme.terracotta)
                            }
                        }
                        .padding(.horizontal, 20)

                        if thisWeekSessions.isEmpty {
                            Text("No sessions this week")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(Array(thisWeekSessions.prefix(5).enumerated()), id: \.offset) { _, item in
                                    if item.type == .run, let run = item.session as? RunSessionRecord {
                                        SessionRow(run: run)
                                            .padding(.horizontal, 20)
                                    } else if item.type == .workout, let workout = item.session as? WorkoutSessionRecord {
                                        WorkoutSessionRowDashboard(session: workout)
                                            .padding(.horizontal, 20)
                                    }
                                }
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

// MARK: - Dashboard Workout Session Row

struct WorkoutSessionRowDashboard: View {
    let session: WorkoutSessionRecord
    
    var body: some View {
        NavigationLink(destination: SessionDetailView(workoutSession: session)) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.terracotta.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.terracotta)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.name)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text("\(session.exerciseCount) exercises")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        
                        Text("•")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.stone)
                        
                        Text(session.date, format: .dateTime.weekday(.abbreviated))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.terracotta)
                        Text("\(session.calories)")
                            .foregroundStyle(Theme.terracotta)
                    }
                    .font(.system(size: 12, weight: .medium))
                    
                    Text(formatDuration(session.duration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.stone)
                }
            }
            .padding(12)
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DashboardView()
}

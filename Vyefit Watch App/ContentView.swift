//
//  ContentView.swift
//  Vyefit Watch App
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var workoutManager = WatchWorkoutManager()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    @State private var isEndingSession = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.watchBackgroundTop, Theme.watchBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Group {
                switch connectivityManager.appState {
                case .loading:
                    LoadingView()
                case .noConnection:
                    NoConnectionView()
                case .activeSession(let sessionType):
                    ActiveSessionView(
                        workoutManager: workoutManager,
                        sessionType: sessionType
                    )
                case .chooseActivity(let schedule, let activities, let weeklySessions):
                    ActivityChooserView(
                        connectivityManager: connectivityManager,
                        workoutManager: workoutManager,
                        schedule: schedule,
                        activities: activities,
                        weeklySessions: weeklySessions
                    )
                }
            }
        }
        .onAppear {
            workoutManager.requestAuthorization()
            connectivityManager.checkForActiveSession()
            
            connectivityManager.onPauseCommand = { [weak workoutManager] in
                workoutManager?.pause()
            }
            connectivityManager.onResumeCommand = { [weak workoutManager] in
                workoutManager?.resume()
            }
            connectivityManager.onEndCommand = { [weak workoutManager] in
                workoutManager?.end()
            }
        }
        .onReceive(connectivityManager.$activeSessionInfo) { info in
            if let info = info, !workoutManager.isRunning, !isEndingSession {
                startLocalWorkout(type: info.type, location: info.location)
            }
        }
        .onReceive(connectivityManager.$receivedStartCommand) { command in
            if let cmd = command {
                connectivityManager.receivedStartCommand = nil
                if !workoutManager.isRunning {
                    startLocalWorkout(type: cmd.type, location: cmd.location)
                }
            }
        }
        .onChange(of: workoutManager.isRunning) { _, isRunning in
            if isRunning {
                isEndingSession = false
                let activity = workoutManager.currentActivityType == .running ? "run" : "workout"
                connectivityManager.appState = .activeSession(
                    activity == "run" ? .run(name: "Run") : .workout(name: "Workout")
                )
            } else {
                isEndingSession = true
                connectivityManager.activeSessionInfo = nil
                connectivityManager.appState = .loading
                connectivityManager.checkForActiveSession()
            }
        }
    }
    
    private func startLocalWorkout(type: String, location: String) {
        let activity: HKWorkoutActivityType = type == "run" ? .running : .traditionalStrengthTraining
        let locationType: HKWorkoutSessionLocationType = location == "outdoor" ? .outdoor : .indoor
        workoutManager.start(activity: activity, location: locationType)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Checking...")
                .font(.caption)
                .foregroundStyle(Theme.watchTextSecondary)
        }
    }
}

struct NoConnectionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 32))
                .foregroundStyle(Theme.watchTextTertiary)
            Text("iPhone Not Connected")
                .font(.headline)
                .foregroundStyle(Theme.watchTextPrimary)
            Text("Open Vyefit on your iPhone")
                .font(.caption)
                .foregroundStyle(Theme.watchTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ActiveSessionView: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    let sessionType: SessionType
    
    @State private var showingEndConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: sessionIcon)
                        .font(.caption)
                        .foregroundStyle(Theme.watchAccent)
                    Text(sessionName)
                        .font(.caption)
                        .foregroundStyle(Theme.watchTextSecondary)
                    Spacer()
                    if workoutManager.isRunning {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(workoutManager.isPaused ? Theme.watchWarning : Theme.watchSuccess)
                                .frame(width: 6, height: 6)
                            Text(workoutManager.isPaused ? "PAUSED" : "LIVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(workoutManager.isPaused ? Theme.watchWarning : Theme.watchSuccess)
                        }
                    }
                }
                
                VStack(spacing: 4) {
                    Text(formatElapsed(workoutManager.elapsedSeconds))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.watchTextPrimary)
                        .monospacedDigit()
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(Theme.watchCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    MetricTile(
                        title: "HEART RATE",
                        value: workoutManager.heartRate > 0 ? "\(Int(workoutManager.heartRate))" : "--",
                        unit: "BPM",
                        icon: "heart.fill"
                    )
                    
                    MetricTile(
                        title: "CALORIES",
                        value: workoutManager.activeEnergy > 0 ? "\(Int(workoutManager.activeEnergy))" : "--",
                        unit: "KCAL",
                        icon: "flame.fill"
                    )
                    
                    MetricTile(
                        title: "DISTANCE",
                        value: workoutManager.distanceMeters > 0 ? String(format: "%.2f", workoutManager.distanceMeters / 1000.0) : "--",
                        unit: "KM",
                        icon: "figure.walk"
                    )
                    
                    MetricTile(
                        title: "CADENCE",
                        value: workoutManager.cadenceSpm > 0 ? "\(Int(workoutManager.cadenceSpm))" : "--",
                        unit: "SPM",
                        icon: "shoeprints.fill"
                    )
                }
                
                HStack(spacing: 8) {
                    Button {
                        if workoutManager.isPaused {
                            workoutManager.resume()
                        } else {
                            workoutManager.pause()
                        }
                    } label: {
                        HStack {
                            Image(systemName: workoutManager.isPaused ? "play.fill" : "pause.fill")
                            Text(workoutManager.isPaused ? "Resume" : "Pause")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.watchTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(workoutManager.isPaused ? Theme.watchSuccess : Theme.watchAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        showingEndConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("End")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.watchTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.watchStop)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
        }
        .confirmationDialog("End Session?", isPresented: $showingEndConfirmation, titleVisibility: .visible) {
            Button("End Session", role: .destructive) {
                workoutManager.end()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to end this \(sessionTypeName)?")
        }
    }
    
    private var sessionTypeName: String {
        switch sessionType {
        case .run: return "run"
        case .workout: return "workout"
        }
    }
    
    private var sessionIcon: String {
        switch sessionType {
        case .workout:
            return "dumbbell.fill"
        case .run:
            return "figure.run"
        }
    }
    
    private var sessionName: String {
        switch sessionType {
        case .workout(let name), .run(let name):
            return name
        }
    }
    
    private func formatElapsed(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

struct ActivityChooserView: View {
    @ObservedObject var connectivityManager: WatchConnectivityManager
    @ObservedObject var workoutManager: WatchWorkoutManager
    let schedule: WatchScheduleData
    let activities: WatchActivityData
    let weeklySessions: WatchWeeklySessions
    
    @State private var showingConfirmation = false
    @State private var pendingItem: WatchScheduleItem?
    @State private var isRefreshing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Vyefit")
                        .font(.caption)
                        .foregroundStyle(Theme.watchTextSecondary)
                    Spacer()
                    HStack(spacing: 2) {
                        Circle()
                            .fill(Theme.watchSuccess)
                            .frame(width: 5, height: 5)
                        Text("Connected")
                            .font(.caption2)
                            .foregroundStyle(Theme.watchTextSecondary)
                    }
                }
                
                // Today's Focus
                TodayFocusCard(
                    schedule: schedule,
                    onStartActivity: { item in
                        pendingItem = item
                        showingConfirmation = true
                    }
                )
                
                // This Week's Sessions
                if !weeklySessions.sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("This Week")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.watchTextSecondary)
                            .textCase(.uppercase)
                        
                        ForEach(weeklySessions.sessions.prefix(5)) { session in
                            WeeklySessionRow(session: session)
                        }
                    }
                    .padding(8)
                    .background(Theme.watchCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(10)
        }
        .refreshable {
            isRefreshing = true
            connectivityManager.checkForActiveSession()
            try? await Task.sleep(nanoseconds: 500_000_000)
            isRefreshing = false
        }
        .confirmationDialog("Start \(pendingItem?.name ?? "Activity")?", isPresented: $showingConfirmation, titleVisibility: .visible) {
            Button("Start") {
                if let item = pendingItem {
                    startScheduleItem(item)
                }
                pendingItem = nil
            }
            Button("Cancel", role: .cancel) {
                pendingItem = nil
            }
        } message: {
            Text("This will begin your \(pendingItem?.type.lowercased() == "run" ? "run" : "workout") session.")
        }
    }
    
    private func startScheduleItem(_ item: WatchScheduleItem) {
        let isRun = item.type.lowercased() == "run"
        let location: String = isRun ? "outdoor" : "indoor"
        connectivityManager.startActivity(type: isRun ? "run" : "workout", location: location, workoutId: item.workoutId)
        startLocalWorkout(type: isRun ? "run" : "workout", location: location)
    }
    
    private func startLocalWorkout(type: String, location: String) {
        guard !workoutManager.isRunning else { return }
        let isRun = type.lowercased() == "run"
        let activity: HKWorkoutActivityType = isRun ? .running : .traditionalStrengthTraining
        let locationType: HKWorkoutSessionLocationType = location == "outdoor" ? .outdoor : .indoor
        workoutManager.start(activity: activity, location: locationType)
    }
}

struct TodayFocusCard: View {
    let schedule: WatchScheduleData
    let onStartActivity: (WatchScheduleItem) -> Void
    
    private var todayFocus: WatchScheduleItem? {
        schedule.todayItems.first { $0.type.lowercased() == "workout" || $0.type.lowercased() == "run" }
    }
    
    private var isRestDay: Bool {
        schedule.todayItems.isEmpty || schedule.todayItems.allSatisfy { $0.type.lowercased() == "rest" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Focus")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.watchTextTertiary)
                .textCase(.uppercase)
            
            if let item = todayFocus {
                let itemColor = item.type.lowercased() == "run" ? Theme.watchSuccess : Theme.watchAccent
                
                HStack(spacing: 10) {
                    Image(systemName: item.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(itemColor)
                        .frame(width: 32, height: 32)
                        .background(itemColor.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.watchTextPrimary)
                        
                        if item.isCompleted {
                            Text("Completed")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.watchSuccess)
                        } else {
                            Text("Tap to start")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.watchTextSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.watchSuccess)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.watchSuccess)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !item.isCompleted {
                        onStartActivity(item)
                    }
                }
            } else if isRestDay {
                HStack(spacing: 10) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.watchWarning)
                        .frame(width: 32, height: 32)
                        .background(Theme.watchWarning.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rest Day")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.watchTextPrimary)
                        Text("Take time to recover")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.watchTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "moon.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.watchWarning)
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.watchAccent)
                        .frame(width: 32, height: 32)
                        .background(Theme.watchAccent.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Free Day")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.watchTextPrimary)
                        Text("No schedule set")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.watchTextSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(Theme.watchCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WeeklySessionRow: View {
    let session: WatchSessionRecord
    
    private var sessionColor: Color {
        session.type == "run" ? Theme.watchSuccess : Theme.watchAccent
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: session.icon)
                .font(.system(size: 12))
                .foregroundStyle(sessionColor)
                .frame(width: 24, height: 24)
                .background(sessionColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(session.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.watchTextPrimary)
                    .lineLimit(1)
                
                Text(session.date, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.watchTextSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 1) {
                Text(formatDuration(session.duration))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.watchTextPrimary)
                
                if session.calories > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                        Text("\(session.calories)")
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.watchAccent)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct ScheduleItemRow: View {
    let item: WatchScheduleItem
    let onTap: () -> Void
    
    private var itemColor: Color {
        item.type.lowercased() == "run" ? Theme.watchSuccess : Theme.watchAccent
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(itemColor)
                    .frame(width: 28, height: 28)
                    .background(itemColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.watchTextPrimary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if item.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.watchSuccess)
                } else if item.type.lowercased() == "workout" || item.type.lowercased() == "run" {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.watchSuccess)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(item.isCompleted)
        .opacity(item.isCompleted ? 0.6 : 1.0)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.watchTextTertiary)
                Text(title)
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.watchTextTertiary)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.watchTextPrimary)
                Text(unit)
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.watchTextSecondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.watchCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  Vyefit Watch App
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var workoutManager = WatchWorkoutManager()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
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
                case .chooseActivity(let schedule, let activities):
                    ActivityChooserView(
                        connectivityManager: connectivityManager,
                        workoutManager: workoutManager,
                        schedule: schedule,
                        activities: activities
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
            if let info = info, !workoutManager.isRunning {
                startLocalWorkout(type: info.type, location: info.location)
            }
        }
        .onReceive(connectivityManager.$receivedStartCommand) { command in
            if let cmd = command {
                connectivityManager.receivedStartCommand = nil
                startLocalWorkout(type: cmd.type, location: cmd.location)
            }
        }
        .onChange(of: workoutManager.isRunning) { _, isRunning in
            if isRunning {
                let activity = workoutManager.currentActivityType == .running ? "run" : "workout"
                connectivityManager.appState = .activeSession(
                    activity == "run" ? .run(name: "Run") : .workout(name: "Workout")
                )
            } else {
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
    
    @State private var showingConfirmation = false
    @State private var pendingItem: WatchScheduleItem?
    @State private var isRefreshing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
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
                
                if schedule.todayItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.watchTextTertiary)
                        Text("No activities scheduled")
                            .font(.subheadline)
                            .foregroundStyle(Theme.watchTextSecondary)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(schedule.dayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.watchTextSecondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        
                        ForEach(schedule.todayItems) { item in
                            ScheduleItemRow(item: item) {
                                if !item.isCompleted {
                                    pendingItem = item
                                    showingConfirmation = true
                                }
                            }
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
            Text("This will begin your \(pendingItem?.type == "run" ? "run" : "workout") session.")
        }
    }
    
    private func startScheduleItem(_ item: WatchScheduleItem) {
        let location: String = item.type == "run" ? "outdoor" : "indoor"
        connectivityManager.startActivity(type: item.type, location: location, workoutId: item.workoutId)
        startLocalWorkout(type: item.type, location: location)
    }
    
    private func startLocalWorkout(type: String, location: String) {
        guard !workoutManager.isRunning else { return }
        let activity: HKWorkoutActivityType = type == "run" ? .running : .traditionalStrengthTraining
        let locationType: HKWorkoutSessionLocationType = location == "outdoor" ? .outdoor : .indoor
        workoutManager.start(activity: activity, location: locationType)
    }
}

struct ScheduleItemRow: View {
    let item: WatchScheduleItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(colorFromHex(item.colorHex))
                    .frame(width: 28, height: 28)
                    .background(colorFromHex(item.colorHex).opacity(0.2))
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
                } else if item.type == "workout" || item.type == "run" {
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
    
    private func colorFromHex(_ hex: String) -> Color {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
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

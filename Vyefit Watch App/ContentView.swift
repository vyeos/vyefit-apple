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
    }
    
    private func startLocalWorkout(type: String, location: String) {
        let activity: HKWorkoutActivityType = type == "run" ? .running : .traditionalStrengthTraining
        let locationType: HKWorkoutSessionLocationType = location == "outdoor" ? .outdoor : .indoor
        workoutManager.start(activity: activity, location: locationType)
    }
}

// MARK: - Loading View
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

// MARK: - No Connection View
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

// MARK: - Active Session View
struct ActiveSessionView: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    let sessionType: SessionType
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Header
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
                                .fill(Theme.watchSuccess)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.watchSuccess)
                        }
                    }
                }
                
                // Timer
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
                
                // Stats Grid
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
                
                // Control Button
                Button {
                    if workoutManager.isRunning {
                        workoutManager.end()
                    }
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("End Session")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.watchTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.watchStop)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(10)
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

// MARK: - Activity Chooser View
struct ActivityChooserView: View {
    @ObservedObject var connectivityManager: WatchConnectivityManager
    @ObservedObject var workoutManager: WatchWorkoutManager
    let schedule: WatchScheduleData
    let activities: WatchActivityData
    @State private var selectedActivity: String = "run"
    @State private var selectedLocation: String = "outdoor"
    @State private var showAllWorkouts = false
    
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
                
                if !schedule.todayItems.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(schedule.dayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.watchTextSecondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        
                        ForEach(schedule.todayItems.prefix(3)) { item in
                            ScheduleItemRow(item: item) {
                                startScheduleItem(item)
                            }
                        }
                    }
                    .padding(8)
                    .background(Theme.watchCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Quick Start")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.watchTextSecondary)
                            .textCase(.uppercase)
                        Spacer()
                    }
                    
                    Picker("Activity", selection: $selectedActivity) {
                        Text("Run").tag("run")
                        Text("Workout").tag("workout")
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .background(Theme.watchCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Picker("Location", selection: $selectedLocation) {
                        Text("Outdoor").tag("outdoor")
                        Text("Indoor").tag("indoor")
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .background(Theme.watchCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button {
                        startQuickActivity()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start \(selectedActivity == "run" ? "Run" : "Workout")")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.watchTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.watchSuccess)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(8)
                .background(Theme.watchCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if !activities.workouts.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Workouts")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.watchTextSecondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        
                        ForEach(activities.workouts.prefix(3)) { workout in
                            WorkoutRow(workout: workout) {
                                startWorkout(workout)
                            }
                        }
                        
                        if activities.workouts.count > 3 {
                            Button {
                                showAllWorkouts = true
                            } label: {
                                Text("View All (\(activities.workouts.count))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.watchAccent)
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
        .sheet(isPresented: $showAllWorkouts) {
            AllWorkoutsSheet(
                workouts: activities.workouts,
                onSelect: { workout in
                    showAllWorkouts = false
                    startWorkout(workout)
                }
            )
        }
    }
    
    private func startScheduleItem(_ item: WatchScheduleItem) {
        let location: String = item.type == "run" ? "outdoor" : "indoor"
        startLocalWorkout(type: item.type, location: location)
        connectivityManager.startActivity(type: item.type, location: location, workoutId: item.workoutId)
    }
    
    private func startQuickActivity() {
        startLocalWorkout(type: selectedActivity, location: selectedLocation)
        connectivityManager.startActivity(type: selectedActivity, location: selectedLocation)
    }
    
    private func startWorkout(_ workout: WatchWorkoutSummary) {
        startLocalWorkout(type: "workout", location: "indoor")
        connectivityManager.startActivity(type: "workout", location: "indoor", workoutId: workout.id)
    }
    
    private func startLocalWorkout(type: String, location: String) {
        guard !workoutManager.isRunning else { return }
        let activity: HKWorkoutActivityType = type == "run" ? .running : .traditionalStrengthTraining
        let locationType: HKWorkoutSessionLocationType = location == "outdoor" ? .outdoor : .indoor
        workoutManager.start(activity: activity, location: locationType)
    }
}

// MARK: - Schedule Item Row
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
                
                if item.type == "workout" || item.type == "run" {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.watchSuccess)
                }
            }
        }
        .buttonStyle(.plain)
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

// MARK: - Workout Row
struct WorkoutRow: View {
    let workout: WatchWorkoutSummary
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: workout.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.watchAccent)
                    .frame(width: 28, height: 28)
                    .background(Theme.watchAccent.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.watchTextPrimary)
                        .lineLimit(1)
                    Text("\(workout.exerciseCount) exercises")
                        .font(.caption2)
                        .foregroundStyle(Theme.watchTextTertiary)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.watchSuccess)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - All Workouts Sheet
struct AllWorkoutsSheet: View {
    let workouts: [WatchWorkoutSummary]
    let onSelect: (WatchWorkoutSummary) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(workouts) { workout in
                Button {
                    onSelect(workout)
                } label: {
                    HStack {
                        Image(systemName: workout.icon)
                            .foregroundStyle(Theme.watchAccent)
                        VStack(alignment: .leading) {
                            Text(workout.name)
                                .font(.system(size: 14, weight: .medium))
                            Text("\(workout.exerciseCount) exercises")
                                .font(.caption2)
                                .foregroundStyle(Theme.watchTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "play.fill")
                            .foregroundStyle(Theme.watchSuccess)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Choose Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Metric Tile
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

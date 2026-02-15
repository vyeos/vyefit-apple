//
//  ContentView.swift
//  VyefitWatch Watch App
//
//  Created by Rudra Patel on 15/02/26.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var workoutManager = WatchWorkoutManager()
    @StateObject private var wcManager = WatchConnectivityManager.shared
    @State private var selectedActivity: HKWorkoutActivityType = .running
    @State private var selectedLocation: HKWorkoutSessionLocationType = .outdoor
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.watchBackgroundTop, Theme.watchBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 10) {
                    HStack {
                        Text("Vyefit")
                            .font(.caption)
                            .foregroundStyle(Theme.watchTextSecondary)
                        Spacer()
                        Text(wcManager.isReachable ? "Connected" : "No iPhone")
                            .font(.caption2)
                            .foregroundStyle(wcManager.isReachable ? Theme.watchSuccess : Theme.watchAccent)
                    }
                    
                    VStack(spacing: 4) {
                        Text(formatElapsed(workoutManager.elapsedSeconds))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.watchTextPrimary)
                        Text(workoutManager.isRunning ? "LIVE" : "READY")
                            .font(.caption2)
                            .foregroundStyle(workoutManager.isRunning ? Theme.watchSuccess : Theme.watchTextSecondary)
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Theme.watchCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    HStack(spacing: 6) {
                        MetricTile(title: "HR", value: workoutManager.heartRate > 0 ? "\(Int(workoutManager.heartRate))" : "--", unit: "bpm")
                        MetricTile(title: "CAL", value: workoutManager.activeEnergy > 0 ? "\(Int(workoutManager.activeEnergy))" : "--", unit: "kcal")
                    }
                    
                    HStack(spacing: 6) {
                        MetricTile(title: "DIST", value: workoutManager.distanceMeters > 0 ? String(format: "%.2f", workoutManager.distanceMeters / 1000.0) : "--", unit: "km")
                        MetricTile(title: "CAD", value: workoutManager.cadenceSpm > 0 ? "\(Int(workoutManager.cadenceSpm))" : "--", unit: "spm")
                    }
                    
                    HStack(spacing: 6) {
                        Picker("Activity", selection: $selectedActivity) {
                            Text("Run").tag(HKWorkoutActivityType.running)
                            Text("Workout").tag(HKWorkoutActivityType.traditionalStrengthTraining)
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(Theme.watchCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Picker("Location", selection: $selectedLocation) {
                            Text("Outdoor").tag(HKWorkoutSessionLocationType.outdoor)
                            Text("Indoor").tag(HKWorkoutSessionLocationType.indoor)
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(Theme.watchCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .font(.caption2)
                    
                    Button(workoutManager.isRunning ? "End Workout" : "Start Workout") {
                        if workoutManager.isRunning {
                            workoutManager.end()
                        } else {
                            workoutManager.start(activity: selectedActivity, location: selectedLocation)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(workoutManager.isRunning ? Theme.watchStop : Theme.watchSuccess)
                }
                .padding(12)
            }
            .focusable(true)
        }
        .onAppear {
            workoutManager.requestAuthorization()
            wcManager.onStartCommand = { activity, location in
                let act: HKWorkoutActivityType = activity == "run" ? .running : .traditionalStrengthTraining
                let loc: HKWorkoutSessionLocationType = location == "outdoor" ? .outdoor : .indoor
                workoutManager.start(activity: act, location: loc)
            }
            wcManager.onEndCommand = {
                workoutManager.end()
            }
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

#Preview {
    ContentView()
}

private struct MetricTile: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.watchTextTertiary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.watchTextPrimary)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Theme.watchTextSecondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.watchCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

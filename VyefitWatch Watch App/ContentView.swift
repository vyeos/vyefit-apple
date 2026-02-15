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
        VStack {
            Text("Vyefit")
                .font(.headline)
            
            Picker("Activity", selection: $selectedActivity) {
                Text("Run").tag(HKWorkoutActivityType.running)
                Text("Workout").tag(HKWorkoutActivityType.traditionalStrengthTraining)
            }
            .labelsHidden()
            
            Picker("Location", selection: $selectedLocation) {
                Text("Outdoor").tag(HKWorkoutSessionLocationType.outdoor)
                Text("Indoor").tag(HKWorkoutSessionLocationType.indoor)
            }
            .labelsHidden()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("HR: \(Int(workoutManager.heartRate))")
                Text("Dist: \(String(format: "%.2f", workoutManager.distanceMeters / 1000.0)) km")
                Text("Cals: \(Int(workoutManager.activeEnergy))")
                Text("Cadence: \(Int(workoutManager.cadenceSpm)) spm")
            }
            .font(.caption2)
            
            Spacer()
            
            Button(workoutManager.isRunning ? "End" : "Start") {
                if workoutManager.isRunning {
                    workoutManager.end()
                } else {
                    workoutManager.start(activity: selectedActivity, location: selectedLocation)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
}

#Preview {
    ContentView()
}

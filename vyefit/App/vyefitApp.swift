//
//  vyefitApp.swift
//  vyefit
//

import SwiftUI
import CoreData

@main
struct vyefitApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .background(Theme.background.ignoresSafeArea())
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Setup WatchConnectivity callback for starting workouts from watch
        WatchConnectivityManager.shared.onStartFromWatch = { [weak self] activity, location, workoutId in
            self?.handleStartFromWatch(activity: activity, location: location, workoutId: workoutId)
        }
        
        // Ensure WatchConnectivity is activated
        WatchConnectivityManager.shared.activate { success in
            print("[AppDelegate] WatchConnectivity activation: \(success ? "success" : "failed")")
        }
        
        return true
    }
    
    private func handleStartFromWatch(activity: String, location: String, workoutId: String?) {
        DispatchQueue.main.async {
            if activity == "run" {
                RunStore.shared.isStartingFromWatch = true
                let config = RunConfiguration(type: .quickStart)
                RunStore.shared.startSession(configuration: config)
            } else {
                WorkoutStore.shared.isStartingFromWatch = true
                if let workoutIdString = workoutId,
                   let uuid = UUID(uuidString: workoutIdString),
                   let workout = WorkoutStore.shared.workouts.first(where: { $0.id == uuid }) {
                    WorkoutStore.shared.startSession(for: workout)
                } else if let firstWorkout = WorkoutStore.shared.workouts.first {
                    WorkoutStore.shared.startSession(for: firstWorkout)
                } else {
                    // No workouts available - create a default one
                    let defaultWorkout = UserWorkout(
                        id: UUID(),
                        name: "Quick Workout",
												workoutType: .traditionalStrengthTraining,
                        exercises: [],
                        icon: "dumbbell.fill",
                        createdAt: Date()
                    )
                    WorkoutStore.shared.add(defaultWorkout)
                    WorkoutStore.shared.startSession(for: defaultWorkout)
                }
            }
        }
    }
}

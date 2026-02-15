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
        WatchConnectivityManager.shared.onStartFromWatch = { [weak self] activity, location, workoutId in
            self?.handleStartFromWatch(activity: activity, location: location, workoutId: workoutId)
        }
        return true
    }
    
    private func handleStartFromWatch(activity: String, location: String, workoutId: String?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if activity == "run" {
                let config = RunConfiguration(type: .quickStart)
                RunStore.shared.startSession(configuration: config)
            } else {
                if let workoutIdString = workoutId,
                   let uuid = UUID(uuidString: workoutIdString),
                   let workout = WorkoutStore.shared.workouts.first(where: { $0.id == uuid }) {
                    WorkoutStore.shared.startSession(for: workout)
                } else if let firstWorkout = WorkoutStore.shared.workouts.first {
                    WorkoutStore.shared.startSession(for: firstWorkout)
                }
            }
        }
    }
}

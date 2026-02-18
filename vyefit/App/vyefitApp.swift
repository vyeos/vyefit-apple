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
        // Ignore start commands from watch: Vyefit handles planning/logging only.
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
        print("[AppDelegate] Ignoring start-from-watch command (\(activity), \(location), \(workoutId ?? "nil"))")
    }
}

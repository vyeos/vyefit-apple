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
        removeOversizedLegacyDefaults()
        return true
    }

    private func removeOversizedLegacyDefaults() {
        let candidateKeys = [
            "completedWorkouts",
            "completedRuns",
            "exerciseRecords.v1",
            "userWorkouts",
            "customExercises",
            "scheduleSettings"
        ]
        for key in candidateKeys {
            guard let data = UserDefaults.standard.data(forKey: key) else { continue }
            if data.count >= 3_500_000 {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

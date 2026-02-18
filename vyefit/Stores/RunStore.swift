//
//  RunStore.swift
//  vyefit
//
//  Observable store for active run sessions.
//

import SwiftUI

@Observable
class RunStore {
    static let shared = RunStore()
    
    var activeSession: RunSession?
    var showActiveRun: Bool = false
    func startSession(configuration: RunConfiguration) {
        print("[RunStore] Live run tracking is disabled. Use Apple Workout for run recording.")
    }
    
    func endActiveSession() {
        if let session = activeSession {
            if let workout = session.consumeFinishedWorkout() {
                HealthKitManager.shared.importWorkoutSample(workout) { _ in }
            } else if !session.isHealthBacked {
                HistoryStore.shared.saveRun(
                    type: session.configuration.type.rawValue,
                    distance: session.currentDistance,
                    duration: TimeInterval(session.elapsedSeconds),
                    calories: session.activeCalories,
                    avgHeartRate: session.currentHeartRate
                )
            }
        }
        if let session = activeSession, session.state != .completed {
            session.endRun()
        }
        HealthKitManager.shared.importLatestWorkoutsIfNeeded(force: true)
        activeSession = nil
        showActiveRun = false
        
        WatchConnectivityManager.shared.endWorkout()
        WatchConnectivityManager.shared.updateApplicationContext()
    }
    
    func discardActiveSession() {
        activeSession?.endRun()
        activeSession = nil
        showActiveRun = false
    }
    
    func minimizeSession() {
        showActiveRun = false
    }
}

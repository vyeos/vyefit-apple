//
//  RunStore.swift
//  vyefit
//
//  Observable store for active run sessions.
//

import SwiftUI
import HealthKit

@Observable
class RunStore {
    var activeSession: RunSession?
    var showActiveRun: Bool = false
    
    func startSession(configuration: RunConfiguration) {
        let stored = UserDefaults.standard.object(forKey: "healthWriteWorkouts")
        let writeEnabled = stored == nil ? false : UserDefaults.standard.bool(forKey: "healthWriteWorkouts")
        let controller: HealthKitWorkoutController? = writeEnabled && HealthKitManager.shared.isAuthorized
            ? HealthKitManager.shared.startWorkoutController(activityType: .running, location: .outdoor)
            : nil
        activeSession = RunSession(configuration: configuration, healthController: controller)
        showActiveRun = true
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
        activeSession = nil
        showActiveRun = false
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

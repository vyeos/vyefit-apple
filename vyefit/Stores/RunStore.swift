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
    static let shared = RunStore()
    
    var activeSession: RunSession?
    var showActiveRun: Bool = false
    
    func startSession(configuration: RunConfiguration) {
        let writeStored = UserDefaults.standard.object(forKey: "healthWriteWorkouts")
        let writeEnabled = writeStored == nil ? false : UserDefaults.standard.bool(forKey: "healthWriteWorkouts")
        let readStored = UserDefaults.standard.object(forKey: "healthReadWorkouts")
        let readEnabled = readStored == nil ? true : UserDefaults.standard.bool(forKey: "healthReadWorkouts")
        let vitalsStored = UserDefaults.standard.object(forKey: "healthReadVitals")
        let vitalsEnabled = vitalsStored == nil ? true : UserDefaults.standard.bool(forKey: "healthReadVitals")
        let shouldUseHealth = HealthKitManager.shared.isAuthorized && (writeEnabled || readEnabled || vitalsEnabled)
        if WatchConnectivityManager.shared.isReachable {
            WatchConnectivityManager.shared.startWorkout(activity: "run", location: "outdoor")
        }
        WatchConnectivityManager.shared.updateApplicationContext()
        let controller: HealthKitWorkoutController? = shouldUseHealth && !WatchConnectivityManager.shared.isReachable
            ? HealthKitManager.shared.startWorkoutController(activityType: .running, location: .outdoor)
            : nil
        activeSession = RunSession(configuration: configuration, healthController: controller)
        showActiveRun = true
    }
    
    func endActiveSession() {
        if let session = activeSession {
            WatchConnectivityManager.shared.endWorkout()
            WatchConnectivityManager.shared.updateApplicationContext()
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

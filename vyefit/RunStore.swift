//
//  RunStore.swift
//  vyefit
//
//  Observable store for active run sessions.
//

import SwiftUI

@Observable
class RunStore {
    var activeSession: RunSession?
    var showActiveRun: Bool = false
    
    func startSession(configuration: RunConfiguration) {
        activeSession = RunSession(configuration: configuration)
        showActiveRun = true
    }
    
    func endActiveSession() {
        if let session = activeSession {
            HistoryStore.shared.saveRun(
                type: session.configuration.type.rawValue,
                distance: session.currentDistance,
                duration: TimeInterval(session.elapsedSeconds),
                calories: session.activeCalories,
                avgHeartRate: session.currentHeartRate
            )
        }
        activeSession?.endRun()
        activeSession = nil
        showActiveRun = false
    }
    
    func minimizeSession() {
        showActiveRun = false
    }
}

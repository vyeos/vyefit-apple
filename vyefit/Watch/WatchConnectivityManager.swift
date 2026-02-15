//
//  WatchConnectivityManager.swift
//  vyefit
//
//  Handles messaging with the Apple Watch app.
//

import Foundation
import WatchConnectivity
import Combine

struct WatchMetrics {
    let activity: String
    let heartRate: Double
    let distanceMeters: Double
    let activeEnergyKcal: Double
    let cadenceSpm: Double
    let elapsedSeconds: Int
}

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published private(set) var isReachable: Bool = false
    @Published private(set) var latestMetrics: WatchMetrics?
    
    var onMetrics: ((WatchMetrics) -> Void)?
    var onWorkoutEnded: ((UUID?) -> Void)?
    
    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    func startWorkout(activity: String, location: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["command": "start", "activity": activity, "location": location],
            replyHandler: nil,
            errorHandler: nil
        )
    }
    
    func endWorkout() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["command": "end"],
            replyHandler: nil,
            errorHandler: nil
        )
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let event = message["event"] as? String, event == "ended" {
            let uuid = (message["uuid"] as? String).flatMap { UUID(uuidString: $0) }
            DispatchQueue.main.async {
                self.onWorkoutEnded?(uuid)
            }
            return
        }
        
        guard let activity = message["activity"] as? String else { return }
        let metrics = WatchMetrics(
            activity: activity,
            heartRate: message["heartRate"] as? Double ?? 0,
            distanceMeters: message["distanceMeters"] as? Double ?? 0,
            activeEnergyKcal: message["activeEnergyKcal"] as? Double ?? 0,
            cadenceSpm: message["cadenceSpm"] as? Double ?? 0,
            elapsedSeconds: message["elapsedSeconds"] as? Int ?? 0
        )
        DispatchQueue.main.async {
            self.latestMetrics = metrics
            self.onMetrics?(metrics)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}

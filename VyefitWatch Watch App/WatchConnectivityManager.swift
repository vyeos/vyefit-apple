//
//  WatchConnectivityManager.swift
//  VyefitWatch Watch App
//

import Foundation
import Combine
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    var onStartCommand: ((String, String) -> Void)?
    var onEndCommand: (() -> Void)?
    
    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    func sendMetrics(activity: String, heartRate: Double, distanceMeters: Double, activeEnergyKcal: Double, cadenceSpm: Double, elapsedSeconds: Int) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            [
                "activity": activity,
                "heartRate": heartRate,
                "distanceMeters": distanceMeters,
                "activeEnergyKcal": activeEnergyKcal,
                "cadenceSpm": cadenceSpm,
                "elapsedSeconds": elapsedSeconds
            ],
            replyHandler: nil,
            errorHandler: nil
        )
    }
    
    func sendEnded(uuid: UUID?) {
        guard WCSession.default.isReachable else { return }
        var message: [String: Any] = ["event": "ended"]
        if let uuid {
            message["uuid"] = uuid.uuidString
        }
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let command = message["command"] as? String, command == "start" {
            let activity = message["activity"] as? String ?? "workout"
            let location = message["location"] as? String ?? "indoor"
            DispatchQueue.main.async {
                self.onStartCommand?(activity, location)
            }
        } else if let command = message["command"] as? String, command == "end" {
            DispatchQueue.main.async {
                self.onEndCommand?()
            }
        }
    }
}

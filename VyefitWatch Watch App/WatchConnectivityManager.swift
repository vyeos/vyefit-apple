//
//  WatchConnectivityManager.swift
//  VyefitWatch Watch App
//

import Foundation
import Combine
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published private(set) var isReachable: Bool = false
    @Published private(set) var activationState: WCSessionActivationState = .notActivated
    
    private var pendingMessages: [[String: Any]] = []
    
    var onStartCommand: ((String, String) -> Void)?
    var onEndCommand: (() -> Void)?
    
    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        activationState = session.activationState
        isReachable = session.isReachable
    }
    
    func sendMetrics(activity: String, heartRate: Double, distanceMeters: Double, activeEnergyKcal: Double, cadenceSpm: Double, elapsedSeconds: Int) {
        let session = WCSession.default
        if session.activationState != .activated {
            session.activate()
            pendingMessages.append([
                "activity": activity,
                "heartRate": heartRate,
                "distanceMeters": distanceMeters,
                "activeEnergyKcal": activeEnergyKcal,
                "cadenceSpm": cadenceSpm,
                "elapsedSeconds": elapsedSeconds
            ])
            return
        }
        guard session.isReachable else {
            pendingMessages.append([
                "activity": activity,
                "heartRate": heartRate,
                "distanceMeters": distanceMeters,
                "activeEnergyKcal": activeEnergyKcal,
                "cadenceSpm": cadenceSpm,
                "elapsedSeconds": elapsedSeconds
            ])
            return
        }
        session.sendMessage(
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
        let session = WCSession.default
        if session.activationState != .activated {
            session.activate()
            var message: [String: Any] = ["event": "ended"]
            if let uuid { message["uuid"] = uuid.uuidString }
            pendingMessages.append(message)
            return
        }
        guard session.isReachable else {
            var message: [String: Any] = ["event": "ended"]
            if let uuid { message["uuid"] = uuid.uuidString }
            pendingMessages.append(message)
            return
        }
        var message: [String: Any] = ["event": "ended"]
        if let uuid {
            message["uuid"] = uuid.uuidString
        }
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
    
    private func flushPendingIfPossible() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        guard !pendingMessages.isEmpty else { return }
        let toSend = pendingMessages
        pendingMessages.removeAll()
        for message in toSend {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.activationState = activationState
            self.isReachable = session.isReachable
            self.flushPendingIfPossible()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.flushPendingIfPossible()
        }
    }
    
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

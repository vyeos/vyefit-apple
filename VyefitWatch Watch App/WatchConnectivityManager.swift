//
//  WatchConnectivityManager.swift
//  VyefitWatch Watch App
//

import Foundation
import Combine
import WatchConnectivity

struct WatchScheduleData: Codable, Equatable {
    let todayItems: [WatchScheduleItem]
    let dayName: String
}

struct WatchScheduleItem: Codable, Identifiable, Equatable {
    let id: String
    let type: String
    let name: String
    let icon: String
    let colorHex: String
    let workoutId: String?
    let runType: String?
}

struct WatchActivityData: Codable, Equatable {
    let workouts: [WatchWorkoutSummary]
    let hasActiveSession: Bool
    let activeSessionType: String?
    let activeSessionName: String?
    let activeSessionWorkoutId: String?
    let activeSessionLocation: String?
}

struct WatchWorkoutSummary: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let exerciseCount: Int
}

enum WatchAppState: Equatable {
    case loading
    case noConnection
    case activeSession(SessionType)
    case chooseActivity(WatchScheduleData, WatchActivityData)
}

enum SessionType: Equatable {
    case workout(name: String)
    case run(name: String)
}

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published private(set) var isReachable: Bool = false
    @Published private(set) var activationState: WCSessionActivationState = .notActivated
    @Published private(set) var appState: WatchAppState = .loading
    @Published private(set) var scheduleData: WatchScheduleData?
    @Published private(set) var activityData: WatchActivityData?
    @Published var activeSessionInfo: (type: String, location: String)?
    @Published var receivedStartCommand: (type: String, location: String)?
    
    private var pendingMessages: [[String: Any]] = []
    
    var onStartCommand: ((String, String) -> Void)?
    var onEndCommand: (() -> Void)?
    
    private override init() {
        super.init()
        guard WCSession.isSupported() else {
            appState = .noConnection
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        activationState = session.activationState
        isReachable = session.isReachable
    }
    
    func checkForActiveSession() {
        guard isReachable else {
            appState = .noConnection
            return
        }
        
        let session = WCSession.default
        session.sendMessage(["request": "activities"], replyHandler: { [weak self] response in
            guard let self = self else { return }
            
            if let data = try? JSONSerialization.data(withJSONObject: response),
               let activities = try? JSONDecoder().decode(WatchActivityData.self, from: data) {
                DispatchQueue.main.async {
                    self.activityData = activities
                    
                    if activities.hasActiveSession,
                       let type = activities.activeSessionType,
                       let name = activities.activeSessionName {
                        if type == "workout" {
                            self.appState = .activeSession(.workout(name: name))
                        } else {
                            self.appState = .activeSession(.run(name: name))
                        }
                        if let location = activities.activeSessionLocation {
                            self.activeSessionInfo = (type: type, location: location)
                        }
                    } else {
                        self.fetchSchedule()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.appState = .noConnection
                }
            }
        }, errorHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.appState = .noConnection
            }
        })
    }
    
    func fetchSchedule() {
        guard isReachable else {
            appState = .noConnection
            return
        }
        
        let session = WCSession.default
        session.sendMessage(["request": "schedule"], replyHandler: { [weak self] response in
            guard let self = self else { return }
            
            if let data = try? JSONSerialization.data(withJSONObject: response),
               let schedule = try? JSONDecoder().decode(WatchScheduleData.self, from: data) {
                DispatchQueue.main.async {
                    self.scheduleData = schedule
                    if let activities = self.activityData {
                        self.appState = .chooseActivity(schedule, activities)
                    } else {
                        // Fetch activities if not already loaded
                        self.checkForActiveSession()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.appState = .noConnection
                }
            }
        }, errorHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.appState = .noConnection
            }
        })
    }
    
    func startActivity(type: String, location: String, workoutId: String? = nil) {
        guard isReachable else { return }
        
        var message: [String: Any] = [
            "request": "startActivity",
            "activity": type,
            "location": location
        ]
        
        if let workoutId = workoutId {
            message["workoutId"] = workoutId
        }
        
        let session = WCSession.default
        session.sendMessage(message, replyHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.checkForActiveSession()
            }
        }, errorHandler: nil)
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
            if activationState == .activated && self.appState == .loading {
                self.checkForActiveSession()
            }
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
                self.receivedStartCommand = (type: activity, location: location)
                self.onStartCommand?(activity, location)
            }
        } else if let command = message["command"] as? String, command == "end" {
            DispatchQueue.main.async {
                self.onEndCommand?()
            }
        }
    }
}

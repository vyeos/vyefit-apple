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
            print("[WatchConnectivity] WCSession not supported")
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        activationState = session.activationState
        isReachable = session.isReachable
        print("[WatchConnectivity] Initializing - state: \(activationState.rawValue), reachable: \(isReachable)")
    }
    
    func checkForActiveSession() {
        let session = WCSession.default
        
        // Check if session is activated first
        guard session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated yet, delaying check")
            // Wait and retry after activation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if WCSession.default.activationState == .activated {
                    self?.checkForActiveSession()
                } else {
                    self?.appState = .noConnection
                }
            }
            return
        }
        
        guard session.isReachable else {
            print("[WatchConnectivity] iPhone not reachable")
            appState = .noConnection
            return
        }
        
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
        }, errorHandler: { [weak self] error in
            print("[WatchConnectivity] Error checking active session: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self?.appState = .noConnection
            }
        })
    }
    
    func fetchSchedule() {
        let session = WCSession.default
        
        guard session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated, cannot fetch schedule")
            appState = .noConnection
            return
        }
        
        guard session.isReachable else {
            print("[WatchConnectivity] iPhone not reachable, cannot fetch schedule")
            appState = .noConnection
            return
        }
        
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
        }, errorHandler: { [weak self] error in
            print("[WatchConnectivity] Error fetching schedule: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self?.appState = .noConnection
            }
        })
    }
    
    func startActivity(type: String, location: String, workoutId: String? = nil) {
        let session = WCSession.default
        
        guard session.activationState == .activated, session.isReachable else {
            print("[WatchConnectivity] Cannot start activity - session not ready")
            return
        }
        
        var message: [String: Any] = [
            "request": "startActivity",
            "activity": type,
            "location": location
        ]
        
        if let workoutId = workoutId {
            message["workoutId"] = workoutId
        }
        
        session.sendMessage(message, replyHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.checkForActiveSession()
            }
        }, errorHandler: { error in
            print("[WatchConnectivity] Start activity error: \(error.localizedDescription)")
        })
    }
    
    func sendMetrics(activity: String, heartRate: Double, distanceMeters: Double, activeEnergyKcal: Double, cadenceSpm: Double, elapsedSeconds: Int) {
        let session = WCSession.default
        let message: [String: Any] = [
            "activity": activity,
            "heartRate": heartRate,
            "distanceMeters": distanceMeters,
            "activeEnergyKcal": activeEnergyKcal,
            "cadenceSpm": cadenceSpm,
            "elapsedSeconds": elapsedSeconds
        ]
        
        if session.activationState != .activated {
            print("[WatchConnectivity] Session not activated, queueing metrics")
            pendingMessages.append(message)
            session.activate()
            return
        }
        
        guard session.isReachable else {
            print("[WatchConnectivity] iPhone not reachable, queueing metrics")
            pendingMessages.append(message)
            return
        }
        
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("[WatchConnectivity] Send metrics error: \(error.localizedDescription)")
        })
    }
    
    func sendEnded(uuid: UUID?) {
        let session = WCSession.default
        var message: [String: Any] = ["event": "ended"]
        if let uuid {
            message["uuid"] = uuid.uuidString
        }
        
        if session.activationState != .activated {
            print("[WatchConnectivity] Session not activated, queueing ended event")
            pendingMessages.append(message)
            session.activate()
            return
        }
        
        guard session.isReachable else {
            print("[WatchConnectivity] iPhone not reachable, queueing ended event")
            pendingMessages.append(message)
            return
        }
        
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("[WatchConnectivity] Send ended error: \(error.localizedDescription)")
        })
    }
    
    private func flushPendingIfPossible() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        guard !pendingMessages.isEmpty else { return }
        
        let toSend = pendingMessages
        pendingMessages.removeAll()
        print("[WatchConnectivity] Flushing \(toSend.count) pending messages")
        
        for message in toSend {
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("[WatchConnectivity] Error flushing message: \(error.localizedDescription)")
                // Re-queue failed messages
                DispatchQueue.main.async { [weak self] in
                    self?.pendingMessages.append(message)
                }
            })
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.activationState = activationState
            self.isReachable = session.isReachable
            
            if let error = error {
                print("[WatchConnectivity] Activation error: \(error.localizedDescription)")
            } else {
                print("[WatchConnectivity] Activated - state: \(activationState.rawValue), reachable: \(session.isReachable)")
            }
            
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

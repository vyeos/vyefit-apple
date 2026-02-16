//
//  WatchConnectivityManager.swift
//  Vyefit Watch App
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
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var appState: WatchAppState = .loading
    @Published private(set) var scheduleData: WatchScheduleData?
    @Published private(set) var activityData: WatchActivityData?
    @Published var activeSessionInfo: (type: String, location: String)?
    @Published var receivedStartCommand: (type: String, location: String)?
    
    private var pendingMessages: [[String: Any]] = []
    private var retryTimer: Timer?
    
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
        isConnected = session.activationState == .activated
        print("[WatchConnectivity] Initializing - state: \(activationState.rawValue), reachable: \(isReachable), connected: \(isConnected)")
    }
    
    func checkForActiveSession() {
        let session = WCSession.default
        
        guard session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated yet, scheduling retry")
            scheduleRetry()
            return
        }
        
        // Try immediate message if reachable, otherwise use context
        if session.isReachable {
            requestActivitiesViaMessage()
        } else {
            // Check for last known context
            checkApplicationContext()
        }
    }
    
    private func scheduleRetry() {
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.checkForActiveSession()
        }
    }
    
    private func requestActivitiesViaMessage() {
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
                    // If message fails to decode, still try to show activity chooser with cached data
                    self.showActivityChooserWithCachedData()
                }
            }
        }, errorHandler: { [weak self] error in
            print("[WatchConnectivity] Message error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self?.checkApplicationContext()
            }
        })
    }
    
    private func checkApplicationContext() {
        let session = WCSession.default
        let context = session.receivedApplicationContext
        
        print("[WatchConnectivity] Checking application context: \(context)")
        
        if let activitiesData = context["activities"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: activitiesData),
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
                    self.showActivityChooserWithCachedData()
                }
            }
        } else {
            showActivityChooserWithCachedData()
        }
    }
    
    private func showActivityChooserWithCachedData() {
        if let schedule = scheduleData, let activities = activityData {
            appState = .chooseActivity(schedule, activities)
        } else {
            // Create empty data to show the UI
            let emptySchedule = WatchScheduleData(todayItems: [], dayName: "Today")
            let emptyActivities = WatchActivityData(
                workouts: [],
                hasActiveSession: false,
                activeSessionType: nil,
                activeSessionName: nil,
                activeSessionWorkoutId: nil,
                activeSessionLocation: nil
            )
            appState = .chooseActivity(emptySchedule, emptyActivities)
        }
    }
    
    func fetchSchedule() {
        let session = WCSession.default
        
        guard session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated, cannot fetch schedule")
            showActivityChooserWithCachedData()
            return
        }
        
        if session.isReachable {
            session.sendMessage(["request": "schedule"], replyHandler: { [weak self] response in
                guard let self = self else { return }
                
                if let data = try? JSONSerialization.data(withJSONObject: response),
                   let schedule = try? JSONDecoder().decode(WatchScheduleData.self, from: data) {
                    DispatchQueue.main.async {
                        self.scheduleData = schedule
                        if let activities = self.activityData {
                            self.appState = .chooseActivity(schedule, activities)
                        } else {
                            self.showActivityChooserWithCachedData()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showActivityChooserWithCachedData()
                    }
                }
            }, errorHandler: { [weak self] error in
                print("[WatchConnectivity] Error fetching schedule: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showActivityChooserWithCachedData()
                }
            })
        } else {
            // Use cached schedule from context
            if let context = session.receivedApplicationContext["schedule"] as? [String: Any],
               let data = try? JSONSerialization.data(withJSONObject: context),
               let schedule = try? JSONDecoder().decode(WatchScheduleData.self, from: data) {
                scheduleData = schedule
            }
            showActivityChooserWithCachedData()
        }
    }
    
    func startActivity(type: String, location: String, workoutId: String? = nil) {
        let session = WCSession.default
        
        var message: [String: Any] = [
            "request": "startActivity",
            "activity": type,
            "location": location
        ]
        
        if let workoutId = workoutId {
            message["workoutId"] = workoutId
        }
        
        // Always try to send, queue if not reachable
        if session.isReachable {
            session.sendMessage(message, replyHandler: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.checkForActiveSession()
                }
            }, errorHandler: { error in
                print("[WatchConnectivity] Start activity error: \(error.localizedDescription)")
            })
        }
        
        // Also send via userInfo for reliability
        session.transferUserInfo(message)
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
        
        // Try immediate message if reachable
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("[WatchConnectivity] Send metrics error: \(error.localizedDescription)")
            })
        }
        
        // Always also send via transferUserInfo for reliability
        session.transferUserInfo(message)
    }
    
    func sendEnded(uuid: UUID?) {
        let session = WCSession.default
        var message: [String: Any] = ["event": "ended"]
        if let uuid {
            message["uuid"] = uuid.uuidString
        }
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("[WatchConnectivity] Send ended error: \(error.localizedDescription)")
            })
        }
        
        // Always send via userInfo for reliability
        session.transferUserInfo(message)
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
            })
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.activationState = activationState
            self.isReachable = session.isReachable
            self.isConnected = activationState == .activated
            
            if let error = error {
                print("[WatchConnectivity] Activation error: \(error.localizedDescription)")
            } else {
                print("[WatchConnectivity] Activated - state: \(activationState.rawValue), reachable: \(session.isReachable)")
            }
            
            self.flushPendingIfPossible()
            if activationState == .activated {
                self.checkForActiveSession()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("[WatchConnectivity] Reachability changed: \(session.isReachable)")
            self.flushPendingIfPossible()
            if session.isReachable {
                self.checkForActiveSession()
            }
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
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        if let request = userInfo["request"] as? String, request == "startActivity" {
            let activity = userInfo["activity"] as? String ?? "workout"
            let location = userInfo["location"] as? String ?? "indoor"
            DispatchQueue.main.async {
                self.receivedStartCommand = (type: activity, location: location)
                self.onStartCommand?(activity, location)
            }
        } else if let event = userInfo["event"] as? String, event == "ended" {
            DispatchQueue.main.async {
                self.onEndCommand?()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("[WatchConnectivity] Received application context: \(applicationContext)")
        
        if let activitiesData = applicationContext["activities"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: activitiesData),
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
                }
            }
        }
        
        if let scheduleData = applicationContext["schedule"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: scheduleData),
           let schedule = try? JSONDecoder().decode(WatchScheduleData.self, from: data) {
            DispatchQueue.main.async {
                self.scheduleData = schedule
            }
        }
    }
}

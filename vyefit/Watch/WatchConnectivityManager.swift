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

struct WatchScheduleData: Codable {
    let todayItems: [WatchScheduleItem]
    let dayName: String
}

struct WatchScheduleItem: Codable {
    let id: String
    let type: String // "workout", "run", "rest", "busy"
    let name: String
    let icon: String
    let colorHex: String
    let workoutId: String?
    let runType: String?
}

struct WatchActivityData: Codable {
    let workouts: [WatchWorkoutSummary]
    let hasActiveSession: Bool
    let activeSessionType: String? // "workout" or "run"
    let activeSessionName: String?
    let activeSessionWorkoutId: String?
    let activeSessionLocation: String?
}

struct WatchWorkoutSummary: Codable {
    let id: String
    let name: String
    let icon: String
    let exerciseCount: Int
}

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published private(set) var isReachable: Bool = false
    @Published private(set) var isActivated: Bool = false
    @Published private(set) var latestMetrics: WatchMetrics?
    @Published private(set) var isConnected: Bool = false
    
    var onMetrics: ((WatchMetrics) -> Void)?
    var onWorkoutEnded: ((UUID?) -> Void)?
    var onStartFromWatch: ((String, String, String?) -> Void)? // activity, location, workoutId
    
    private var activationCompletion: ((Bool) -> Void)?
    
    private override init() {
        super.init()
        guard WCSession.isSupported() else { 
            print("[WatchConnectivity] WCSession not supported on this device")
            return 
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        isConnected = session.activationState == .activated
        isReachable = session.isReachable
    }
    
    func activate(completion: ((Bool) -> Void)? = nil) {
        guard WCSession.isSupported() else {
            completion?(false)
            return
        }
        
        let session = WCSession.default
        if session.activationState == .activated {
            isActivated = true
            isConnected = true
            isReachable = session.isReachable
            completion?(true)
        } else {
            activationCompletion = completion
            session.activate()
        }
    }
    
    func updateApplicationContext() {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        
        let activityData = getActivityData()
        let scheduleData = getScheduleData()
        
        var context: [String: Any] = [:]
        
        if let data = try? JSONEncoder().encode(activityData),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            context["activities"] = json
        }
        
        if let data = try? JSONEncoder().encode(scheduleData),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            context["schedule"] = json
        }
        
        do {
            try session.updateApplicationContext(context)
            print("[WatchConnectivity] Updated application context")
        } catch {
            print("[WatchConnectivity] Failed to update context: \(error.localizedDescription)")
        }
    }
    
    func startWorkout(activity: String, location: String) {
        let session = WCSession.default
        let message = ["command": "start", "activity": activity, "location": location]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("[WatchConnectivity] Start workout error: \(error.localizedDescription)")
            })
        }
        
        // Also send via userInfo for reliability
        session.transferUserInfo(message)
    }
    
    func endWorkout() {
        let session = WCSession.default
        let message = ["command": "end"]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("[WatchConnectivity] End workout error: \(error.localizedDescription)")
            })
        }
        
        session.transferUserInfo(message)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isActivated = (activationState == .activated)
            self.isReachable = session.isReachable
            self.isConnected = activationState == .activated
            
            if let error = error {
                print("[WatchConnectivity] Activation error: \(error.localizedDescription)")
            } else {
                print("[WatchConnectivity] Activated - reachable: \(session.isReachable)")
            }
            
            self.activationCompletion?(activationState == .activated)
            self.activationCompletion = nil
            
            if activationState == .activated {
                self.updateApplicationContext()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("[WatchConnectivity] Reachability changed: \(session.isReachable)")
            
            if session.isReachable {
                self.updateApplicationContext()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let request = message["request"] as? String {
            switch request {
            case "schedule":
                let scheduleData = getScheduleData()
                if let data = try? JSONEncoder().encode(scheduleData),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    replyHandler(json)
                } else {
                    replyHandler(["error": "Failed to encode schedule"])
                }
                return
                
            case "activities":
                let activityData = getActivityData()
                if let data = try? JSONEncoder().encode(activityData),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    replyHandler(json)
                } else {
                    replyHandler(["error": "Failed to encode activities"])
                }
                return
                
            case "startActivity":
                if let activity = message["activity"] as? String,
                   let location = message["location"] as? String {
                    let workoutId = message["workoutId"] as? String
                    DispatchQueue.main.async {
                        self.onStartFromWatch?(activity, location, workoutId)
                    }
                }
                replyHandler(["status": "started"])
                return
                
            default:
                break
            }
        }
        
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
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        if let request = userInfo["request"] as? String, request == "startActivity" {
            if let activity = userInfo["activity"] as? String,
               let location = userInfo["location"] as? String {
                let workoutId = userInfo["workoutId"] as? String
                DispatchQueue.main.async {
                    self.onStartFromWatch?(activity, location, workoutId)
                }
            }
        } else if let event = userInfo["event"] as? String, event == "ended" {
            let uuid = (userInfo["uuid"] as? String).flatMap { UUID(uuidString: $0) }
            DispatchQueue.main.async {
                self.onWorkoutEnded?(uuid)
            }
        } else if let activity = userInfo["activity"] as? String {
            let metrics = WatchMetrics(
                activity: activity,
                heartRate: userInfo["heartRate"] as? Double ?? 0,
                distanceMeters: userInfo["distanceMeters"] as? Double ?? 0,
                activeEnergyKcal: userInfo["activeEnergyKcal"] as? Double ?? 0,
                cadenceSpm: userInfo["cadenceSpm"] as? Double ?? 0,
                elapsedSeconds: userInfo["elapsedSeconds"] as? Int ?? 0
            )
            DispatchQueue.main.async {
                self.latestMetrics = metrics
                self.onMetrics?(metrics)
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    private func getScheduleData() -> WatchScheduleData {
        let scheduleStore = ScheduleStore.shared
        let todayItems = scheduleStore.todaySchedule?.items ?? []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: scheduleStore.selectedDate)
        
        let workoutStore = WorkoutStore.shared
        
        let watchItems = todayItems.map { item -> WatchScheduleItem in
            let name: String
            let icon: String
            let colorHex: String
            let workoutId: String?
            let runType: String?
            
            switch item.type {
            case .workout:
                if let id = item.workoutId,
                   let workout = workoutStore.workouts.first(where: { $0.id == id }) {
                    name = workout.name
                    icon = workout.icon
                    colorHex = "CC7359" // terracotta
                    workoutId = id.uuidString
                    runType = nil
                } else {
                    name = "Workout"
                    icon = "dumbbell.fill"
                    colorHex = "CC7359"
                    workoutId = item.workoutId?.uuidString
                    runType = nil
                }
            case .run:
                name = item.runType?.rawValue ?? "Run"
                icon = item.runType?.icon ?? "figure.run"
                colorHex = "8CA680" // sage
                workoutId = nil
                runType = item.runType?.rawValue
            case .rest:
                name = "Rest Day"
                icon = "bed.double.fill"
                colorHex = "C0B8A8" // stone
                workoutId = nil
                runType = nil
            case .busy:
                name = "Busy"
                icon = "briefcase.fill"
                colorHex = "A66858" // clay
                workoutId = nil
                runType = nil
            }
            
            return WatchScheduleItem(
                id: item.id.uuidString,
                type: item.type.rawValue,
                name: name,
                icon: icon,
                colorHex: colorHex,
                workoutId: workoutId,
                runType: runType
            )
        }
        
        return WatchScheduleData(todayItems: watchItems, dayName: dayName)
    }
    
    private func getActivityData() -> WatchActivityData {
        let workoutStore = WorkoutStore.shared
        let runStore = RunStore.shared
        
        let hasActiveWorkout = workoutStore.activeSession != nil
        let hasActiveRun = runStore.activeSession != nil
        
        let hasActiveSession = hasActiveWorkout || hasActiveRun
        let activeSessionType: String? = hasActiveWorkout ? "workout" : (hasActiveRun ? "run" : nil)
        let activeSessionName: String? = workoutStore.activeSession?.workout.name ?? runStore.activeSession?.configuration.type.rawValue
        let activeSessionWorkoutId: String? = workoutStore.activeSession?.workout.id.uuidString
        let activeSessionLocation: String? = hasActiveWorkout ? "indoor" : (hasActiveRun ? "outdoor" : nil)
        
        let workouts = workoutStore.workouts.prefix(10).map { workout in
            WatchWorkoutSummary(
                id: workout.id.uuidString,
                name: workout.name,
                icon: workout.icon,
                exerciseCount: workout.exercises.count
            )
        }
        
        return WatchActivityData(
            workouts: Array(workouts),
            hasActiveSession: hasActiveSession,
            activeSessionType: activeSessionType,
            activeSessionName: activeSessionName,
            activeSessionWorkoutId: activeSessionWorkoutId,
            activeSessionLocation: activeSessionLocation
        )
    }
}

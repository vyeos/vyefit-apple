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
    let isPaused: Bool
}

struct WatchScheduleData: Codable {
    let todayItems: [WatchScheduleItem]
    let dayName: String
}

struct WatchScheduleItem: Codable {
    let id: String
    let type: String
    let name: String
    let icon: String
    let colorHex: String
    let workoutId: String?
    let runType: String?
    let isCompleted: Bool
}

struct WatchActivityData: Codable {
    let workouts: [WatchWorkoutSummary]
    let hasActiveSession: Bool
    let activeSessionType: String? // "workout" or "run"
    let activeSessionName: String?
    let activeSessionWorkoutId: String?
    let activeSessionLocation: String?
}

struct WatchWeeklySessions: Codable {
    let sessions: [WatchSessionRecord]
}

struct WatchSessionRecord: Codable, Identifiable {
    let id: String
    let type: String // "workout" or "run"
    let name: String
    let date: Date
    let duration: Int // seconds
    let calories: Int
    let icon: String
    let colorHex: String
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
    var onPauseFromWatch: (() -> Void)?
    var onResumeFromWatch: (() -> Void)?
    
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
        let weeklySessions = getWeeklySessions()
        
        var context: [String: Any] = [:]
        
        if let data = try? JSONEncoder().encode(activityData),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            context["activities"] = json
        }
        
        if let data = try? JSONEncoder().encode(scheduleData),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            context["schedule"] = json
        }
        
        if let data = try? JSONEncoder().encode(weeklySessions),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            context["weeklySessions"] = json
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
    
    func pauseWorkout() {
        let session = WCSession.default
        let message = ["command": "pause"]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("[WatchConnectivity] Pause workout error: \(error.localizedDescription)")
            })
        }
        session.transferUserInfo(message)
    }
    
    func resumeWorkout() {
        let session = WCSession.default
        let message = ["command": "resume"]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("[WatchConnectivity] Resume workout error: \(error.localizedDescription)")
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
        
        if let event = message["event"] as? String, event == "pause" {
            DispatchQueue.main.async {
                self.onPauseFromWatch?()
            }
            return
        }
        
        if let event = message["event"] as? String, event == "resume" {
            DispatchQueue.main.async {
                self.onResumeFromWatch?()
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
            elapsedSeconds: message["elapsedSeconds"] as? Int ?? 0,
            isPaused: message["isPaused"] as? Bool ?? false
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
        } else if let event = userInfo["event"] as? String, event == "pause" {
            DispatchQueue.main.async {
                self.onPauseFromWatch?()
            }
        } else if let event = userInfo["event"] as? String, event == "resume" {
            DispatchQueue.main.async {
                self.onResumeFromWatch?()
            }
        } else if let activity = userInfo["activity"] as? String {
            let metrics = WatchMetrics(
                activity: activity,
                heartRate: userInfo["heartRate"] as? Double ?? 0,
                distanceMeters: userInfo["distanceMeters"] as? Double ?? 0,
                activeEnergyKcal: userInfo["activeEnergyKcal"] as? Double ?? 0,
                cadenceSpm: userInfo["cadenceSpm"] as? Double ?? 0,
                elapsedSeconds: userInfo["elapsedSeconds"] as? Int ?? 0,
                isPaused: userInfo["isPaused"] as? Bool ?? false
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
        let historyStore = HistoryStore.shared
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        let todayWorkouts = historyStore.workoutSessionRecords.filter { $0.date >= startOfDay && $0.date < endOfDay }
        let todayRuns = historyStore.runSessionRecords.filter { $0.date >= startOfDay && $0.date < endOfDay }
        
        let watchItems = todayItems.map { item -> WatchScheduleItem in
            let name: String
            let icon: String
            let colorHex: String
            let workoutId: String?
            let runType: String?
            var isCompleted = false
            
            switch item.type {
            case .workout:
                if let id = item.workoutId,
                   let workout = workoutStore.workouts.first(where: { $0.id == id }) {
                    name = workout.name
                    icon = workout.icon
                    colorHex = "CC7359"
                    workoutId = id.uuidString
                    runType = nil
                    isCompleted = todayWorkouts.contains { $0.workoutTemplateName == workout.name }
                } else {
                    name = "Workout"
                    icon = "dumbbell.fill"
                    colorHex = "CC7359"
                    workoutId = item.workoutId?.uuidString
                    runType = nil
                    isCompleted = !todayWorkouts.isEmpty
                }
            case .run:
                name = item.runType?.rawValue ?? "Run"
                icon = item.runType?.icon ?? "figure.run"
                colorHex = "8CA680"
                workoutId = nil
                runType = item.runType?.rawValue
                isCompleted = todayRuns.contains { $0.type.rawValue == item.runType?.rawValue }
            case .rest:
                name = "Rest Day"
                icon = "bed.double.fill"
                colorHex = "C0B8A8"
                workoutId = nil
                runType = nil
                isCompleted = true
            }
            
            return WatchScheduleItem(
                id: item.id.uuidString,
                type: item.type.rawValue,
                name: name,
                icon: icon,
                colorHex: colorHex,
                workoutId: workoutId,
                runType: runType,
                isCompleted: isCompleted
            )
        }
        
        return WatchScheduleData(todayItems: watchItems, dayName: dayName)
    }
    
    private func getWeeklySessions() -> WatchWeeklySessions {
        let historyStore = HistoryStore.shared
        let calendar = Calendar.current
        let today = Date()
        
        // Get start of this week (Monday)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: today)) ?? today
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? today
        
        var sessions: [WatchSessionRecord] = []
        
        // Add workouts
        for workout in historyStore.workoutSessionRecords {
            guard workout.date >= startOfWeek && workout.date < endOfWeek else { continue }
            sessions.append(WatchSessionRecord(
                id: workout.id.uuidString,
                type: "workout",
                name: workout.name,
                date: workout.date,
                duration: Int(workout.duration),
                calories: workout.calories,
                icon: "dumbbell.fill",
                colorHex: "CC7359"
            ))
        }
        
        // Add runs
        for run in historyStore.runSessionRecords {
            guard run.date >= startOfWeek && run.date < endOfWeek else { continue }
            sessions.append(WatchSessionRecord(
                id: run.id.uuidString,
                type: "run",
                name: run.name,
                date: run.date,
                duration: Int(run.duration),
                calories: run.calories,
                icon: "figure.run",
                colorHex: "8CA680"
            ))
        }
        
        // Sort by date descending
        sessions.sort { $0.date > $1.date }
        
        return WatchWeeklySessions(sessions: sessions)
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

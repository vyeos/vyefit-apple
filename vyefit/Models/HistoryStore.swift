//
//  HistoryStore.swift
//  vyefit
//
//  Store for managing completed workout and run sessions.
//

import Foundation
import SwiftUI

struct CompletedWorkout: Identifiable, Codable {
    let id: UUID
    let date: Date
    let name: String
    let location: String
    let duration: TimeInterval
    let calories: Int
    let exerciseCount: Int
    let heartRateAvg: Int
    let heartRateMax: Int
    let heartRateData: [HeartRateDataPoint]
    
    let workoutName: String
    let workoutType: String
    
    let wasPaused: Bool
    let totalElapsedTime: TimeInterval?
    let workingTime: TimeInterval?
}

struct CompletedRun: Identifiable, Codable {
    let id: UUID
    let date: Date
    let name: String
    let location: String
    let distance: Double
    let duration: TimeInterval
    let calories: Int
    let avgPace: Double
    let heartRateAvg: Int
    let heartRateMax: Int
    let heartRateData: [HeartRateDataPoint]
    let type: String
    
    let elevationGain: Double
    let elevationLoss: Double
    let avgCadence: Int
    let splits: [RunSplit]
    let route: [MapCoordinate]
    
    let wasPaused: Bool
    let totalElapsedTime: TimeInterval?
    let workingTime: TimeInterval?
}

@Observable
class HistoryStore {
    static let shared = HistoryStore()
    
    var completedWorkouts: [CompletedWorkout] = []
    var completedRuns: [CompletedRun] = []
    
    init() {
        loadHistory()
    }
    
    func saveWorkout(
        name: String,
        duration: TimeInterval,
        calories: Int,
        exerciseCount: Int,
        avgHeartRate: Int,
        workoutType: String
    ) {
        let completed = CompletedWorkout(
            id: UUID(),
            date: Date(),
            name: name,
            location: "Current Location",
            duration: duration,
            calories: calories,
            exerciseCount: exerciseCount,
            heartRateAvg: avgHeartRate,
            heartRateMax: avgHeartRate + 10,
            heartRateData: [],
            workoutName: name,
            workoutType: workoutType,
            wasPaused: false,
            totalElapsedTime: duration,
            workingTime: duration
        )
        
        completedWorkouts.insert(completed, at: 0)
        saveToDisk()
    }
    
    func saveRun(
        type: String,
        distance: Double,
        duration: TimeInterval,
        calories: Int,
        avgHeartRate: Int
    ) {
        let avgPace = distance > 0 ? (Double(duration) / 60.0) / distance : 0
        
        let completed = CompletedRun(
            id: UUID(),
            date: Date(),
            name: type,
            location: "Current Location",
            distance: distance,
            duration: duration,
            calories: calories,
            avgPace: avgPace,
            heartRateAvg: avgHeartRate,
            heartRateMax: avgHeartRate + 10,
            heartRateData: [],
            type: type,
            elevationGain: 0,
            elevationLoss: 0,
            avgCadence: 0,
            splits: [],
            route: [],
            wasPaused: false,
            totalElapsedTime: duration,
            workingTime: duration
        )
        
        completedRuns.insert(completed, at: 0)
        saveToDisk()
    }

    func importWorkout(_ completed: CompletedWorkout) -> Bool {
        guard !completedWorkouts.contains(where: { $0.id == completed.id }) else { return false }
        completedWorkouts.insert(completed, at: 0)
        saveToDisk()
        return true
    }

    func importRun(_ completed: CompletedRun) -> Bool {
        guard !completedRuns.contains(where: { $0.id == completed.id }) else { return false }
        completedRuns.insert(completed, at: 0)
        saveToDisk()
        return true
    }
    
    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(completedWorkouts) {
            UserDefaults.standard.set(encoded, forKey: "completedWorkouts")
        }
        if let encoded = try? JSONEncoder().encode(completedRuns) {
            UserDefaults.standard.set(encoded, forKey: "completedRuns")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "completedWorkouts"),
           let decoded = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            completedWorkouts = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "completedRuns"),
           let decoded = try? JSONDecoder().decode([CompletedRun].self, from: data) {
            completedRuns = decoded
        }
    }
    
    func toRunSessionRecord(_ completed: CompletedRun) -> RunSessionRecord {
        let runType = RunGoalType(rawValue: completed.type) ?? .quickStart
        
        return RunSessionRecord(
            id: completed.id,
            date: completed.date,
            name: completed.name,
            location: completed.location,
            distance: completed.distance,
            duration: completed.duration,
            calories: completed.calories,
            avgPace: completed.avgPace,
            heartRateAvg: completed.heartRateAvg,
            heartRateMax: completed.heartRateMax,
            heartRateData: completed.heartRateData,
            type: runType,
            elevationGain: completed.elevationGain,
            elevationLoss: completed.elevationLoss,
            avgCadence: completed.avgCadence,
            splits: completed.splits,
            route: completed.route,
            wasPaused: completed.wasPaused,
            totalElapsedTime: completed.totalElapsedTime,
            workingTime: completed.workingTime
        )
    }
    
    func toWorkoutSessionRecord(_ completed: CompletedWorkout) -> WorkoutSessionRecord {
        return WorkoutSessionRecord(
            id: completed.id,
            date: completed.date,
            name: completed.name,
            location: completed.location,
            duration: completed.duration,
            calories: completed.calories,
            exerciseCount: completed.exerciseCount,
            heartRateAvg: completed.heartRateAvg,
            heartRateMax: completed.heartRateMax,
            heartRateData: completed.heartRateData,
            workoutTemplateName: completed.workoutName,
            wasPaused: completed.wasPaused,
            totalElapsedTime: completed.totalElapsedTime,
            workingTime: completed.workingTime
        )
    }
    
    var runSessionRecords: [RunSessionRecord] {
        completedRuns.map { toRunSessionRecord($0) }
    }
    
    var workoutSessionRecords: [WorkoutSessionRecord] {
        completedWorkouts.map { toWorkoutSessionRecord($0) }
    }
}

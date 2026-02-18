//
//  HistoryStore.swift
//  vyefit
//
//  Store for managing completed workout sessions.
//

import Foundation

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

@Observable
class HistoryStore {
    static let shared = HistoryStore()
    
    var completedWorkouts: [CompletedWorkout] = []
    
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
    
    func importWorkout(_ completed: CompletedWorkout) -> Bool {
        guard !completedWorkouts.contains(where: { $0.id == completed.id }) else { return false }
        completedWorkouts.insert(completed, at: 0)
        saveToDisk()
        return true
    }

    func deleteWorkout(id: UUID) {
        completedWorkouts.removeAll { $0.id == id }
        saveToDisk()
    }
    
    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(completedWorkouts) {
            UserDefaults.standard.set(encoded, forKey: "completedWorkouts")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "completedWorkouts"),
           let decoded = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            completedWorkouts = decoded
        }
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
    
    var workoutSessionRecords: [WorkoutSessionRecord] {
        completedWorkouts.map { toWorkoutSessionRecord($0) }
    }
}

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
    private let workoutsFileName = "completedWorkouts.json"
    
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
        guard let encoded = try? JSONEncoder().encode(completedWorkouts) else { return }
        do {
            try encoded.write(to: fileURL(fileName: workoutsFileName), options: .atomic)
        } catch {
            // File write failed; avoid falling back to UserDefaults for large payloads.
        }
    }
    
    private func loadHistory() {
        let fileURL = fileURL(fileName: workoutsFileName)
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            completedWorkouts = decoded
            return
        }

        // One-time migration from older UserDefaults storage.
        if let legacy = UserDefaults.standard.data(forKey: "completedWorkouts"),
           let decoded = try? JSONDecoder().decode([CompletedWorkout].self, from: legacy) {
            completedWorkouts = decoded
            saveToDisk()
            UserDefaults.standard.removeObject(forKey: "completedWorkouts")
        }
    }

    private func fileURL(fileName: String) -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        return directory.appendingPathComponent(fileName)
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

//
//  HistoryStore.swift
//  vyefit
//
//  Store for managing completed workout and run sessions.
//

import Foundation
import SwiftUI

// MARK: - Shared Data Models

struct HistoryHeartRateDataPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: TimeInterval
    let heartRate: Int
    
    init(id: UUID = UUID(), timestamp: TimeInterval, heartRate: Int) {
        self.id = id
        self.timestamp = timestamp
        self.heartRate = heartRate
    }
}

struct HistoryRunSplit: Identifiable, Codable {
    let id: UUID
    let kilometer: Int
    let pace: Double
    let elevationChange: Double
    
    init(id: UUID = UUID(), kilometer: Int, pace: Double, elevationChange: Double) {
        self.id = id
        self.kilometer = kilometer
        self.pace = pace
        self.elevationChange = elevationChange
    }
}

struct HistoryMapCoordinate: Identifiable, Codable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: TimeInterval
    
    init(id: UUID = UUID(), latitude: Double, longitude: Double, timestamp: TimeInterval) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}

// MARK: - Completed Session Models

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
    let heartRateData: [HistoryHeartRateDataPoint]
    
    // We store minimal workout info to avoid referencing UserWorkout directly (which might be deleted)
    let workoutName: String
    let workoutType: String // Store raw value of WorkoutType
    
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
    let heartRateData: [HistoryHeartRateDataPoint]
    let type: String // Store raw value of RunGoalType
    
    let elevationGain: Double
    let elevationLoss: Double
    let avgCadence: Int
    let splits: [HistoryRunSplit]
    let route: [HistoryMapCoordinate]
    
    let wasPaused: Bool
    let totalElapsedTime: TimeInterval?
    let workingTime: TimeInterval?
}

// MARK: - History Store

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
            location: "Current Location", // Placeholder
            duration: duration,
            calories: calories,
            exerciseCount: exerciseCount,
            heartRateAvg: avgHeartRate, // Simplified
            heartRateMax: avgHeartRate + 10, // Simplified
            heartRateData: [], // We don't have this in WorkoutSession yet
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
            heartRateData: [], // Placeholder
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
    
    // MARK: - Persistence
    
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
    
    func toMockRunSession(_ completed: CompletedRun) -> MockRunSession {
        let runType = RunGoalType(rawValue: completed.type) ?? .quickStart
        let heartRateMock = completed.heartRateData.map { HeartRateDataPoint(timestamp: $0.timestamp, heartRate: $0.heartRate) }
        let splitsMock = completed.splits.map { RunSplit(kilometer: $0.kilometer, pace: $0.pace, elevationChange: $0.elevationChange) }
        let routeMock = completed.route.map { MapCoordinate(latitude: $0.latitude, longitude: $0.longitude, timestamp: $0.timestamp) }
        
        return MockRunSession(
            date: completed.date,
            name: completed.name,
            location: completed.location,
            distance: completed.distance,
            duration: completed.duration,
            calories: completed.calories,
            avgPace: completed.avgPace,
            heartRateAvg: completed.heartRateAvg,
            heartRateMax: completed.heartRateMax,
            heartRateData: heartRateMock,
            type: runType,
            elevationGain: completed.elevationGain,
            elevationLoss: completed.elevationLoss,
            avgCadence: completed.avgCadence,
            splits: splitsMock,
            route: routeMock,
            wasPaused: completed.wasPaused,
            totalElapsedTime: completed.totalElapsedTime,
            workingTime: completed.workingTime
        )
    }
    
    func toMockWorkoutSession(_ completed: CompletedWorkout) -> MockWorkoutSession {
        let heartRateMock = completed.heartRateData.map { HeartRateDataPoint(timestamp: $0.timestamp, heartRate: $0.heartRate) }
        
        let mockWorkout: MockWorkout? = MockWorkout(
            name: completed.workoutName,
            exercises: [],
            color: Theme.terracotta,
            icon: "dumbbell.fill",
            lastPerformed: completed.date,
            scheduledDay: nil
        )
        
        return MockWorkoutSession(
            date: completed.date,
            name: completed.name,
            location: completed.location,
            duration: completed.duration,
            calories: completed.calories,
            exerciseCount: completed.exerciseCount,
            heartRateAvg: completed.heartRateAvg,
            heartRateMax: completed.heartRateMax,
            heartRateData: heartRateMock,
            workout: mockWorkout,
            wasPaused: completed.wasPaused,
            totalElapsedTime: completed.totalElapsedTime,
            workingTime: completed.workingTime
        )
    }
    
    var mockRunSessions: [MockRunSession] {
        completedRuns.map { toMockRunSession($0) }
    }
    
    var mockWorkoutSessions: [MockWorkoutSession] {
        completedWorkouts.map { toMockWorkoutSession($0) }
    }
}

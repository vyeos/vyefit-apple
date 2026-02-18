//
//  WorkoutStore.swift
//  vyefit
//
//  Observable store for user-created workouts.
//

import SwiftUI
import Foundation

struct UserWorkout: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var workoutType: WorkoutType
    var exercises: [CatalogExercise]
    var icon: String
    let createdAt: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UserWorkout, rhs: UserWorkout) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
class WorkoutStore {
    static let shared = WorkoutStore()
    
    var workouts: [UserWorkout] = []
    var customExercises: [CatalogExercise] = []
    
    // Active Session State
    var activeSession: WorkoutSession?
    private let workoutsFileName = "userWorkouts.json"
    private let customExercisesFileName = "customExercises.json"
    
    init() {
        loadData()
    }

    /// All exercises: catalog + user-created customs
    var allExercises: [CatalogExercise] {
        ExerciseCatalog.all + customExercises
    }

    func add(_ workout: UserWorkout) {
        workouts.insert(workout, at: 0)
        saveWorkouts()
    }

    func remove(id: UUID) {
        workouts.removeAll { $0.id == id }
        saveWorkouts()
    }

    func update(_ workout: UserWorkout) {
        guard let index = workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        workouts[index] = workout
        saveWorkouts()
    }

    func addCustomExercise(_ exercise: CatalogExercise) {
        guard !customExercises.contains(exercise),
              !ExerciseCatalog.all.contains(exercise) else { return }
        customExercises.append(exercise)
        saveCustomExercises()
    }
    
    // MARK: - Persistence
    
    private func saveWorkouts() {
        guard let encoded = try? JSONEncoder().encode(workouts) else { return }
        try? encoded.write(to: fileURL(fileName: workoutsFileName), options: .atomic)
    }
    
    private func saveCustomExercises() {
        guard let encoded = try? JSONEncoder().encode(customExercises) else { return }
        try? encoded.write(to: fileURL(fileName: customExercisesFileName), options: .atomic)
    }
    
    private func loadData() {
        if let data = try? Data(contentsOf: fileURL(fileName: workoutsFileName)),
           let decoded = try? JSONDecoder().decode([UserWorkout].self, from: data) {
            workouts = decoded
        } else if let legacy = UserDefaults.standard.data(forKey: "userWorkouts"),
                  let decoded = try? JSONDecoder().decode([UserWorkout].self, from: legacy) {
            workouts = decoded
            saveWorkouts()
            UserDefaults.standard.removeObject(forKey: "userWorkouts")
        }
        
        if let data = try? Data(contentsOf: fileURL(fileName: customExercisesFileName)),
           let decoded = try? JSONDecoder().decode([CatalogExercise].self, from: data) {
            customExercises = decoded
        } else if let legacy = UserDefaults.standard.data(forKey: "customExercises"),
                  let decoded = try? JSONDecoder().decode([CatalogExercise].self, from: legacy) {
            customExercises = decoded
            saveCustomExercises()
            UserDefaults.standard.removeObject(forKey: "customExercises")
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
    
    func startSession(for workout: UserWorkout) {
        if activeSession != nil {
            endActiveSession()
        }
        activeSession = WorkoutSession(workout: workout)
    }
    
    func endActiveSession() {
        if let session = activeSession, session.state != .completed {
            session.endWorkout()
        }
        activeSession = nil
    }
    
    func discardActiveSession() {
        activeSession?.endWorkout()
        activeSession = nil
    }
}

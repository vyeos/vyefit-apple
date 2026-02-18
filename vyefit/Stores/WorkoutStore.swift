//
//  WorkoutStore.swift
//  vyefit
//
//  Observable store for user-created workouts.
//

import SwiftUI

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
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: "userWorkouts")
        }
    }
    
    private func saveCustomExercises() {
        if let encoded = try? JSONEncoder().encode(customExercises) {
            UserDefaults.standard.set(encoded, forKey: "customExercises")
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "userWorkouts"),
           let decoded = try? JSONDecoder().decode([UserWorkout].self, from: data) {
            workouts = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "customExercises"),
           let decoded = try? JSONDecoder().decode([CatalogExercise].self, from: data) {
            customExercises = decoded
        }
    }
    
    func startSession(for workout: UserWorkout) {
        if activeSession != nil {
            endActiveSession()
        }
        activeSession = WorkoutSession(workout: workout)
    }
    
    func endActiveSession() {
        if let session = activeSession {
            HistoryStore.shared.saveWorkout(
                name: session.workout.name,
                duration: TimeInterval(session.elapsedSeconds),
                calories: 0,
                exerciseCount: session.workout.exercises.count,
                avgHeartRate: 0,
                workoutType: session.workout.workoutType.rawValue
            )
        }
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

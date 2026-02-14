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
    var workouts: [UserWorkout] = []
    var customExercises: [CatalogExercise] = []
    
    // Active Session State
    var activeSession: WorkoutSession?
    var showActiveWorkout: Bool = false

    
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
        activeSession = WorkoutSession(workout: workout)
        showActiveWorkout = true
    }
    
    func endActiveSession() {
        if let session = activeSession {
            HistoryStore.shared.saveWorkout(
                name: session.workout.name,
                duration: TimeInterval(session.elapsedSeconds),
                calories: session.activeCalories,
                exerciseCount: session.workout.exercises.count,
                avgHeartRate: session.currentHeartRate,
                workoutType: session.workout.workoutType.rawValue
            )
        }
        activeSession?.endWorkout()
        activeSession = nil
        showActiveWorkout = false
    }
    
    func discardActiveSession() {
        activeSession?.endWorkout()
        activeSession = nil
        showActiveWorkout = false
    }
}

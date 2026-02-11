//
//  WorkoutStore.swift
//  vyefit
//
//  Observable store for user-created workouts.
//

import SwiftUI

struct UserWorkout: Identifiable {
    let id: UUID
    var name: String
    var workoutType: WorkoutType
    var exercises: [CatalogExercise]
    var icon: String
    let createdAt: Date
}

@Observable
class WorkoutStore {
    var workouts: [UserWorkout] = []
    var customExercises: [CatalogExercise] = []

    /// All exercises: catalog + user-created customs
    var allExercises: [CatalogExercise] {
        ExerciseCatalog.all + customExercises
    }

    func add(_ workout: UserWorkout) {
        workouts.insert(workout, at: 0)
    }

    func remove(id: UUID) {
        workouts.removeAll { $0.id == id }
    }

    func update(_ workout: UserWorkout) {
        guard let index = workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        workouts[index] = workout
    }

    func addCustomExercise(_ exercise: CatalogExercise) {
        guard !customExercises.contains(exercise),
              !ExerciseCatalog.all.contains(exercise) else { return }
        customExercises.append(exercise)
    }
}

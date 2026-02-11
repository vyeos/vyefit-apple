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
    var exercises: [CatalogExercise]
    var icon: String
    let createdAt: Date
}

@Observable
class WorkoutStore {
    var workouts: [UserWorkout] = []

    func add(_ workout: UserWorkout) {
        workouts.insert(workout, at: 0)
    }

    func remove(id: UUID) {
        workouts.removeAll { $0.id == id }
    }
}

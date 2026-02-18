//
//  WorkoutSession.swift
//  vyefit
//
//  Manual workout logging session (sets/reps/weights only).
//

import SwiftUI
import Combine

struct WorkoutSet: Identifiable, Equatable {
    let id = UUID()
    var reps: Int?
    var weight: Double?
    var recordedAt: Date = Date()
}

struct ActiveExercise: Identifiable {
    let id = UUID()
    let exercise: CatalogExercise
    var sets: [WorkoutSet]
    
    init(exercise: CatalogExercise) {
        self.exercise = exercise
        self.sets = []
    }
}

@Observable
class WorkoutSession {
    var workout: UserWorkout
    var activeExercises: [ActiveExercise]
    var state: WorkoutState = .active
    var currentExerciseIndex: Int = 0
    
    // Kept for compatibility with existing views/history pipeline.
    var currentHeartRate: Int = 0
    var activeCalories: Int = 0
    var hasHeartRateData: Bool = false
    var hasCaloriesData: Bool = false
    
    // Rest timer for set transitions.
    var isResting: Bool = false
    var restSecondsRemaining: Int = 0
    var restDuration: Int = 60
    
    private let startedAt: Date
    private var endedAt: Date?
    private var restTimer: AnyCancellable?
    
    enum WorkoutState {
        case active
        case paused
        case completed
    }
    
    var elapsedSeconds: Int {
        let end = endedAt ?? Date()
        return max(Int(end.timeIntervalSince(startedAt)), 0)
    }
    
    var isHealthBacked: Bool { false }
    var healthWarnings: [String] { [] }
    
    init(workout: UserWorkout) {
        self.workout = workout
        self.activeExercises = workout.exercises.map { ActiveExercise(exercise: $0) }
        self.startedAt = Date()
    }
    
    func togglePause() {
        if state == .active {
            state = .paused
        } else if state == .paused {
            state = .active
        }
    }
    
    func startRestTimer() {
        cancelRestTimer()
        isResting = true
        restSecondsRemaining = restDuration
        
        restTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.restSecondsRemaining > 0 {
                    self.restSecondsRemaining -= 1
                } else {
                    self.cancelRestTimer()
                }
            }
    }
    
    func cancelRestTimer() {
        restTimer?.cancel()
        restTimer = nil
        isResting = false
        restSecondsRemaining = 0
    }
    
    func addSet(to exerciseIndex: Int) {
        activeExercises[exerciseIndex].sets.append(WorkoutSet())
    }
    
    func addRecord(to exerciseIndex: Int, reps: Int, weight: Double) {
        activeExercises[exerciseIndex].sets.append(
            WorkoutSet(reps: reps, weight: weight, recordedAt: Date())
        )
    }
    
    func removeSet(from exerciseIndex: Int, at setIndex: Int) {
        activeExercises[exerciseIndex].sets.remove(at: setIndex)
    }
    
    func endWorkout() {
        guard state != .completed else { return }
        state = .completed
        endedAt = Date()
        cancelRestTimer()
    }

    @MainActor
    func endWorkoutAsync() async {
        endWorkout()
        await Task.yield()
    }
}

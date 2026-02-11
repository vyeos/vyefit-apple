//
//  WorkoutSession.swift
//  vyefit
//
//  Manages the state of an active workout session.
//

import SwiftUI
import Combine

struct WorkoutSet: Identifiable, Equatable {
    let id = UUID()
    var reps: Int?
    var weight: Double?
    var isCompleted: Bool = false
}

struct ActiveExercise: Identifiable {
    let id = UUID() // Unique ID for this instance in the workout
    let exercise: CatalogExercise
    var sets: [WorkoutSet]
    
    init(exercise: CatalogExercise) {
        self.exercise = exercise
        // Default to 3 empty sets
        self.sets = [
            WorkoutSet(),
            WorkoutSet(),
            WorkoutSet()
        ]
    }
}

@Observable
class WorkoutSession {
    var workout: UserWorkout
    var activeExercises: [ActiveExercise]
    var state: WorkoutState = .active
    var elapsedSeconds: Int = 0
    var currentHeartRate: Int = 75
    var activeCalories: Int = 0
    
    // Rest Timer
    var isResting: Bool = false
    var restSecondsRemaining: Int = 0
    var restDuration: Int = 60 // Default 60s
    
    private var timer: AnyCancellable?
    
    enum WorkoutState {
        case active
        case paused
        case completed
    }
    
    init(workout: UserWorkout) {
        self.workout = workout
        self.activeExercises = workout.exercises.map { ActiveExercise(exercise: $0) }
        startTimer()
    }
    
    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.tick()
        }
    }
    
    func stopTimer() {
        timer?.cancel()
    }
    
    private func tick() {
        if state == .active {
            elapsedSeconds += 1
            
            // Mock data updates
            if elapsedSeconds % 5 == 0 {
                currentHeartRate = Int.random(in: 80...160)
                activeCalories += 1
            }
        }
        
        if isResting {
            if restSecondsRemaining > 0 {
                restSecondsRemaining -= 1
            } else {
                isResting = false
                // Notify user rest is over
            }
        }
    }
    
    func togglePause() {
        if state == .active {
            state = .paused
        } else if state == .paused {
            state = .active
        }
    }
    
    func completeSet(exerciseIndex: Int, setIndex: Int) {
        activeExercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
        
        if activeExercises[exerciseIndex].sets[setIndex].isCompleted {
            startRestTimer()
        } else {
            cancelRestTimer()
        }
    }
    
    func startRestTimer() {
        isResting = true
        restSecondsRemaining = restDuration
    }
    
    func cancelRestTimer() {
        isResting = false
        restSecondsRemaining = 0
    }
    
    func addSet(to exerciseIndex: Int) {
        activeExercises[exerciseIndex].sets.append(WorkoutSet())
    }
    
    func removeSet(from exerciseIndex: Int, at setIndex: Int) {
        activeExercises[exerciseIndex].sets.remove(at: setIndex)
    }
    
    func endWorkout() {
        state = .completed
        stopTimer()
    }
}

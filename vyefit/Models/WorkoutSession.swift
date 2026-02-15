//
//  WorkoutSession.swift
//  vyefit
//
//  Manages the state of an active workout session.
//

import SwiftUI
import Combine
import HealthKit

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
    var currentExerciseIndex: Int = 0
    var hasShownWatchPrompt: Bool = false
    
    var hasHeartRateData: Bool = false
    var hasCaloriesData: Bool = false
    
    // Rest Timer
    var isResting: Bool = false
    var restSecondsRemaining: Int = 0
    var restDuration: Int = 60 // Default 60s
    
    private var timer: AnyCancellable?
    private var startDate: Date = Date()
    private var pauseStartDate: Date?
    private var totalPausedSeconds: TimeInterval = 0
    private var healthController: HealthKitWorkoutController?
    private var finishedWorkout: HKWorkout?
    private var usesWatchMetrics: Bool = false
    
    enum WorkoutState {
        case active
        case paused
        case completed
    }

    var isHealthBacked: Bool {
        healthController != nil || usesWatchMetrics
    }
    
    var healthWarnings: [String] {
        guard isHealthBacked, elapsedSeconds > 10 else { return [] }
        var warnings: [String] = []
        if !hasHeartRateData { warnings.append("No heart rate sensor detected") }
        return warnings
    }
    
    init(workout: UserWorkout, healthController: HealthKitWorkoutController? = nil) {
        self.workout = workout
        self.activeExercises = workout.exercises.map { ActiveExercise(exercise: $0) }
        self.healthController = healthController
        self.startDate = Date()
        if let healthController {
            wireHealthController(healthController)
            healthController.start()
        }
        wireWatchMetrics()
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
            let now = Date()
            let elapsed = now.timeIntervalSince(startDate) - totalPausedSeconds
            elapsedSeconds = max(Int(elapsed), 0)
            
            if healthController == nil && !usesWatchMetrics, elapsedSeconds % 5 == 0 {
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
            pauseStartDate = Date()
            healthController?.pause()
        } else if state == .paused {
            state = .active
            if let pauseStartDate {
                totalPausedSeconds += Date().timeIntervalSince(pauseStartDate)
                self.pauseStartDate = nil
            }
            healthController?.resume()
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
        healthController?.end { [weak self] workout in
            self?.finishedWorkout = workout
        }
    }

    @MainActor
    func endWorkoutAsync() async {
        state = .completed
        stopTimer()
        if let healthController {
            await withCheckedContinuation { continuation in
                healthController.end { [weak self] workout in
                    self?.finishedWorkout = workout
                    continuation.resume()
                }
            }
        } else {
            await Task.yield()
        }
    }

    func consumeFinishedWorkout() -> HKWorkout? {
        defer { finishedWorkout = nil }
        return finishedWorkout
    }

    private func wireHealthController(_ controller: HealthKitWorkoutController) {
        controller.onMetrics = { [weak self] metrics in
            guard let self else { return }
            if metrics.activeEnergyKcal > 0 {
                self.activeCalories = Int(metrics.activeEnergyKcal)
                self.hasCaloriesData = true
            }
            if metrics.heartRateBpm > 0 {
                self.currentHeartRate = Int(metrics.heartRateBpm)
                self.hasHeartRateData = true
            }
        }
        controller.onStateChange = { [weak self] state in
            guard let self else { return }
            switch state {
            case .running: self.state = .active
            case .paused: self.state = .paused
            case .ended: self.state = .completed
            default: break
            }
        }
    }
    
    private func wireWatchMetrics() {
        WatchConnectivityManager.shared.onMetrics = { [weak self] metrics in
            guard let self else { return }
            guard metrics.activity == "workout" else { return }
            self.usesWatchMetrics = true
            if metrics.activeEnergyKcal > 0 {
                self.activeCalories = Int(metrics.activeEnergyKcal)
                self.hasCaloriesData = true
            }
            if metrics.heartRate > 0 {
                self.currentHeartRate = Int(metrics.heartRate)
                self.hasHeartRateData = true
            }
        }
        
        WatchConnectivityManager.shared.onWorkoutEnded = { [weak self] _ in
            guard let self else { return }
            self.state = .completed
        }
    }
}

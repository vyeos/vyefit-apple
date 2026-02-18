//
//  WorkoutSession.swift
//  vyefit
//
//  Manual workout logging session (sets/reps/weights only).
//

import SwiftUI
import Combine

struct WorkoutSet: Identifiable, Equatable {
    let id: UUID
    var reps: Int?
    var weight: Double?
    var recordedAt: Date = Date()
    
    init(id: UUID = UUID(), reps: Int? = nil, weight: Double? = nil, recordedAt: Date = Date()) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.recordedAt = recordedAt
    }
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
        let record = ExerciseRecordStore.shared.addRecord(
            exerciseName: activeExercises[exerciseIndex].exercise.name,
            reps: reps,
            weightKg: weight
        )
        activeExercises[exerciseIndex].sets.append(
            WorkoutSet(id: record.id, reps: record.reps, weight: record.weightKg, recordedAt: record.recordedAt)
        )
    }
    
    func updateRecord(exerciseIndex: Int, recordID: UUID, reps: Int, weight: Double) {
        guard let idx = activeExercises[exerciseIndex].sets.firstIndex(where: { $0.id == recordID }) else { return }
        activeExercises[exerciseIndex].sets[idx].reps = reps
        activeExercises[exerciseIndex].sets[idx].weight = weight
        ExerciseRecordStore.shared.updateRecord(id: recordID, reps: reps, weightKg: weight)
    }
    
    func removeRecord(exerciseIndex: Int, recordID: UUID) {
        activeExercises[exerciseIndex].sets.removeAll { $0.id == recordID }
        ExerciseRecordStore.shared.deleteRecord(id: recordID)
    }
    
    func removeSet(from exerciseIndex: Int, at setIndex: Int) {
        let removed = activeExercises[exerciseIndex].sets.remove(at: setIndex)
        ExerciseRecordStore.shared.deleteRecord(id: removed.id)
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

struct ExerciseRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let exerciseName: String
    var reps: Int
    var weightKg: Double
    var recordedAt: Date
}

final class ExerciseRecordStore {
    static let shared = ExerciseRecordStore()
    
    private let key = "exerciseRecords.v1"
    private var records: [ExerciseRecord] = []
    
    private init() {
        load()
    }
    
    func records(for exerciseName: String) -> [ExerciseRecord] {
        records
            .filter { $0.exerciseName == exerciseName }
            .sorted { $0.recordedAt > $1.recordedAt }
    }
    
    @discardableResult
    func addRecord(exerciseName: String, reps: Int, weightKg: Double, at date: Date = Date()) -> ExerciseRecord {
        let record = ExerciseRecord(
            id: UUID(),
            exerciseName: exerciseName,
            reps: reps,
            weightKg: weightKg,
            recordedAt: date
        )
        records.append(record)
        save()
        return record
    }
    
    func updateRecord(id: UUID, reps: Int, weightKg: Double) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].reps = reps
        records[index].weightKg = weightKg
        save()
    }
    
    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ExerciseRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded
    }
}

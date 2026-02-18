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
    var weight: Double? // Stored as kilograms for compatibility.
    var weightLb: Double?
    var recordedUnit: String?
    var recordedAt: Date = Date()
    
    init(
        id: UUID = UUID(),
        reps: Int? = nil,
        weight: Double? = nil,
        weightLb: Double? = nil,
        recordedUnit: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.weightLb = weightLb
        self.recordedUnit = recordedUnit
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
    
    func addRecord(
        to exerciseIndex: Int,
        reps: Int,
        weightKg: Double,
        weightLb: Double,
        recordedUnit: String
    ) {
        let record = ExerciseRecordStore.shared.addRecord(
            exerciseName: activeExercises[exerciseIndex].exercise.name,
            reps: reps,
            weightKg: weightKg,
            weightLb: weightLb,
            recordedUnit: recordedUnit
        )
        activeExercises[exerciseIndex].sets.append(
            WorkoutSet(
                id: record.id,
                reps: record.reps,
                weight: record.weightKg,
                weightLb: record.weightLb,
                recordedUnit: record.recordedUnit,
                recordedAt: record.recordedAt
            )
        )
    }
    
    func updateRecord(
        exerciseIndex: Int,
        recordID: UUID,
        reps: Int,
        weightKg: Double,
        weightLb: Double,
        recordedUnit: String
    ) {
        guard let idx = activeExercises[exerciseIndex].sets.firstIndex(where: { $0.id == recordID }) else { return }
        activeExercises[exerciseIndex].sets[idx].reps = reps
        activeExercises[exerciseIndex].sets[idx].weight = weightKg
        activeExercises[exerciseIndex].sets[idx].weightLb = weightLb
        activeExercises[exerciseIndex].sets[idx].recordedUnit = recordedUnit
        ExerciseRecordStore.shared.updateRecord(
            id: recordID,
            reps: reps,
            weightKg: weightKg,
            weightLb: weightLb,
            recordedUnit: recordedUnit
        )
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
    var weightLb: Double
    var recordedUnit: String
    var recordedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, exerciseName, reps, weightKg, weightLb, recordedUnit, recordedAt
    }

    init(
        id: UUID,
        exerciseName: String,
        reps: Int,
        weightKg: Double,
        weightLb: Double,
        recordedUnit: String,
        recordedAt: Date
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.reps = reps
        self.weightKg = weightKg
        self.weightLb = weightLb
        self.recordedUnit = recordedUnit
        self.recordedAt = recordedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        exerciseName = try container.decode(String.self, forKey: .exerciseName)
        reps = try container.decode(Int.self, forKey: .reps)
        weightKg = try container.decode(Double.self, forKey: .weightKg)
        recordedAt = try container.decode(Date.self, forKey: .recordedAt)

        // Backward compatibility for records saved before lbs/unit were stored.
        weightLb = try container.decodeIfPresent(Double.self, forKey: .weightLb) ?? (weightKg * 2.2046226218)
        recordedUnit = try container.decodeIfPresent(String.self, forKey: .recordedUnit) ?? "kilograms"
    }
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
    func addRecord(
        exerciseName: String,
        reps: Int,
        weightKg: Double,
        weightLb: Double,
        recordedUnit: String,
        at date: Date = Date()
    ) -> ExerciseRecord {
        let record = ExerciseRecord(
            id: UUID(),
            exerciseName: exerciseName,
            reps: reps,
            weightKg: weightKg,
            weightLb: weightLb,
            recordedUnit: recordedUnit,
            recordedAt: date
        )
        records.append(record)
        save()
        return record
    }
    
    func updateRecord(id: UUID, reps: Int, weightKg: Double, weightLb: Double, recordedUnit: String) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].reps = reps
        records[index].weightKg = weightKg
        records[index].weightLb = weightLb
        records[index].recordedUnit = recordedUnit
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

//
//  ActiveWorkoutView.swift
//  vyefit
//
//  The main tracking screen during a workout.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @State private var showEndConfirmation = false
    var onEnd: () -> Void
    var onDiscard: () -> Void
    
    init(session: WorkoutSession, onEnd: @escaping () -> Void, onDiscard: @escaping () -> Void) {
        self.session = session
        self.onEnd = onEnd
        self.onDiscard = onDiscard
    }
    
    var body: some View {
        NavigationStack {
            LogView(session: session)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(session.workout.name)
                        .font(.headline)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Minimize") {
                        dismiss()
                    }
                    .font(.system(size: 14))
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End") {
                        showEndConfirmation = true
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.terracotta)
                }
            }
            .alert("End Workout?", isPresented: $showEndConfirmation) {
                Button("Save Workout", role: .destructive) {
                    Task(priority: TaskPriority.userInitiated) {
                        await session.endWorkoutAsync()
                        onEnd()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    Task(priority: TaskPriority.userInitiated) {
                        await session.endWorkoutAsync()
                        onDiscard()
                        dismiss()
                    }
                }
            } message: {
                Text("Save this logged workout or discard it.")
            }
        }
    }
}

struct LogView: View {
    var session: WorkoutSession
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    if session.isResting {
                        RestTimerBanner(session: session)
                    } else {
                        StartNextSetBanner()
                    }
                    
                    ForEach(Array(session.activeExercises.enumerated()), id: \.element.id) { index, activeExercise in
                        ExerciseLogCard(session: session, exerciseIndex: index)
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

struct RestTimerBanner: View {
    var session: WorkoutSession
    
    var body: some View {
        HStack {
            Image(systemName: "timer")
                .font(.title2)
            VStack(alignment: .leading) {
                Text("Resting")
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                Text(formatRestTime(session.restSecondsRemaining))
                    .font(.title3)
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }
            Spacer()
            Button("Skip") {
                withAnimation {
                    session.cancelRestTimer()
                }
            }
            .buttonStyle(.bordered)
            .tint(Theme.cream)
        }
        .padding()
        .background(Theme.terracotta)
        .foregroundStyle(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct StartNextSetBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "dumbbell.fill")
                .font(.title2)
            VStack(alignment: .leading) {
                Text("Ready")
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                Text("Start Next Set")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding()
        .background(Theme.sage)
        .foregroundStyle(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ExerciseLogCard: View {
    var session: WorkoutSession
    let exerciseIndex: Int
    @State private var weightUnit = "kg"
    
    var activeExercise: ActiveExercise {
        session.activeExercises[exerciseIndex]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: activeExercise.exercise.icon)
                    .foregroundStyle(Theme.terracotta)
                Text(activeExercise.exercise.name)
                    .font(.headline)
                Spacer()
                
                Picker("Unit", selection: $weightUnit) {
                    Text("kg").tag("kg")
                    Text("lbs").tag("lbs")
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
            }
            
            Divider()
            
            // Header
            HStack {
                Text("Set")
                    .frame(width: 30)
                Text("Previous")
                    .frame(maxWidth: .infinity)
                Text(weightUnit)
                    .frame(width: 60)
                Text("Reps")
                    .frame(width: 60)
                Text("✓")
                    .frame(width: 40)
                Spacer()
                    .frame(width: 30)
            }
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
            
            // Sets
            ForEach(Array(activeExercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                let previousSet = setIndex > 0 ? activeExercise.sets[setIndex - 1] : nil
                SetRow(
                    setIndex: setIndex + 1,
                    set: set,
                    previousSet: previousSet,
                    onToggle: {
                        session.completeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
                    },
                    onUpdate: { reps, weight in
                        session.activeExercises[exerciseIndex].sets[setIndex].reps = reps
                        session.activeExercises[exerciseIndex].sets[setIndex].weight = weight
                    },
                    onDelete: {
                        withAnimation {
                            session.removeSet(from: exerciseIndex, at: setIndex)
                        }
                    }
                )
            }
            
            Button {
                withAnimation {
                    session.addSet(to: exerciseIndex)
                }
            } label: {
                Text("+ Add Set")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.terracotta)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.terracotta.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SetRow: View {
    let setIndex: Int
    let set: WorkoutSet
    let previousSet: WorkoutSet?
    let onToggle: () -> Void
    let onUpdate: (Int?, Double?) -> Void
    let onDelete: () -> Void
    
    @State private var weightText: String
    @State private var repsText: String
    
    init(setIndex: Int, set: WorkoutSet, previousSet: WorkoutSet?, onToggle: @escaping () -> Void, onUpdate: @escaping (Int?, Double?) -> Void, onDelete: @escaping () -> Void) {
        self.setIndex = setIndex
        self.set = set
        self.previousSet = previousSet
        self.onToggle = onToggle
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        
        _weightText = State(initialValue: set.weight.map { String($0) } ?? "")
        _repsText = State(initialValue: set.reps.map { String($0) } ?? "")
    }
    
    var body: some View {
        HStack {
            Text("\(setIndex)")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 30)
                .foregroundStyle(Theme.stone)
            
            Text(previousDisplay)
                .font(.system(size: 14))
                .foregroundStyle(Theme.stone)
                .frame(maxWidth: .infinity)
            
            TextField("-", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .padding(.vertical, 8)
                .background(set.isCompleted ? Theme.sage.opacity(0.2) : Theme.sand)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: weightText) { oldValue, newValue in
                    onUpdate(Int(repsText), Double(newValue))
                }
            
            TextField("-", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .padding(.vertical, 8)
                .background(set.isCompleted ? Theme.sage.opacity(0.2) : Theme.sand)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: repsText) { oldValue, newValue in
                    onUpdate(Int(newValue), Double(weightText))
                }
            
            Button {
                onToggle()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? Theme.sage : Theme.stone.opacity(0.3))
            }
            .frame(width: 40)
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.stone.opacity(0.5))
            }
            .frame(width: 30)
        }
    }

    private var previousDisplay: String {
        guard let previousSet else { return "-" }
        let reps = previousSet.reps
        let weight = previousSet.weight
        
        if reps == nil && weight == nil { return "-" }
        if let reps, let weight { return "\(formatWeight(weight)) x \(reps)" }
        if let weight { return formatWeight(weight) }
        if let reps { return "\(reps)" }
        return "-"
    }
    
    private func formatWeight(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

#Preview {
    ActiveWorkoutView(
        session: WorkoutSession(workout: UserWorkout(id: UUID(), name: "Test Workout", workoutType: .traditionalStrengthTraining, exercises: [], icon: "dumbbell.fill", createdAt: Date())),
        onEnd: {},
        onDiscard: {}
    )
}

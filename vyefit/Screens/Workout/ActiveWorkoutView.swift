//
//  ActiveWorkoutView.swift
//  vyefit
//
//  Exercise records tracker screen (reps + weight).
//

import SwiftUI

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    var onClose: () -> Void
    
    @State private var selectedExerciseIndex: Int?
    @State private var didFinalize = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(session.activeExercises.enumerated()), id: \.element.id) { index, activeExercise in
                    ExerciseRecordsCard(
                        exercise: activeExercise.exercise,
                        records: activeExercise.sets,
                        onAddRecord: {
                            selectedExerciseIndex = index
                        },
                        onDeleteRecord: { set in
                            guard let setIndex = session.activeExercises[index].sets.firstIndex(where: { $0.id == set.id }) else { return }
                            session.removeSet(from: index, at: setIndex)
                        }
                    )
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle(session.workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: {
                selectedExerciseIndex.map { ExerciseSelection(id: $0) }
            },
            set: { value in
                selectedExerciseIndex = value?.id
            }
        )) { selection in
            AddRecordSheet { reps, weight in
                session.addRecord(to: selection.id, reps: reps, weight: weight)
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        .onDisappear {
            finalizeIfNeeded()
        }
    }
    
    private func finalizeIfNeeded() {
        guard !didFinalize else { return }
        didFinalize = true
        onClose()
    }
}

private struct ExerciseRecordsCard: View {
    let exercise: CatalogExercise
    let records: [WorkoutSet]
    let onAddRecord: () -> Void
    let onDeleteRecord: (WorkoutSet) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: exercise.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.terracotta)
                    .frame(width: 30, height: 30)
                    .background(Theme.terracotta.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                    Text(exercise.muscleGroup)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                Button("Add Record") {
                    onAddRecord()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.terracotta)
                .clipShape(Capsule())
            }
            
            if records.isEmpty {
                Text("No records yet")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("#")
                            .frame(width: 28, alignment: .leading)
                        Text("Time")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Reps")
                            .frame(width: 70, alignment: .trailing)
                        Text("Weight")
                            .frame(width: 80, alignment: .trailing)
                        Text("")
                            .frame(width: 24)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.stone)
                    .padding(.bottom, 8)
                    
                    ForEach(Array(records.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("\(index + 1)")
                                .frame(width: 28, alignment: .leading)
                                .foregroundStyle(Theme.stone)
                            Text(set.recordedAt.formatted(date: .omitted, time: .shortened))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Theme.textSecondary)
                            Text("\(set.reps ?? 0)")
                                .frame(width: 70, alignment: .trailing)
                                .foregroundStyle(Theme.sage)
                            Text("\(formatWeight(set.weight ?? 0)) kg")
                                .frame(width: 80, alignment: .trailing)
                                .foregroundStyle(Theme.terracotta)
                            
                            Button(role: .destructive) {
                                onDeleteRecord(set)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                            }
                            .frame(width: 24)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .padding(.vertical, 8)
                        
                        if index < records.count - 1 {
                            Divider().background(Theme.sand)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private func formatWeight(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

private struct AddRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reps: Int = 10
    @State private var weight: Double = 20
    let onSave: (Int, Double) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reps")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .textCase(.uppercase)
                    
                    HStack {
                        Stepper("", value: $reps, in: 1...200)
                            .labelsHidden()
                        Spacer()
                        Text("\(reps)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.sage)
                    }
                }
                .padding(14)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weight (kg)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .textCase(.uppercase)
                    
                    HStack {
                        Stepper("", value: $weight, in: 0...500, step: 2.5)
                            .labelsHidden()
                        Spacer()
                        Text(weight, format: .number.precision(.fractionLength(0...1)))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.terracotta)
                    }
                }
                .padding(14)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                Button {
                    onSave(reps, weight)
                    dismiss()
                } label: {
                    Text("Save Record")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.sage)
                        .clipShape(Capsule())
                }
                .padding(.top, 6)
                
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Theme.background)
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ExerciseSelection: Identifiable {
    let id: Int
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(
            session: WorkoutSession(
                workout: UserWorkout(
                    id: UUID(),
                    name: "Upper Body",
                    workoutType: .traditionalStrengthTraining,
                    exercises: ExerciseCatalog.all.prefix(3).map { $0 },
                    icon: "dumbbell.fill",
                    createdAt: Date()
                )
            ),
            onClose: {}
        )
    }
}

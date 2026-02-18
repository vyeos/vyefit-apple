//
//  ActiveWorkoutView.swift
//  vyefit
//
//  Exercise records tracker with history, editing, and plate calculator.
//

import SwiftUI

private enum TrackerWeightUnit: String, CaseIterable, Identifiable {
    case kilograms = "Kilograms"
    case pounds = "Pounds"
    
    var id: String { rawValue }
    var symbol: String { self == .kilograms ? "kg" : "lb" }
    
    func toDisplay(_ kg: Double) -> Double {
        self == .kilograms ? kg : (kg * 2.2046226218)
    }
    
    func toKilograms(_ value: Double) -> Double {
        self == .kilograms ? value : (value / 2.2046226218)
    }
    
    var plateSizes: [Double] {
        if self == .kilograms {
            return [25, 20, 15, 10, 5, 2.5, 1.25]
        }
        return [55, 45, 35, 25, 10, 5, 2.5]
    }
    
    var defaultBarbell: Double {
        self == .kilograms ? 20 : 45
    }
}

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @AppStorage("weightUnit") private var storedWeightUnit = TrackerWeightUnit.kilograms.rawValue
    
    @State private var selectedExerciseIndex: Int?
    @State private var recordEditorContext: RecordEditorContext?
    @State private var historyRefreshToken = 0
    
    private var preferredUnit: TrackerWeightUnit {
        TrackerWeightUnit(rawValue: storedWeightUnit) ?? .kilograms
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(session.activeExercises.enumerated()), id: \.element.id) { index, activeExercise in
                    ExerciseRecordsCard(
                        exercise: activeExercise.exercise,
                        records: activeExercise.sets,
                        unit: preferredUnit,
                        onOpenHistory: {
                            selectedExerciseIndex = index
                        },
                        onAddRecord: {
                            recordEditorContext = RecordEditorContext(exerciseIndex: index)
                        },
                        onDeleteRecord: { set in
                            session.removeRecord(exerciseIndex: index, recordID: set.id)
                            historyRefreshToken += 1
                        }
                    )
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle(session.workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: Binding(
            get: { selectedExerciseIndex.map { ExerciseSelection(id: $0) } },
            set: { selectedExerciseIndex = $0?.id }
        )) { selection in
            ExerciseHistoryView(
                exercise: session.activeExercises[selection.id].exercise,
                currentSessionRecords: session.activeExercises[selection.id].sets,
                unit: preferredUnit,
                refreshToken: historyRefreshToken,
                onAddRecord: {
                    recordEditorContext = RecordEditorContext(exerciseIndex: selection.id)
                },
                onEditRecord: { record in
                    recordEditorContext = RecordEditorContext(exerciseIndex: selection.id, existingRecord: record)
                },
                onDeleteRecord: { record in
                    if session.activeExercises[selection.id].sets.contains(where: { $0.id == record.id }) {
                        session.removeRecord(exerciseIndex: selection.id, recordID: record.id)
                    } else {
                        ExerciseRecordStore.shared.deleteRecord(id: record.id)
                    }
                    historyRefreshToken += 1
                }
            )
        }
        .sheet(item: $recordEditorContext) { context in
            RecordEditorSheet(
                title: context.existingRecord == nil ? "Add Record" : "Edit Record",
                initialRecord: context.existingRecord,
                initialUnit: preferredUnit
            ) { reps, weightKg in
                if let existing = context.existingRecord {
                    session.updateRecord(
                        exerciseIndex: context.exerciseIndex,
                        recordID: existing.id,
                        reps: reps,
                        weight: weightKg
                    )
                } else {
                    session.addRecord(
                        to: context.exerciseIndex,
                        reps: reps,
                        weight: weightKg
                    )
                }
                historyRefreshToken += 1
            }
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct ExerciseRecordsCard: View {
    let exercise: CatalogExercise
    let records: [WorkoutSet]
    let unit: TrackerWeightUnit
    let onOpenHistory: () -> Void
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
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.stone)
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
                            .frame(width: 86, alignment: .trailing)
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
                            Text("\(formatWeight(unit.toDisplay(set.weight ?? 0))) \(unit.symbol)")
                                .frame(width: 86, alignment: .trailing)
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
            
            Button("Add Record") {
                onAddRecord()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.cream)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Theme.terracotta)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture {
            onOpenHistory()
        }
    }
    
    private func formatWeight(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

private struct ExerciseHistoryView: View {
    let exercise: CatalogExercise
    let currentSessionRecords: [WorkoutSet]
    let unit: TrackerWeightUnit
    let refreshToken: Int
    let onAddRecord: () -> Void
    let onEditRecord: (WorkoutSet) -> Void
    let onDeleteRecord: (WorkoutSet) -> Void
    
    @State private var allRecords: [WorkoutSet] = []
    
    var groupedRecords: [(Date, [WorkoutSet])] {
        let grouped = Dictionary(grouping: allRecords) { Calendar.current.startOfDay(for: $0.recordedAt) }
        return grouped
            .map { ($0.key, $0.value.sorted { $0.recordedAt > $1.recordedAt }) }
            .sorted { $0.0 > $1.0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(groupedRecords, id: \.0) { day, records in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(dayTitle(day))
                            .font(.system(size: 15, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                        
                        VStack(spacing: 0) {
                            ForEach(records) { record in
                                HStack {
                                    Text(record.recordedAt.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("\(record.reps ?? 0) reps")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.sage)
                                    
                                    Text("\(formatWeight(unit.toDisplay(record.weight ?? 0))) \(unit.symbol)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.terracotta)
                                        .frame(width: 110, alignment: .trailing)
                                    
                                    Button {
                                        onEditRecord(record)
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.stone)
                                    }
                                    .frame(width: 20)
                                    
                                    Button(role: .destructive) {
                                        onDeleteRecord(record)
                                        loadData()
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                    }
                                    .frame(width: 20)
                                }
                                .padding(.vertical, 10)
                                
                                if records.last?.id != record.id {
                                    Divider().background(Theme.sand)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .background(Theme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    onAddRecord()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onAddRecord()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Record")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.sage)
                .clipShape(Capsule())
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Theme.background.opacity(0.95))
        }
        .onAppear(perform: loadData)
        .onChange(of: currentSessionRecords.count) { _, _ in
            loadData()
        }
        .onChange(of: refreshToken) { _, _ in
            loadData()
        }
    }
    
    private func loadData() {
        allRecords = ExerciseRecordStore.shared.records(for: exercise.name).map {
            WorkoutSet(id: $0.id, reps: $0.reps, weight: $0.weightKg, recordedAt: $0.recordedAt)
        }
    }
    
    private func dayTitle(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func formatWeight(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

private struct RecordEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let initialRecord: WorkoutSet?
    let initialUnit: TrackerWeightUnit
    let onSave: (Int, Double) -> Void
    
    @State private var selectedUnit: TrackerWeightUnit = .kilograms
    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @State private var barbellText: String = ""
    @State private var plateCounts: [Double: Int] = [:]
    
    var parsedReps: Int? {
        Int(repsText)
    }
    
    var parsedWeight: Double? {
        Double(weightText)
    }
    
    var computedTotalInUnit: Double {
        let bar = Double(barbellText) ?? selectedUnit.defaultBarbell
        let platesTotalPerSide = selectedUnit.plateSizes.reduce(0.0) { total, size in
            total + (Double(plateCounts[size] ?? 0) * size)
        }
        return bar + (2 * platesTotalPerSide)
    }
    
    var isValid: Bool {
        guard let reps = parsedReps, reps > 0 else { return false }
        guard let weight = parsedWeight, weight >= 0 else { return false }
        return true
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(TrackerWeightUnit.allCases) { unit in
                        Text(unit.symbol.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reps")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        TextField("12", text: $repsText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Weight (\(selectedUnit.symbol))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        TextField("20", text: $weightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Plate Calculator")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    HStack {
                        Text("Barbell")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        TextField("", text: $barbellText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                        Text(selectedUnit.symbol)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.stone)
                        Spacer()
                        Text("Total: \(formatWeight(computedTotalInUnit)) \(selectedUnit.symbol)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.sage)
                    }
                    
                    ForEach(selectedUnit.plateSizes, id: \.self) { plate in
                        HStack {
                            Text("\(formatWeight(plate)) \(selectedUnit.symbol) x2")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                            
                            Spacer()
                            
                            Stepper(
                                "\(plateCounts[plate] ?? 0) / side",
                                value: Binding(
                                    get: { plateCounts[plate] ?? 0 },
                                    set: { plateCounts[plate] = max($0, 0) }
                                ),
                                in: 0...8
                            )
                            .labelsHidden()
                            
                            Text("\(plateCounts[plate] ?? 0)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 30)
                        }
                    }
                    
                    Button("Use Calculated Total") {
                        weightText = formatWeight(computedTotalInUnit)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.terracotta)
                }
                .padding(12)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button {
                    guard let reps = parsedReps, let weightValue = parsedWeight else { return }
                    onSave(reps, selectedUnit.toKilograms(weightValue))
                    dismiss()
                } label: {
                    Text("Save Record")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? Theme.sage : Theme.stone.opacity(0.5))
                        .clipShape(Capsule())
                }
                .disabled(!isValid)
                
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Theme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedUnit = initialUnit
                let reps = initialRecord?.reps ?? 10
                let weightInKg = initialRecord?.weight ?? initialUnit.toKilograms(20)
                repsText = "\(reps)"
                weightText = formatWeight(selectedUnit.toDisplay(weightInKg))
                barbellText = formatWeight(selectedUnit.defaultBarbell)
                selectedUnit.plateSizes.forEach { plateCounts[$0] = 0 }
            }
        }
    }
    
    private func formatWeight(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

private struct ExerciseSelection: Identifiable, Hashable {
    let id: Int
}

private struct RecordEditorContext: Identifiable {
    let id = UUID()
    let exerciseIndex: Int
    var existingRecord: WorkoutSet? = nil
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
            )
        )
    }
}

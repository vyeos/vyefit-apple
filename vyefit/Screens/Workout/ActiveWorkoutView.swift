//
//  ActiveWorkoutView.swift
//  vyefit
//
//  Exercise records tracker with history and editable record input.
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
}

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @AppStorage("weightUnit") private var storedWeightUnit = TrackerWeightUnit.kilograms.rawValue

    @State private var selectedExerciseIndex: Int?
    @State private var recordEditorContext: RecordEditorContext?
    @State private var historyRefreshToken = 0
    @State private var pendingDelete: PendingDelete?

    private var preferredUnit: TrackerWeightUnit {
        TrackerWeightUnit(rawValue: storedWeightUnit) ?? .kilograms
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(session.activeExercises.enumerated()), id: \.element.id) { index, activeExercise in
                    ExerciseRecordsCard(
                        exercise: activeExercise.exercise,
                        records: latestRecords(for: activeExercise.exercise.name),
                        unit: preferredUnit,
                        onOpenHistory: {
                            selectedExerciseIndex = index
                        },
                        onAddRecord: {
                            recordEditorContext = RecordEditorContext(exerciseIndex: index)
                        },
                        onDeleteRecord: { set in
                            pendingDelete = PendingDelete(
                                id: set.id,
                                mode: .store(recordID: set.id)
                            )
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
                refreshToken: historyRefreshToken,
                onAddRecord: {
                    recordEditorContext = RecordEditorContext(exerciseIndex: selection.id)
                },
                onEditRecord: { record in
                    recordEditorContext = RecordEditorContext(exerciseIndex: selection.id, existingRecord: record)
                },
                onDeleteRecord: { record in
                    ExerciseRecordStore.shared.deleteRecord(id: record.id)
                    historyRefreshToken += 1
                }
            )
        }
        .sheet(item: $recordEditorContext) { context in
            RecordEditorSheet(
                title: context.existingRecord == nil ? "Add Record" : "Edit Record",
                initialRecord: context.existingRecord,
                initialUnit: preferredUnit
            ) { reps, weightKg, weightLb, recordedUnit in
                if let existing = context.existingRecord {
                    session.updateRecord(
                        exerciseIndex: context.exerciseIndex,
                        recordID: existing.id,
                        reps: reps,
                        weightKg: weightKg,
                        weightLb: weightLb,
                        recordedUnit: recordedUnit
                    )
                } else {
                    session.addRecord(
                        to: context.exerciseIndex,
                        reps: reps,
                        weightKg: weightKg,
                        weightLb: weightLb,
                        recordedUnit: recordedUnit
                    )
                }
                historyRefreshToken += 1
            }
            .presentationDetents([.height(390)])
            .presentationDragIndicator(.visible)
        }
        .alert("Delete Record?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { visible in if !visible { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                guard let pendingDelete else { return }
                switch pendingDelete.mode {
                case .store(let recordID):
                    ExerciseRecordStore.shared.deleteRecord(id: recordID)
                }
                historyRefreshToken += 1
                self.pendingDelete = nil
            }
        } message: {
            Text("This record will be permanently removed.")
        }
    }

    private func latestRecords(for exerciseName: String) -> [WorkoutSet] {
        Array(
            ExerciseRecordStore.shared.records(for: exerciseName)
                .prefix(3)
                .map {
                    WorkoutSet(
                        id: $0.id,
                        reps: $0.reps,
                        weight: $0.weightKg,
                        weightLb: $0.weightLb,
                        recordedUnit: $0.recordedUnit,
                        recordedAt: $0.recordedAt
                    )
                }
        )
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
        if value == floor(value) { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}

private struct ExerciseHistoryView: View {
    let exercise: CatalogExercise
    let refreshToken: Int
    let onAddRecord: () -> Void
    let onEditRecord: (WorkoutSet) -> Void
    let onDeleteRecord: (WorkoutSet) -> Void

    @State private var allRecords: [WorkoutSet] = []
    @State private var pendingDeleteRecord: WorkoutSet?

    var groupedRecords: [(Date, [WorkoutSet])] {
        let grouped = Dictionary(grouping: allRecords) { Calendar.current.startOfDay(for: $0.recordedAt) }
        return grouped
            .map { ($0.key, $0.value.sorted { $0.recordedAt > $1.recordedAt }) }
            .sorted { $0.0 > $1.0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if groupedRecords.isEmpty {
                    VStack(spacing: 8) {
                        Text("No history")
                            .font(.system(size: 24, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Record a set to see here")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 420, alignment: .center)
                } else {
                    ForEach(groupedRecords, id: \.0) { day, records in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Text(dayTitle(day))
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
                                    .foregroundStyle(Theme.textPrimary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.stone)
                            }

                            VStack(spacing: 0) {
                                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Theme.stone)
                                            .frame(width: 18, alignment: .leading)

                                        Text(record.recordedAt.formatted(date: .omitted, time: .shortened))
                                            .font(.system(size: 14))
                                            .foregroundStyle(Theme.textSecondary)

                                        Spacer()

                                        Text("\(record.reps ?? 0) rep")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Theme.sage)

                                    unitText(record: record)
                                        .frame(width: 120, alignment: .trailing)

                                    Button(role: .destructive) {
                                        pendingDeleteRecord = record
                                    } label: {
                                        Image(systemName: "trash")
                                                .font(.system(size: 12))
                                        }
                                        .frame(width: 20)
                                }
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onEditRecord(record)
                                }

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
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onAddRecord()
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.sage)
                        .frame(width: 76, height: 76)
                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Theme.cream)
                }
                .shadow(color: Theme.bark.opacity(0.22), radius: 10, x: 0, y: 5)
                .padding(.bottom, 14)
            }
            .background(Theme.background.opacity(0.95))
        }
        .alert("Delete Record?", isPresented: Binding(
            get: { pendingDeleteRecord != nil },
            set: { visible in if !visible { pendingDeleteRecord = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                pendingDeleteRecord = nil
            }
            Button("Delete", role: .destructive) {
                guard let record = pendingDeleteRecord else { return }
                onDeleteRecord(record)
                loadData()
                pendingDeleteRecord = nil
            }
        } message: {
            Text("This record will be permanently removed.")
        }
        .onAppear(perform: loadData)
        .onChange(of: refreshToken) { _, _ in loadData() }
    }

    @ViewBuilder
    private func unitText(record: WorkoutSet) -> some View {
        let kg = record.weight ?? 0
        let lb = record.weightLb ?? (kg * 2.2046226218)
        let recorded = record.recordedUnit ?? "kilograms"
        let kgPrimary = recorded == "kilograms"

        HStack(spacing: 6) {
            Text("\(formatWeight(kg))kg")
                .foregroundStyle(kgPrimary ? Theme.terracotta : Theme.stone)
            Text("/")
                .foregroundStyle(Theme.stone.opacity(0.7))
            Text("\(formatWeight(lb))lb")
                .foregroundStyle(kgPrimary ? Theme.stone : Theme.terracotta)
        }
        .font(.system(size: 13, weight: .semibold))
    }

    private func loadData() {
        allRecords = ExerciseRecordStore.shared.records(for: exercise.name).map {
            WorkoutSet(
                id: $0.id,
                reps: $0.reps,
                weight: $0.weightKg,
                weightLb: $0.weightLb,
                recordedUnit: $0.recordedUnit,
                recordedAt: $0.recordedAt
            )
        }
    }

    private func dayTitle(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }

    private func formatWeight(_ value: Double) -> String {
        if value == floor(value) { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}

private struct RecordEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let initialRecord: WorkoutSet?
    let initialUnit: TrackerWeightUnit
    let onSave: (Int, Double, Double, String) -> Void

    @State private var selectedUnit: TrackerWeightUnit = .kilograms
    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @FocusState private var focusedField: FocusedField?

    private enum FocusedField {
        case reps
        case weight
    }

    var parsedReps: Int? { Int(repsText) }
    var parsedWeight: Double? { Double(weightText) }

    var isValid: Bool {
        guard let reps = parsedReps, reps > 0 else { return false }
        guard let weight = parsedWeight, weight >= 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 0) {
                    valueEditor(
                        value: $repsText,
                        unit: "rep",
                        color: Theme.sage,
                        focus: .reps,
                        minusAction: {
                            let current = parsedReps ?? 0
                            repsText = "\(max(current - 1, 0))"
                        },
                        plusAction: {
                            let current = parsedReps ?? 0
                            repsText = "\(current + 1)"
                        }
                    )
                    .padding(.trailing, 14)

                    Divider()
                        .frame(height: 66)

                    valueEditor(
                        value: $weightText,
                        unit: selectedUnit.symbol,
                        color: Theme.terracotta,
                        focus: .weight,
                        minusAction: {
                            let step = selectedUnit == .kilograms ? 2.5 : 5.0
                            let current = parsedWeight ?? 0
                            weightText = formatWeight(max(current - step, 0))
                        },
                        plusAction: {
                            let step = selectedUnit == .kilograms ? 2.5 : 5.0
                            let current = parsedWeight ?? 0
                            weightText = formatWeight(current + step)
                        }
                    )
                    .padding(.leading, 14)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Picker("Unit", selection: $selectedUnit) {
                    ForEach(TrackerWeightUnit.allCases) { unit in
                        Text(unit.symbol.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    guard let reps = parsedReps, let value = parsedWeight else { return }
                    let kg = selectedUnit.toKilograms(value)
                    let lb = kg * 2.2046226218
                    let recordedUnit = selectedUnit == .kilograms ? "kilograms" : "pounds"
                    onSave(reps, kg, lb, recordedUnit)
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .onAppear {
                selectedUnit = initialUnit
                let reps = initialRecord?.reps ?? 10
                let weightInKg = initialRecord?.weight ?? initialUnit.toKilograms(20)
                repsText = "\(reps)"
                weightText = formatWeight(selectedUnit.toDisplay(weightInKg))
            }
        }
    }

    @ViewBuilder
    private func valueEditor(
        value: Binding<String>,
        unit: String,
        color: Color,
        focus: FocusedField,
        minusAction: @escaping () -> Void,
        plusAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Button(action: minusAction) {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Button(action: plusAction) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            TextField("0", text: value)
                .keyboardType(focus == .reps ? .numberPad : .decimalPad)
                .focused($focusedField, equals: focus)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 84)
                .textFieldStyle(.plain)
                .padding(.horizontal, 8)
            Text(unit)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatWeight(_ value: Double) -> String {
        if value == floor(value) { return String(Int(value)) }
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

private enum PendingDeleteMode {
    case store(recordID: UUID)
}

private struct PendingDelete: Identifiable {
    let id: UUID
    let mode: PendingDeleteMode
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

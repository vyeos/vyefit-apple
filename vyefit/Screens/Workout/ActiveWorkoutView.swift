//
//  ActiveWorkoutView.swift
//  vyefit
//
//  Exercise records tracker with history, editing, and plate keyboard.
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
        self == .kilograms ? [25, 20, 15, 10, 5, 2.5] : [45, 35, 25, 10, 5, 2.5]
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
            .presentationDetents([.height(640)])
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
            VStack(spacing: 18) {
                HStack(spacing: 10) {
                    HistoryModePill(title: "Sets", icon: "list.bullet", isActive: true)
                    HistoryModePill(title: "Analyze", icon: "chart.line.uptrend.xyaxis", isActive: false)
                    HistoryModePill(title: "1RM", icon: "gauge.with.needle", isActive: false)
                }

                ForEach(groupedRecords, id: \.0) { day, records in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Text(dayTitle(day))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.white.opacity(0.35))
                                        .frame(width: 18, alignment: .leading)

                                    Text(record.recordedAt.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.white.opacity(0.7))

                                    Spacer()

                                    Text("\(record.reps ?? 0) rep")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color(red: 0.12, green: 0.85, blue: 0.46))

                                    Text("\(formatWeight(unit.toDisplay(record.weight ?? 0))) \(unit.symbol)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color(red: 1.0, green: 0.58, blue: 0.20))
                                        .frame(width: 110, alignment: .trailing)

                                    Button {
                                        onEditRecord(record)
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color.white.opacity(0.5))
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
                                    Divider().background(Color.white.opacity(0.08))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .background(Color(red: 0.10, green: 0.10, blue: 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(16)
        }
        .background(Color.black)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onAddRecord()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.09, green: 0.86, blue: 0.42))
                        .frame(width: 84, height: 84)
                    Image(systemName: "plus")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 8)
                .padding(.top, 6)
            }
            .background(Color.black.opacity(0.95))
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

private struct HistoryModePill: View {
    let title: String
    let icon: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(isActive ? Color.black : Color.white.opacity(0.85))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isActive ? Color.white : Color.white.opacity(0.16))
        .clipShape(Capsule())
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
    @State private var noteText: String = ""
    @State private var plateCounts: [Double: Int] = [:]
    @FocusState private var focusedField: FocusedField?

    private enum FocusedField {
        case reps
        case weight
        case barbell
        case note
    }

    var parsedReps: Int? {
        Int(repsText)
    }

    var parsedWeight: Double? {
        Double(weightText)
    }

    var computedTotalInUnit: Double {
        let bar = Double(barbellText) ?? selectedUnit.defaultBarbell
        let perSide = selectedUnit.plateSizes.reduce(0.0) { sum, plate in
            sum + (Double(plateCounts[plate] ?? 0) * plate)
        }
        return bar + (2 * perSide)
    }

    var isValid: Bool {
        guard let reps = parsedReps, reps > 0 else { return false }
        guard let weight = parsedWeight, weight >= 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 46, height: 5)

                HStack(spacing: 18) {
                    metricHeader(
                        value: parsedReps.map(String.init) ?? "0",
                        unit: "rep",
                        color: Color(red: 0.12, green: 0.85, blue: 0.46),
                        minusAction: {
                            let current = parsedReps ?? 0
                            repsText = "\(max(current - 1, 0))"
                        },
                        plusAction: {
                            let current = parsedReps ?? 0
                            repsText = "\(current + 1)"
                        }
                    )

                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: 70)

                    metricHeader(
                        value: formatWeight(parsedWeight ?? 0),
                        unit: selectedUnit.symbol,
                        color: .white,
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
                }

                HStack(spacing: 10) {
                    TextField("Reps", text: $repsText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .reps)
                        .textFieldStyle(.roundedBorder)

                    TextField("Weight (\(selectedUnit.symbol))", text: $weightText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 8) {
                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(TrackerWeightUnit.allCases) { unit in
                            Text(unit.symbol.uppercased()).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Barbell")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.72))
                        TextField("", text: $barbellText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .barbell)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                        Text(selectedUnit.symbol.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.55))
                        Spacer()
                        Text("Total: \(formatWeight(computedTotalInUnit)) \(selectedUnit.symbol)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 0.12, green: 0.85, blue: 0.46))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedUnit.plateSizes, id: \.self) { plate in
                                VStack(spacing: 10) {
                                    Button {
                                        plateCounts[plate] = max((plateCounts[plate] ?? 0) + 1, 0)
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.white.opacity(0.9))
                                    }

                                    Text(formatWeight(plate))
                                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                    Text(selectedUnit.symbol.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.white.opacity(0.45))

                                    Text("\(plateCounts[plate] ?? 0)")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.black.opacity(0.35))
                                        .clipShape(Circle())

                                    Button {
                                        plateCounts[plate] = max((plateCounts[plate] ?? 0) - 1, 0)
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.white.opacity(0.9))
                                    }
                                }
                                .frame(width: 72, height: 168)
                                .background(Color.white.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Label("Plates", systemImage: "circle.grid.3x3.fill")
                        Label(selectedUnit.symbol.uppercased(), systemImage: "scalemass")
                        Label("Now", systemImage: "calendar")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))

                    HStack(spacing: 10) {
                        TextField("Add note", text: $noteText)
                            .keyboardType(.default)
                            .focused($focusedField, equals: .note)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            weightText = formatWeight(computedTotalInUnit)
                            focusedField = nil
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 78, height: 42)
                                .background(Color(red: 0.09, green: 0.86, blue: 0.42))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    guard let reps = parsedReps, let weightValue = parsedWeight else { return }
                    onSave(reps, selectedUnit.toKilograms(weightValue))
                    dismiss()
                } label: {
                    Text("Save Record")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? Color(red: 0.09, green: 0.86, blue: 0.42) : Color.white.opacity(0.25))
                        .clipShape(Capsule())
                }
                .disabled(!isValid)

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color.black)
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
                barbellText = formatWeight(selectedUnit.defaultBarbell)
                selectedUnit.plateSizes.forEach { plateCounts[$0] = 0 }
            }
        }
    }

    @ViewBuilder
    private func metricHeader(
        value: String,
        unit: String,
        color: Color,
        minusAction: @escaping () -> Void,
        plusAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Button(action: minusAction) {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            Button(action: plusAction) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            Text(value)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(unit)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.72))
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

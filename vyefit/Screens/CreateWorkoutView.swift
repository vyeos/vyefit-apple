//
//  CreateWorkoutView.swift
//  vyefit
//
//  Sheet for creating a new workout with exercise selection and ordering.
//

import SwiftUI

// MARK: - Sort Mode

enum ExerciseSortMode: String, CaseIterable {
    case custom = "Custom"
    case name = "Name"
    case recent = "Recent"
}

// MARK: - Create Workout View

struct CreateWorkoutView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var workoutName: String
    @State private var selectedExercises: [CatalogExercise]
    @State private var showExercisePicker = false
    @State private var sortMode: ExerciseSortMode = .custom
    @State private var selectedIcon: String

    init(template: MockWorkout? = nil) {
        if let t = template {
            _workoutName = State(initialValue: t.name)
            _selectedIcon = State(initialValue: t.icon)
            _selectedExercises = State(initialValue: t.exercises.map { mock in
                ExerciseCatalog.all.first { $0.name == mock.name }
                    ?? CatalogExercise(name: mock.name, muscleGroup: mock.muscleGroup, icon: mock.icon)
            })
        } else {
            _workoutName = State(initialValue: "")
            _selectedIcon = State(initialValue: "figure.strengthtraining.traditional")
            _selectedExercises = State(initialValue: [])
        }
    }

    private let iconOptions = [
        "figure.strengthtraining.traditional",
        "figure.strengthtraining.functional",
        "figure.core.training",
        "figure.walk",
        "figure.run",
        "figure.mixed.cardio",
        "dumbbell.fill",
        "flame.fill",
    ]

    private var displayedExercises: [CatalogExercise] {
        switch sortMode {
        case .custom: return selectedExercises
        case .name: return selectedExercises.sorted { $0.name < $1.name }
        case .recent: return selectedExercises.sorted {
            ($0.lastPerformed ?? .distantPast) > ($1.lastPerformed ?? .distantPast)
        }
        }
    }

    private var canSave: Bool {
        !workoutName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedExercises.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        nameSection
                        iconSection
                        exercisesSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cream, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWorkout() }
                        .disabled(!canSave)
                        .foregroundStyle(canSave ? Theme.terracotta : Theme.stone)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView(selectedExercises: $selectedExercises)
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Workout Name")
            TextField("e.g. Push Day", text: $workoutName)
                .font(.system(size: 16, design: .serif))
                .padding(14)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Icon")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedIcon = icon }
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundStyle(selectedIcon == icon ? .white : Theme.textSecondary)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Theme.terracotta : Theme.cream)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionHeader("Exercises (\(selectedExercises.count))")
                Spacer()
                if selectedExercises.count > 1 {
                    Menu {
                        ForEach(ExerciseSortMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation { sortMode = mode }
                            } label: {
                                HStack {
                                    Text(mode.rawValue)
                                    if mode == sortMode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 10))
                            Text(sortMode.rawValue)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                        }
                        .foregroundStyle(Theme.terracotta)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.terracotta.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }

            if selectedExercises.isEmpty {
                addExercisesPlaceholder
            } else {
                exerciseList
                addMoreButton
            }
        }
    }

    private var addExercisesPlaceholder: some View {
        Button { showExercisePicker = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add Exercises")
                    .font(.system(size: 14, weight: .medium, design: .serif))
            }
            .foregroundStyle(Theme.terracotta)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.terracotta.opacity(0.3),
                                  style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
    }

    private var exerciseList: some View {
        Group {
            if sortMode == .custom {
                List {
                    ForEach(selectedExercises) { exercise in
                        exerciseRow(exercise)
                    }
                    .onMove { from, to in
                        selectedExercises.move(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { offsets in
                        selectedExercises.remove(atOffsets: offsets)
                    }
                    .listRowBackground(Theme.cream)
                    .listRowSeparatorTint(Theme.sand)
                    .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
                .frame(height: CGFloat(selectedExercises.count) * 52)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(displayedExercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseRow(exercise)

                        if index < displayedExercises.count - 1 {
                            Divider()
                                .padding(.leading, 54)
                        }
                    }
                }
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func exerciseRow(_ exercise: CatalogExercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.icon)
                .font(.system(size: 13))
                .foregroundStyle(Theme.sage)
                .frame(width: 26, height: 26)
                .background(Theme.sage.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(exercise.muscleGroup)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            if let date = exercise.lastPerformed {
                Text(SampleData.relativeDateString(date))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.stone)
            }

            if sortMode != .custom {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedExercises.removeAll { $0.id == exercise.id }
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.stone.opacity(0.6))
                }
            }
        }
        .padding(.vertical, sortMode == .custom ? 2 : 10)
        .padding(.horizontal, sortMode == .custom ? 0 : 14)
    }

    private var addMoreButton: some View {
        Button { showExercisePicker = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                Text("Add More")
                    .font(.system(size: 13, weight: .medium, design: .serif))
            }
            .foregroundStyle(Theme.terracotta)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium, design: .serif))
            .foregroundStyle(Theme.textSecondary)
    }

    private func saveWorkout() {
        let workout = UserWorkout(
            id: UUID(),
            name: workoutName.trimmingCharacters(in: .whitespaces),
            exercises: sortMode == .custom ? selectedExercises : displayedExercises,
            icon: selectedIcon,
            createdAt: Date()
        )
        store.add(workout)
        dismiss()
    }
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    @Binding var selectedExercises: [CatalogExercise]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showCustomSheet = false
    @State private var customName = ""
    @State private var customMuscleGroup = "Chest"

    private var filteredExercises: [CatalogExercise] {
        guard !searchText.isEmpty else { return ExerciseCatalog.all }
        return ExerciseCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedExercises: [(String, [CatalogExercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { $0.muscleGroup }
        return ExerciseCatalog.muscleGroups.compactMap { group in
            guard let exercises = grouped[group], !exercises.isEmpty else { return nil }
            return (group, exercises)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        searchBar

                        if filteredExercises.isEmpty {
                            noResultsView
                        } else {
                            exerciseGroups
                            createCustomButton
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cream, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.terracotta)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showCustomSheet) {
                CustomExerciseSheet(
                    name: $customName,
                    muscleGroup: $customMuscleGroup
                ) { exercise in
                    selectedExercises.append(exercise)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Theme.stone)
            TextField("Search exercises", text: $searchText)
                .font(.system(size: 15))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.stone)
                }
            }
        }
        .padding(12)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(Theme.stone.opacity(0.5))

            Text("No exercises found")
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Theme.textSecondary)

            Button {
                customName = searchText
                showCustomSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Create \"\(searchText)\"")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                }
                .foregroundStyle(Theme.terracotta)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Theme.terracotta.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var exerciseGroups: some View {
        ForEach(groupedExercises, id: \.0) { group, exercises in
            VStack(alignment: .leading, spacing: 0) {
                Text(group.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(1)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)

                VStack(spacing: 0) {
                    ForEach(exercises) { exercise in
                        Button { toggleSelection(exercise) } label: {
                            exercisePickerRow(exercise)
                        }

                        if exercise.id != exercises.last?.id {
                            Divider()
                                .padding(.leading, 54)
                        }
                    }
                }
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func exercisePickerRow(_ exercise: CatalogExercise) -> some View {
        let selected = selectedExercises.contains(exercise)
        return HStack(spacing: 12) {
            Image(systemName: exercise.icon)
                .font(.system(size: 13))
                .foregroundStyle(Theme.sage)
                .frame(width: 28, height: 28)
                .background(Theme.sage.opacity(0.15))
                .clipShape(Circle())

            Text(exercise.name)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            if let date = exercise.lastPerformed {
                Text(SampleData.relativeDateString(date))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.stone)
            }

            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(selected ? Theme.terracotta : Theme.stone.opacity(0.4))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }

    private var createCustomButton: some View {
        Button {
            customName = ""
            showCustomSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                Text("Create Custom Exercise")
                    .font(.system(size: 14, weight: .medium, design: .serif))
            }
            .foregroundStyle(Theme.terracotta)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func toggleSelection(_ exercise: CatalogExercise) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if let index = selectedExercises.firstIndex(of: exercise) {
                selectedExercises.remove(at: index)
            } else {
                selectedExercises.append(exercise)
            }
        }
    }
}

// MARK: - Custom Exercise Sheet

struct CustomExerciseSheet: View {
    @Binding var name: String
    @Binding var muscleGroup: String
    let onSave: (CatalogExercise) -> Void
    @Environment(\.dismiss) private var dismiss

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercise Name")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundStyle(Theme.textSecondary)
                        TextField("e.g. Cable Lateral Raise", text: $name)
                            .font(.system(size: 16, design: .serif))
                            .padding(14)
                            .background(Theme.cream)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Muscle Group")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundStyle(Theme.textSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(ExerciseCatalog.muscleGroups, id: \.self) { group in
                                Button {
                                    muscleGroup = group
                                } label: {
                                    Text(group)
                                        .font(.system(size: 13, weight: .medium, design: .serif))
                                        .foregroundStyle(muscleGroup == group ? .white : Theme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(muscleGroup == group ? Theme.terracotta : Theme.cream)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cream, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let exercise = CatalogExercise(
                            name: name.trimmingCharacters(in: .whitespaces),
                            muscleGroup: muscleGroup,
                            icon: "figure.strengthtraining.traditional"
                        )
                        onSave(exercise)
                        dismiss()
                    }
                    .disabled(!canSave)
                    .foregroundStyle(canSave ? Theme.terracotta : Theme.stone)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Create Workout") {
    CreateWorkoutView()
        .environment(WorkoutStore())
}

#Preview("Exercise Picker") {
    ExercisePickerView(selectedExercises: .constant([]))
}

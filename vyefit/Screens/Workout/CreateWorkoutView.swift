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
    @State private var selectedWorkoutType: WorkoutType = .traditionalStrengthTraining
    @State private var editMode: EditMode = .inactive
    private let editingId: UUID?

    init(template: WorkoutTemplate? = nil) {
        editingId = nil
        if let t = template {
            _workoutName = State(initialValue: t.name)
            _selectedIcon = State(initialValue: t.icon)
            _selectedWorkoutType = State(initialValue: .traditionalStrengthTraining)
            _selectedExercises = State(initialValue: t.exercises.map { exercise in
                ExerciseCatalog.all.first { $0.name == exercise.name }
                    ?? CatalogExercise(name: exercise.name, muscleGroup: exercise.muscleGroup, icon: exercise.icon)
            })
        } else {
            _workoutName = State(initialValue: "")
            _selectedIcon = State(initialValue: "figure.strengthtraining.traditional")
            _selectedExercises = State(initialValue: [])
            _selectedWorkoutType = State(initialValue: .traditionalStrengthTraining)
        }
    }

    init(editing workout: UserWorkout) {
        editingId = workout.id
        _workoutName = State(initialValue: workout.name)
        _selectedIcon = State(initialValue: workout.icon)
        _selectedExercises = State(initialValue: workout.exercises)
        _selectedWorkoutType = State(initialValue: workout.workoutType)
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
            List {
                Section {
                    TextField("Workout Name", text: $workoutName)
                        .font(.system(size: 16, design: .serif))
                } header: {
                    Text("Workout Name")
                }
                .listRowBackground(Theme.cream)

                Section {
                    NavigationLink {
                        WorkoutTypePickerView(selectedType: $selectedWorkoutType)
                    } label: {
                        HStack {
                            Image(systemName: selectedWorkoutType.icon)
                                .foregroundStyle(Theme.terracotta)
                            Text(selectedWorkoutType.rawValue)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                } header: {
                    Text("Workout Type")
                }
                .listRowBackground(Theme.cream)

                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) { selectedIcon = icon }
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(selectedIcon == icon ? Theme.cream : Theme.textSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? Theme.terracotta : Theme.cream)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Theme.terracotta.opacity(selectedIcon == icon ? 0 : 0.1), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Icon")
                }
                .listRowBackground(Theme.cream)

                Section {
                    if selectedExercises.isEmpty {
                        Button { showExercisePicker = true } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Exercises")
                            }
                            .foregroundStyle(Theme.terracotta)
                        }
                    } else {
                        ForEach(displayedExercises) { exercise in
                            exerciseRow(exercise)
                        }
                        .onMove { from, to in
                            selectedExercises.move(fromOffsets: from, toOffset: to)
                        }
                        .onDelete { offsets in
                            selectedExercises.remove(atOffsets: offsets)
                        }
                        
                        Button { showExercisePicker = true } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add More Exercises")
                            }
                            .foregroundStyle(Theme.terracotta)
                        }
                    }
                } header: {
                    HStack {
                        Text("Exercises (\(selectedExercises.count))")
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
                            }
                        }
                    }
                }
                .listRowBackground(Theme.cream)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .environment(\.editMode, $editMode)
            .onChange(of: sortMode) {
                editMode = sortMode == .custom ? .active : .inactive
            }
            .navigationTitle(editingId != nil ? "Edit Workout" : "New Workout")
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
                    .lineLimit(nil) // Allow multiple lines
                    .fixedSize(horizontal: false, vertical: true)
                Text(exercise.muscleGroup)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            if let date = exercise.lastPerformed {
                Text(relativeDateString(date))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.stone)
            }
            
            // Visual handle for custom sort mode
            if sortMode == .custom {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.stone.opacity(0.5))
            }
            
            // Delete button for non-custom modes (custom mode uses swipe-to-delete)
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
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium, design: .serif))
            .foregroundStyle(Theme.textSecondary)
    }

    private func saveWorkout() {
        let workout = UserWorkout(
            id: editingId ?? UUID(),
            name: workoutName.trimmingCharacters(in: .whitespaces),
            workoutType: selectedWorkoutType,
            exercises: sortMode == .custom ? selectedExercises : displayedExercises,
            icon: selectedIcon,
            createdAt: Date()
        )
        if editingId != nil {
            store.update(workout)
        } else {
            store.add(workout)
        }
        dismiss()
    }
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    @Binding var selectedExercises: [CatalogExercise]
    @Environment(WorkoutStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showCustomSheet = false
    @State private var customName = ""
    @State private var customMuscleGroup = "Chest"

    private var filteredExercises: [CatalogExercise] {
        let all = store.allExercises
        guard !searchText.isEmpty else { return all }
        return all.filter {
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
                    store.addCustomExercise(exercise)
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
                customName = searchText.trimmingCharacters(in: .whitespaces)
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
                Text(relativeDateString(date))
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
            customName = searchText.trimmingCharacters(in: .whitespaces)
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
                                        .foregroundStyle(muscleGroup == group ? Theme.cream : Theme.textPrimary)
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

// MARK: - Workout Type Picker

struct WorkoutTypePickerView: View {
    @Binding var selectedType: WorkoutType
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredTypes: [WorkoutType] {
        if searchText.isEmpty {
            return WorkoutType.allCases
        } else {
            return WorkoutType.allCases.filter {
                $0.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.stone)
                    TextField("Search workout types", text: $searchText)
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
                .padding()

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredTypes) { type in
                            Button {
                                selectedType = type
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: type.icon)
                                        .foregroundStyle(type == selectedType ? Theme.terracotta : Theme.sage)
                                        .frame(width: 24, height: 24)
                                    
                                    Text(type.rawValue)
                                        .font(.system(size: 16))
                                        .foregroundStyle(Theme.textPrimary)
                                    
                                    Spacer()
                                    
                                    if type == selectedType {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Theme.terracotta)
                                    }
                                }
                                .padding()
                                .background(Theme.cream)
                            }
                            
                            if type != filteredTypes.last {
                                Divider()
                                    .padding(.leading, 50)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Workout Type")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cream, for: .navigationBar)
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

//
//  ScheduleDayEditor.swift
//  vyefit
//
//  View for editing a single day's schedule items.
//

import SwiftUI

struct ScheduleDayEditor: View {
    @Environment(WorkoutStore.self) private var workoutStore
    @Bindable var scheduleStore: ScheduleStore
    let scheduleId: UUID
    let day: DayOfWeek
    
    @State private var showingAddSheet = false
    @State private var editingItem: ScheduleItem?
    
    private var schedule: Schedule? {
        scheduleStore.schedules.first { $0.id == scheduleId }
    }
    
    private var scheduleDay: ScheduleDay? {
        schedule?.days.first { $0.day == day }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.rawValue)
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                    
                    if let scheduleDay = scheduleDay {
                        let itemCount = scheduleDay.items.count
                        Text("\(itemCount) activity\(itemCount == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.terracotta)
                }
            }
            .padding(20)
            .background(Theme.cream)
            
            // Items list
            if let scheduleDay = scheduleDay, !scheduleDay.items.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(scheduleDay.items) { item in
                            DayScheduleItemView(
                                item: item,
                                workoutName: scheduleStore.getWorkoutName(for: item, from: workoutStore.workouts),
                                onDelete: {
                                    scheduleStore.removeItem(item.id, from: day, in: scheduleId)
                                },
                                onEdit: {
                                    editingItem = item
                                }
                            )
                        }
                        .onMove { source, destination in
                            scheduleStore.moveItem(in: day, scheduleId: scheduleId, from: source, to: destination)
                        }
                    }
                    .padding(20)
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.stone.opacity(0.5))
                    
                    Text("No activities")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    
                    Text("Tap + to add a workout, run, or rest day")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
        .background(Theme.background)
        .sheet(isPresented: $showingAddSheet) {
            AddScheduleItemSheet(
                scheduleStore: scheduleStore,
                scheduleId: scheduleId,
                day: day,
                workouts: workoutStore.workouts
            )
        }
        .sheet(item: $editingItem) { item in
            EditScheduleItemSheet(
                scheduleStore: scheduleStore,
                scheduleId: scheduleId,
                day: day,
                item: item,
                workouts: workoutStore.workouts
            )
        }
    }
}

// MARK: - Add Schedule Item Sheet

struct AddScheduleItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var scheduleStore: ScheduleStore
    let scheduleId: UUID
    let day: DayOfWeek
    let workouts: [UserWorkout]
    
    @State private var selectedType: ScheduleItemType = .workout
    @State private var selectedWorkout: UserWorkout?
    @State private var selectedRunType: ScheduleRunType = .easy
    @State private var duration: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Activity Type", selection: $selectedType) {
                        ForEach(ScheduleItemType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                switch selectedType {
                case .workout:
                    Section("Workout") {
                        if workouts.isEmpty {
                            Text("No workouts created yet")
                                .foregroundStyle(Theme.textSecondary)
                        } else {
                            Picker("Select Workout", selection: $selectedWorkout) {
                                Text("None")
                                    .tag(nil as UserWorkout?)
                                ForEach(workouts) { workout in
                                    Text(workout.name)
                                        .tag(workout as UserWorkout?)
                                }
                            }
                        }
                    }
                    
                case .run:
                    Section("Run Type") {
                        Picker("Type", selection: $selectedRunType) {
                            ForEach(ScheduleRunType.allCases) { type in
                                Text(type.rawValue)
                                    .tag(type)
                            }
                        }
                    }
                    
                case .rest, .busy:
                    Section("Notes") {
                        TextField("Optional notes", text: $notes)
                    }
                }
                
                if selectedType == .workout || selectedType == .run {
                    Section("Details") {
                        if selectedType == .workout || selectedType == .run {
                            HStack {
                                Text("Duration (min)")
                                Spacer()
                                TextField("0", text: $duration)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                            }
                        }
                        
                        TextField("Notes (optional)", text: $notes)
                    }
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        switch selectedType {
        case .workout:
            return selectedWorkout != nil
        case .run, .rest, .busy:
            return true
        }
    }
    
    private func addItem() {
        let durationValue = Int(duration)
        
        let item: ScheduleItem
        switch selectedType {
        case .workout:
            guard let workout = selectedWorkout else { return }
            item = ScheduleItem.workout(workout.id, duration: durationValue, notes: notes.isEmpty ? nil : notes)
        case .run:
            item = ScheduleItem.run(selectedRunType, duration: durationValue, notes: notes.isEmpty ? nil : notes)
        case .rest:
            item = ScheduleItem.rest(notes: notes.isEmpty ? nil : notes)
        case .busy:
            item = ScheduleItem.busy(notes: notes.isEmpty ? nil : notes)
        }
        
        scheduleStore.addItem(item, to: day, in: scheduleId)
    }
}

// MARK: - Edit Schedule Item Sheet

struct EditScheduleItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var scheduleStore: ScheduleStore
    let scheduleId: UUID
    let day: DayOfWeek
    let item: ScheduleItem
    let workouts: [UserWorkout]
    
    @State private var selectedWorkout: UserWorkout?
    @State private var selectedRunType: ScheduleRunType
    @State private var duration: String
    @State private var notes: String
    
    init(scheduleStore: ScheduleStore, scheduleId: UUID, day: DayOfWeek, item: ScheduleItem, workouts: [UserWorkout]) {
        self.scheduleStore = scheduleStore
        self.scheduleId = scheduleId
        self.day = day
        self.item = item
        self.workouts = workouts
        
        _selectedWorkout = State(initialValue: item.workoutId.flatMap { id in workouts.first { $0.id == id } })
        _selectedRunType = State(initialValue: item.runType ?? .easy)
        _duration = State(initialValue: item.duration.map { String($0) } ?? "")
        _notes = State(initialValue: item.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    HStack {
                        Text("Activity")
                        Spacer()
                        Label(item.type.rawValue, systemImage: item.type.icon)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                switch item.type {
                case .workout:
                    Section("Workout") {
                        if workouts.isEmpty {
                            Text("No workouts created yet")
                                .foregroundStyle(Theme.textSecondary)
                        } else {
                            Picker("Select Workout", selection: $selectedWorkout) {
                                Text("None")
                                    .tag(nil as UserWorkout?)
                                ForEach(workouts) { workout in
                                    Text(workout.name)
                                        .tag(workout as UserWorkout?)
                                }
                            }
                        }
                    }
                    
                case .run:
                    Section("Run Type") {
                        Picker("Type", selection: $selectedRunType) {
                            ForEach(ScheduleRunType.allCases) { type in
                                Text(type.rawValue)
                                    .tag(type)
                            }
                        }
                    }
                    
                case .rest, .busy:
                    EmptyView()
                }
                
                if item.type == .workout || item.type == .run {
                    Section("Details") {
                        if item.type == .workout || item.type == .run {
                            HStack {
                                Text("Duration (min)")
                                Spacer()
                                TextField("0", text: $duration)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                            }
                        }
                        
                        TextField("Notes (optional)", text: $notes)
                    }
                } else {
                    Section("Notes") {
                        TextField("Optional notes", text: $notes)
                    }
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveItem() {
        let durationValue = Int(duration)
        
        let updatedItem: ScheduleItem
        switch item.type {
        case .workout:
            guard let workout = selectedWorkout else { return }
            updatedItem = ScheduleItem(
                id: item.id,
                type: .workout,
                workoutId: workout.id,
                runType: nil,
                notes: notes.isEmpty ? nil : notes,
                duration: durationValue
            )
        case .run:
            updatedItem = ScheduleItem(
                id: item.id,
                type: .run,
                workoutId: nil,
                runType: selectedRunType,
                notes: notes.isEmpty ? nil : notes,
                duration: durationValue
            )
        case .rest:
            updatedItem = ScheduleItem(
                id: item.id,
                type: .rest,
                workoutId: nil,
                runType: nil,
                notes: notes.isEmpty ? nil : notes,
                duration: nil
            )
        case .busy:
            updatedItem = ScheduleItem(
                id: item.id,
                type: .busy,
                workoutId: nil,
                runType: nil,
                notes: notes.isEmpty ? nil : notes,
                duration: nil
            )
        }
        
        scheduleStore.updateItem(updatedItem, in: day, scheduleId: scheduleId)
    }
}

#Preview {
    ScheduleDayEditor(
        scheduleStore: ScheduleStore(),
        scheduleId: UUID(),
        day: .monday
    )
    .environment(WorkoutStore())
}

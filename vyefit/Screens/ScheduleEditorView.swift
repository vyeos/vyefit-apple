//
//  ScheduleEditorView.swift
//  vyefit
//
//  View for creating and editing schedules.
//

import SwiftUI

struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutStore.self) private var workoutStore
    @Bindable var scheduleStore: ScheduleStore
    let editingSchedule: Schedule?
    
    @State private var name: String
    @State private var description: String
    @State private var selectedColor: String
    @State private var selectedDay: DayOfWeek = .monday
    @State private var showDayEditor = false
    @State private var newlyCreatedScheduleId: UUID?
    
    private let colors = [
        "CC7359", "8CA680", "A3C4BC", "6B8E7B", "D4A574",
        "7B9E87", "B8A07A", "9B7B6B", "7A9CC6", "C68C7A"
    ]
    
    init(scheduleStore: ScheduleStore, editingSchedule: Schedule? = nil) {
        self.scheduleStore = scheduleStore
        self.editingSchedule = editingSchedule
        
        _name = State(initialValue: editingSchedule?.name ?? "")
        _description = State(initialValue: editingSchedule?.description ?? "")
        _selectedColor = State(initialValue: editingSchedule?.color ?? "CC7359")
    }
    
    private var scheduleColor: Color {
        Color(hex: selectedColor)
    }
    
    private var isEditing: Bool {
        editingSchedule != nil
    }
    
    private var scheduleDays: [ScheduleDay] {
        if let existing = editingSchedule {
            return existing.days
        }
        if let newId = newlyCreatedScheduleId,
           let schedule = scheduleStore.schedules.first(where: { $0.id == newId }) {
            return schedule.days
        }
        return DayOfWeek.allCases.map { ScheduleDay(day: $0, items: []) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Schedule Details") {
                    TextField("Name", text: $name)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if isEditing || newlyCreatedScheduleId != nil {
                    Section("Weekly Schedule") {
                        ForEach(DayOfWeek.allCases) { day in
                            let daySchedule = scheduleDays.first { $0.day == day }
                            let itemCount = daySchedule?.items.count ?? 0
                            
                            Button {
                                selectedDay = day
                                showDayEditor = true
                            } label: {
                                HStack {
                                    Text(day.shortName)
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(width: 36, alignment: .leading)
                                    
                                    if let daySchedule = daySchedule, !daySchedule.items.isEmpty {
                                        HStack(spacing: 4) {
                                            ForEach(0..<min(daySchedule.items.count, 4), id: \.self) { index in
                                                Circle()
                                                    .fill(colorForItem(daySchedule.items[index]))
                                                    .frame(width: 6, height: 6)
                                            }
                                            if daySchedule.items.count > 4 {
                                                Text("+\(daySchedule.items.count - 4)")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(Theme.textSecondary)
                                            }
                                        }
                                        Spacer()
                                        Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Theme.textSecondary)
                                    } else {
                                        Spacer()
                                        Text("Empty")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Theme.textSecondary.opacity(0.6))
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.stone)
                                }
                            }
                            .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let schedule = editingSchedule {
                                scheduleStore.deleteSchedule(id: schedule.id)
                            }
                            dismiss()
                        } label: {
                            Label("Delete Schedule", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Schedule" : "New Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        // If we created a schedule but are canceling, delete it
                        if let newId = newlyCreatedScheduleId {
                            scheduleStore.deleteSchedule(id: newId)
                        }
                        dismiss() 
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Continue") {
                        if isEditing {
                            saveSchedule()
                            dismiss()
                        } else {
                            // Create schedule first, then allow editing days
                            if newlyCreatedScheduleId == nil {
                                createInitialSchedule()
                            } else {
                                dismiss()
                            }
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showDayEditor) {
                if let scheduleId = editingSchedule?.id ?? newlyCreatedScheduleId {
                    ScheduleDayEditor(
                        scheduleStore: scheduleStore,
                        scheduleId: scheduleId,
                        day: selectedDay
                    )
                }
            }
        }
    }
    
    private func colorForItem(_ item: ScheduleItem) -> Color {
        switch item.type {
        case .workout:
            return Theme.terracotta
        case .run:
            return Theme.sage
        case .rest:
            return Color.blue.opacity(0.6)
        case .busy:
            return Color.orange.opacity(0.7)
        }
    }
    
    private func createInitialSchedule() {
        let descriptionValue = description.isEmpty ? nil : description
        let newSchedule = Schedule.createEmpty(name: name, color: selectedColor)
        var schedule = newSchedule
        schedule.description = descriptionValue
        scheduleStore.addSchedule(schedule)
        newlyCreatedScheduleId = schedule.id
    }
    
    private func saveSchedule() {
        let descriptionValue = description.isEmpty ? nil : description
        
        if let existingSchedule = editingSchedule {
            var updatedSchedule = existingSchedule
            updatedSchedule.name = name
            updatedSchedule.description = descriptionValue
            updatedSchedule.color = selectedColor
            updatedSchedule.updatedAt = Date()
            scheduleStore.updateSchedule(updatedSchedule)
        }
    }
}

// MARK: - Schedule Day Editor

struct ScheduleDayEditor: View {
    @Environment(\.dismiss) private var dismiss
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
    
    private var hasRestOrBusy: Bool {
        scheduleDay?.items.contains { $0.type == .rest || $0.type == .busy } ?? false
    }
    
    var body: some View {
        NavigationStack {
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
                    
                    if !hasRestOrBusy {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.terracotta)
                        }
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
            .navigationTitle("Schedule \(day.shortName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddScheduleItemSheet(
                    scheduleStore: scheduleStore,
                    scheduleId: scheduleId,
                    day: day,
                    workouts: workoutStore.workouts,
                    hasRestOrBusy: hasRestOrBusy
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
}

// MARK: - Add Schedule Item Sheet

struct AddScheduleItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var scheduleStore: ScheduleStore
    let scheduleId: UUID
    let day: DayOfWeek
    let workouts: [UserWorkout]
    let hasRestOrBusy: Bool
    
    @State private var selectedType: ScheduleItemType = .workout
    @State private var selectedWorkout: UserWorkout?
    @State private var selectedRunType: ScheduleRunType = .easy
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
                    EmptyView()
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }
                
                if selectedType == .rest || selectedType == .busy {
                    Section {
                        Text("Adding \(selectedType.rawValue) will prevent other activities on this day.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
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
        let notesValue = notes.isEmpty ? nil : notes
        
        let item: ScheduleItem
        switch selectedType {
        case .workout:
            guard let workout = selectedWorkout else { return }
            item = ScheduleItem.workout(workout.id, notes: notesValue)
        case .run:
            item = ScheduleItem.run(selectedRunType, notes: notesValue)
        case .rest:
            item = ScheduleItem.rest(notes: notesValue)
        case .busy:
            item = ScheduleItem.busy(notes: notesValue)
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
    @State private var notes: String
    
    init(scheduleStore: ScheduleStore, scheduleId: UUID, day: DayOfWeek, item: ScheduleItem, workouts: [UserWorkout]) {
        self.scheduleStore = scheduleStore
        self.scheduleId = scheduleId
        self.day = day
        self.item = item
        self.workouts = workouts
        
        _selectedWorkout = State(initialValue: item.workoutId.flatMap { id in workouts.first { $0.id == id } })
        _selectedRunType = State(initialValue: item.runType ?? .easy)
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
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes)
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
        let notesValue = notes.isEmpty ? nil : notes
        
        let updatedItem: ScheduleItem
        switch item.type {
        case .workout:
            guard let workout = selectedWorkout else { return }
            updatedItem = ScheduleItem(
                id: item.id,
                type: .workout,
                workoutId: workout.id,
                runType: nil,
                notes: notesValue,
                duration: nil
            )
        case .run:
            updatedItem = ScheduleItem(
                id: item.id,
                type: .run,
                workoutId: nil,
                runType: selectedRunType,
                notes: notesValue,
                duration: nil
            )
        case .rest:
            updatedItem = ScheduleItem(
                id: item.id,
                type: .rest,
                workoutId: nil,
                runType: nil,
                notes: notesValue,
                duration: nil
            )
        case .busy:
            updatedItem = ScheduleItem(
                id: item.id,
                type: .busy,
                workoutId: nil,
                runType: nil,
                notes: notesValue,
                duration: nil
            )
        }
        
        scheduleStore.updateItem(updatedItem, in: day, scheduleId: scheduleId)
    }
}

#Preview {
    ScheduleEditorView(scheduleStore: ScheduleStore())
        .environment(WorkoutStore())
}

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
        editingSchedule?.days ?? DayOfWeek.allCases.map { ScheduleDay(day: $0, items: []) }
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
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveSchedule()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showDayEditor) {
                if let schedule = editingSchedule {
                    ScheduleDayEditor(
                        scheduleStore: scheduleStore,
                        scheduleId: schedule.id,
                        day: selectedDay
                    )
                } else {
                    NewScheduleDayEditor(
                        scheduleStore: scheduleStore,
                        name: name,
                        description: description.isEmpty ? nil : description,
                        color: selectedColor,
                        day: selectedDay,
                        onSave: { _ in }
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
    
    private func saveSchedule() {
        let descriptionValue = description.isEmpty ? nil : description
        
        if let existingSchedule = editingSchedule {
            var updatedSchedule = existingSchedule
            updatedSchedule.name = name
            updatedSchedule.description = descriptionValue
            updatedSchedule.color = selectedColor
            updatedSchedule.updatedAt = Date()
            scheduleStore.updateSchedule(updatedSchedule)
        } else {
            let newSchedule = Schedule.createEmpty(name: name, color: selectedColor)
            var schedule = newSchedule
            schedule.description = descriptionValue
            scheduleStore.addSchedule(schedule)
        }
    }
}

// MARK: - New Schedule Day Editor

struct NewScheduleDayEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutStore.self) private var workoutStore
    @Bindable var scheduleStore: ScheduleStore
    let name: String
    let description: String?
    let color: String
    let day: DayOfWeek
    let onSave: (UUID) -> Void
    
    @State private var items: [ScheduleItem] = []
    @State private var showingAddSheet = false
    @State private var editingItem: ScheduleItem?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.rawValue)
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                        
                        let itemCount = items.count
                        Text("\(itemCount) activity\(itemCount == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
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
                
                if !items.isEmpty {
                    List {
                        ForEach(items) { item in
                            DayScheduleItemRow(
                                item: item,
                                workoutName: scheduleStore.getWorkoutName(for: item, from: workoutStore.workouts)
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    items.removeAll { $0.id == item.id }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    editingItem = item
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(Theme.sage)
                            }
                        }
                        .onMove { source, destination in
                            items.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                    .listStyle(.plain)
                } else {
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSchedule()
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddItemToNewScheduleSheet(
                    items: $items,
                    workouts: workoutStore.workouts
                )
            }
            .sheet(item: $editingItem) { item in
                EditItemInNewScheduleSheet(
                    items: $items,
                    item: item,
                    workouts: workoutStore.workouts
                )
            }
        }
    }
    
    private func saveSchedule() {
        var schedule = Schedule.createEmpty(name: name, color: color)
        schedule.description = description
        
        if let dayIndex = schedule.days.firstIndex(where: { $0.day == day }) {
            schedule.days[dayIndex].items = items
        }
        
        scheduleStore.addSchedule(schedule)
        onSave(schedule.id)
        dismiss()
    }
}

// MARK: - Helper Views

struct DayScheduleItemRow: View {
    let item: ScheduleItem
    let workoutName: String?
    
    var body: some View {
        HStack(spacing: 12) {
            let displayInfo = getDisplayInfo()
            
            Image(systemName: displayInfo.icon)
                .font(.system(size: 12))
                .foregroundStyle(displayInfo.color)
                .frame(width: 28, height: 28)
                .background(displayInfo.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayInfo.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                if let subtitle = displayInfo.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func getDisplayInfo() -> (icon: String, title: String, subtitle: String?, color: Color) {
        switch item.type {
        case .workout:
            return (
                icon: "dumbbell.fill",
                title: workoutName ?? "Workout",
                subtitle: item.duration.map { "\($0) min" },
                color: Theme.terracotta
            )
        case .run:
            return (
                icon: item.runType?.icon ?? "figure.run",
                title: item.runType?.rawValue ?? "Run",
                subtitle: item.duration.map { "\($0) min" } ?? item.runType?.description,
                color: Theme.sage
            )
        case .rest:
            return (
                icon: "bed.double.fill",
                title: "Rest Day",
                subtitle: item.notes,
                color: Color.blue.opacity(0.6)
            )
        case .busy:
            return (
                icon: "briefcase.fill",
                title: "Busy",
                subtitle: item.notes,
                color: Color.orange.opacity(0.7)
            )
        }
    }
}

struct AddItemToNewScheduleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var items: [ScheduleItem]
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
                        HStack {
                            Text("Duration (min)")
                            Spacer()
                            TextField("0", text: $duration)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
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
        let notesValue = notes.isEmpty ? nil : notes
        
        let item: ScheduleItem
        switch selectedType {
        case .workout:
            guard let workout = selectedWorkout else { return }
            item = ScheduleItem.workout(workout.id, duration: durationValue, notes: notesValue)
        case .run:
            item = ScheduleItem.run(selectedRunType, duration: durationValue, notes: notesValue)
        case .rest:
            item = ScheduleItem.rest(notes: notesValue)
        case .busy:
            item = ScheduleItem.busy(notes: notesValue)
        }
        
        items.append(item)
    }
}

struct EditItemInNewScheduleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var items: [ScheduleItem]
    let item: ScheduleItem
    let workouts: [UserWorkout]
    
    @State private var selectedWorkout: UserWorkout?
    @State private var selectedRunType: ScheduleRunType
    @State private var duration: String
    @State private var notes: String
    
    init(items: Binding<[ScheduleItem]>, item: ScheduleItem, workouts: [UserWorkout]) {
        self._items = items
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
                        HStack {
                            Text("Duration (min)")
                            Spacer()
                            TextField("0", text: $duration)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
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
                duration: durationValue
            )
        case .run:
            updatedItem = ScheduleItem(
                id: item.id,
                type: .run,
                workoutId: nil,
                runType: selectedRunType,
                notes: notesValue,
                duration: durationValue
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
        
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = updatedItem
        }
    }
}

#Preview {
    ScheduleEditorView(scheduleStore: ScheduleStore())
        .environment(WorkoutStore())
}

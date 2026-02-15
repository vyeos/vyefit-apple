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
    @State private var editingDay: DayOfWeek?
    @State private var draftDays: [ScheduleDay]
    
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
        _draftDays = State(initialValue: editingSchedule?.days ?? DayOfWeek.allCases.map { ScheduleDay(day: $0, items: []) })
    }
    
    private var scheduleColor: Color {
        Color(hex: selectedColor)
    }
    
    private var isEditing: Bool {
        editingSchedule != nil
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
                                            .foregroundStyle(Theme.cream)
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
                        let daySchedule = draftDays.first { $0.day == day }
                        
                        Button {
                            editingDay = day
                        } label: {
                            HStack {
                                Text(day.shortName)
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(width: 40, alignment: .leading)
                                
                                if let daySchedule = daySchedule, !daySchedule.items.isEmpty {
                                    // Show first 2 activities with icon and name
                                    HStack(spacing: 8) {
                                        ForEach(daySchedule.items.prefix(2)) { item in
                                            let displayInfo = getDisplayInfo(for: item)
                                            HStack(spacing: 4) {
                                                Image(systemName: displayInfo.icon)
                                                    .font(.system(size: 10))
                                                Text(displayInfo.title)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .lineLimit(1)
                                            }
                                            .foregroundStyle(displayInfo.color)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(displayInfo.color.opacity(0.12))
                                            .clipShape(Capsule())
                                        }
                                        
                                        if daySchedule.items.count > 2 {
                                            Text("+\(daySchedule.items.count - 2)")
                                                .font(.system(size: 11))
                                                .foregroundStyle(Theme.textSecondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Theme.sand.opacity(0.3))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Spacer()
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
                        if isEditing {
                            saveSchedule()
                        } else {
                            createSchedule()
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(item: $editingDay) { day in
                DraftDayEditor(
                    day: day,
                    items: draftDays.first { $0.day == day }?.items ?? [],
                    workouts: workoutStore.workouts,
                    onSave: { updatedItems in
                        if let index = draftDays.firstIndex(where: { $0.day == day }) {
                            draftDays[index].items = updatedItems
                        }
                    }
                )
            }
        }
    }
    
    private func getDisplayInfo(for item: ScheduleItem) -> (icon: String, title: String, color: Color) {
        switch item.type {
        case .workout:
            if let workoutId = item.workoutId,
               let workout = workoutStore.workouts.first(where: { $0.id == workoutId }) {
                return (icon: "dumbbell.fill", title: workout.name, color: Theme.terracotta)
            }
            return (icon: "dumbbell.fill", title: "Workout", color: Theme.terracotta)
        case .run:
            if let runType = item.runType {
                return (icon: runType.icon, title: runType.rawValue, color: Theme.sage)
            }
            return (icon: "figure.run", title: "Run", color: Theme.sage)
        case .rest:
            return (icon: "bed.double.fill", title: "Rest Day", color: Theme.restDay)
        case .busy:
            return (icon: "briefcase.fill", title: "Busy", color: Theme.busyDay)
        }
    }
    
    private func createSchedule() {
        let descriptionValue = description.isEmpty ? nil : description
        var schedule = Schedule.createEmpty(name: name, color: selectedColor)
        schedule.description = descriptionValue
        schedule.days = draftDays
        scheduleStore.addSchedule(schedule)
    }
    
    private func saveSchedule() {
        let descriptionValue = description.isEmpty ? nil : description
        
        if let existingSchedule = editingSchedule {
            var updatedSchedule = existingSchedule
            updatedSchedule.name = name
            updatedSchedule.description = descriptionValue
            updatedSchedule.color = selectedColor
            updatedSchedule.days = draftDays
            updatedSchedule.updatedAt = Date()
            scheduleStore.updateSchedule(updatedSchedule)
        }
    }
}

// MARK: - Draft Day Editor

struct DraftDayEditor: View {
    @Environment(\.dismiss) private var dismiss
    let day: DayOfWeek
    let workouts: [UserWorkout]
    let onSave: ([ScheduleItem]) -> Void
    
    @State var items: [ScheduleItem]
    @State private var showingAddSheet = false
    @State private var editingItem: ScheduleItem?
    
    init(day: DayOfWeek, items: [ScheduleItem], workouts: [UserWorkout], onSave: @escaping ([ScheduleItem]) -> Void) {
        self.day = day
        self.workouts = workouts
        self.onSave = onSave
        _items = State(initialValue: items)
    }
    
    private var hasRestOrBusy: Bool {
        items.contains { $0.type == .rest || $0.type == .busy }
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
                        
                        let itemCount = items.count
                        Text("\(itemCount) activity\(itemCount == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
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
                if !items.isEmpty {
                    List {
                        ForEach(items) { item in
                            DraftDayItemRow(
                                item: item,
                                workoutName: getWorkoutName(for: item)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(items)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddDraftItemSheet(
                    items: $items,
                    workouts: workouts,
                    hasRestOrBusy: hasRestOrBusy
                )
            }
            .sheet(item: $editingItem) { item in
                EditDraftItemSheet(
                    items: $items,
                    item: item,
                    workouts: workouts
                )
            }
        }
    }
    
    private func getWorkoutName(for item: ScheduleItem) -> String? {
        guard item.type == .workout, let workoutId = item.workoutId else { return nil }
        return workouts.first { $0.id == workoutId }?.name
    }
}

// MARK: - Draft Day Item Row

struct DraftDayItemRow: View {
    let item: ScheduleItem
    let workoutName: String?
    
    private var displayInfo: (icon: String, title: String, color: Color) {
        switch item.type {
        case .workout:
            return (icon: "dumbbell.fill", title: workoutName ?? "Workout", color: Theme.terracotta)
        case .run:
            return (icon: item.runType?.icon ?? "figure.run", title: item.runType?.rawValue ?? "Run", color: Theme.sage)
        case .rest:
            return (icon: "bed.double.fill", title: "Rest Day", color: Theme.restDay)
        case .busy:
            return (icon: "briefcase.fill", title: "Busy", color: Theme.busyDay)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: displayInfo.icon)
                .font(.system(size: 12))
                .foregroundStyle(displayInfo.color)
                .frame(width: 28, height: 28)
                .background(displayInfo.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(displayInfo.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            if let notes = item.notes, !notes.isEmpty {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Draft Item Sheet

struct AddDraftItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var items: [ScheduleItem]
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
        
        // If adding rest/busy, clear other items first
        if selectedType == .rest || selectedType == .busy {
            items.removeAll()
        }
        
        items.append(item)
    }
}

// MARK: - Edit Draft Item Sheet

struct EditDraftItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var items: [ScheduleItem]
    let item: ScheduleItem
    let workouts: [UserWorkout]
    
    @State private var selectedType: ScheduleItemType
    @State private var selectedWorkout: UserWorkout?
    @State private var selectedRunType: ScheduleRunType
    @State private var notes: String
    
    init(items: Binding<[ScheduleItem]>, item: ScheduleItem, workouts: [UserWorkout]) {
        self._items = items
        self.item = item
        self.workouts = workouts
        
        _selectedType = State(initialValue: item.type)
        _selectedWorkout = State(initialValue: item.workoutId.flatMap { id in workouts.first { $0.id == id } })
        _selectedRunType = State(initialValue: item.runType ?? .easy)
        _notes = State(initialValue: item.notes ?? "")
    }
    
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
                        Text("Changing to \(selectedType.rawValue) will remove all other activities from this day.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
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
    
    private func saveItem() {
        let notesValue = notes.isEmpty ? nil : notes
        
        let updatedItem: ScheduleItem
        switch selectedType {
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
        
        // If changing to rest/busy, remove all other items first
        if selectedType == .rest || selectedType == .busy {
            items.removeAll { $0.id != item.id }
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

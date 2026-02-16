//
//  ScheduleStore.swift
//  vyefit
//
//  Observable store for managing schedules and schedule settings.
//

import SwiftUI

@Observable
class ScheduleStore {
    static let shared = ScheduleStore()
    
    var schedules: [Schedule] = []
    var repeatMode: ScheduleRepeatMode = .weekly
    var currentScheduleIndex: Int = 0
    var weekStartDay: DayOfWeek = .monday
    var notificationsEnabled: Bool = true
    var selectedDate: Date
    var isEditing: Bool = false
    var showCreateSheet: Bool = false
    var showSettingsSheet: Bool = false
    
    private let lastWeekStartKey = "scheduleLastWeekStart"
    
    init() {
        self.selectedDate = Date()
        loadSettings()
        ensureNewWeekScheduleIfNeeded()
    }
    
    // MARK: - Computed Properties
    
    var currentSchedule: Schedule? {
        let active = activeSchedules
        guard !active.isEmpty else { return nil }
        
        switch repeatMode {
        case .weekly, .newEachWeek:
            return active.first
        case .cyclic:
            let index = currentScheduleIndex % active.count
            return active[index]
        }
    }
    
    var allSchedules: [Schedule] {
        schedules.sorted { $0.order < $1.order }
    }
    
    var activeSchedules: [Schedule] {
        schedules.filter { $0.isActive }.sorted { $0.order < $1.order }
    }
    
    var todaySchedule: ScheduleDay? {
        guard let schedule = currentSchedule else { return nil }
        let today = DayOfWeek.from(date: selectedDate)
        return schedule.days.first { $0.day == today }
    }
    
    var currentWeekProgress: (completed: Int, total: Int) {
        guard let schedule = currentSchedule else { return (0, 0) }
        let today = DayOfWeek.from(date: Date())
        let todayIndex = today.index
        
        var completed = 0
        var total = 0
        
        for (index, day) in schedule.days.enumerated() {
            if index <= todayIndex {
                total += day.items.count
                if index < todayIndex {
                    completed += day.items.count
                }
            }
        }
        
        return (completed, max(total, 1))
    }
    
    // MARK: - Schedule Management
    
    func addSchedule(_ schedule: Schedule) {
        var newSchedule = schedule
        newSchedule.order = schedules.count
        if schedules.isEmpty {
            newSchedule.isActive = true
        }
        schedules.append(newSchedule)
        saveSettings()
    }
    
    func updateSchedule(_ schedule: Schedule) {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        var updated = schedule
        updated.updatedAt = Date()
        schedules[index] = updated
        saveSettings()
    }
    
    func deleteSchedule(id: UUID) {
        schedules.removeAll { $0.id == id }
        for (index, _) in schedules.enumerated() {
            schedules[index].order = index
        }
        saveSettings()
    }
    
    func activateSchedule(id: UUID) {
        switch repeatMode {
        case .weekly, .newEachWeek:
            for index in schedules.indices {
                schedules[index].isActive = (schedules[index].id == id)
            }
        case .cyclic:
            if let index = schedules.firstIndex(where: { $0.id == id }) {
                schedules[index].isActive.toggle()
                reorderActiveSchedules()
            }
        }
        saveSettings()
    }
    
    func deactivateSchedule(id: UUID) {
        if let index = schedules.firstIndex(where: { $0.id == id }) {
            schedules[index].isActive = false
            reorderActiveSchedules()
            saveSettings()
        }
    }
    
    func reorderSchedules(from source: IndexSet, to destination: Int) {
        schedules.move(fromOffsets: source, toOffset: destination)
        for (index, _) in schedules.enumerated() {
            schedules[index].order = index
        }
        saveSettings()
    }
    
    private func reorderActiveSchedules() {
        let active = schedules.filter { $0.isActive }.sorted { $0.order < $1.order }
        for (newOrder, schedule) in active.enumerated() {
            if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
                schedules[index].order = newOrder
            }
        }
    }
    
    func moveToNextSchedule() {
        let active = activeSchedules
        guard !active.isEmpty else { return }
        currentScheduleIndex = (currentScheduleIndex + 1) % active.count
        saveSettings()
    }
    
    // MARK: - Day Item Management
    
    func addItem(_ item: ScheduleItem, to day: DayOfWeek, in scheduleId: UUID) {
        guard let scheduleIndex = schedules.firstIndex(where: { $0.id == scheduleId }) else { return }
        guard let dayIndex = schedules[scheduleIndex].days.firstIndex(where: { $0.day == day }) else { return }
        
        schedules[scheduleIndex].days[dayIndex].items.append(item)
        schedules[scheduleIndex].updatedAt = Date()
        saveSettings()
    }
    
    func removeItem(_ itemId: UUID, from day: DayOfWeek, in scheduleId: UUID) {
        guard let scheduleIndex = schedules.firstIndex(where: { $0.id == scheduleId }) else { return }
        guard let dayIndex = schedules[scheduleIndex].days.firstIndex(where: { $0.day == day }) else { return }
        
        schedules[scheduleIndex].days[dayIndex].items.removeAll { $0.id == itemId }
        schedules[scheduleIndex].updatedAt = Date()
        saveSettings()
    }
    
    func updateItem(_ item: ScheduleItem, in day: DayOfWeek, scheduleId: UUID) {
        guard let scheduleIndex = schedules.firstIndex(where: { $0.id == scheduleId }) else { return }
        guard let dayIndex = schedules[scheduleIndex].days.firstIndex(where: { $0.day == day }) else { return }
        guard let itemIndex = schedules[scheduleIndex].days[dayIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        
        schedules[scheduleIndex].days[dayIndex].items[itemIndex] = item
        schedules[scheduleIndex].updatedAt = Date()
        saveSettings()
    }
    
    func moveItem(in day: DayOfWeek, scheduleId: UUID, from source: IndexSet, to destination: Int) {
        guard let scheduleIndex = schedules.firstIndex(where: { $0.id == scheduleId }) else { return }
        guard let dayIndex = schedules[scheduleIndex].days.firstIndex(where: { $0.day == day }) else { return }
        
        schedules[scheduleIndex].days[dayIndex].items.move(fromOffsets: source, toOffset: destination)
        schedules[scheduleIndex].updatedAt = Date()
        saveSettings()
    }
    
    // MARK: - Preset Generation
    
    func createScheduleFromPreset(_ preset: SchedulePreset, workouts: [UserWorkout]) {
        if let schedule = preset.generate(workouts: workouts) {
            addSchedule(schedule)
        }
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        let settings = ScheduleSettings(
            repeatMode: repeatMode,
            schedules: schedules,
            currentScheduleIndex: currentScheduleIndex,
            weekStartDay: weekStartDay,
            notificationsEnabled: notificationsEnabled
        )
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "scheduleSettings")
        }
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: "scheduleSettings") else { return }
        if let decoded = try? JSONDecoder().decode(ScheduleSettings.self, from: data) {
            schedules = decoded.schedules
            repeatMode = decoded.repeatMode
            currentScheduleIndex = decoded.currentScheduleIndex
            weekStartDay = decoded.weekStartDay
            notificationsEnabled = decoded.notificationsEnabled
        }
    }

    // MARK: - New Each Week
    
    private func ensureNewWeekScheduleIfNeeded() {
        guard repeatMode == .newEachWeek else { return }
        
        let currentWeekStart = weekStartDate(for: Date())
        let storedWeekStart = UserDefaults.standard.object(forKey: lastWeekStartKey) as? Date
        
        if storedWeekStart == nil || storedWeekStart != currentWeekStart {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let name = "Week of \(formatter.string(from: currentWeekStart))"
            
            var newSchedule = Schedule.createEmpty(name: name, color: "CC7359")
            for index in schedules.indices {
                schedules[index].isActive = false
            }
            newSchedule.isActive = true
            newSchedule.order = schedules.count
            schedules.append(newSchedule)
            
            UserDefaults.standard.set(currentWeekStart, forKey: lastWeekStartKey)
            saveSettings()
        }
    }
    
    private func weekStartDate(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = weekStartDay.index + 2
        let startOfDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfDay)
        return calendar.date(from: components) ?? startOfDay
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        schedules = []
        repeatMode = .weekly
        currentScheduleIndex = 0
        weekStartDay = .monday
        notificationsEnabled = true
        saveSettings()
    }
    
    // MARK: - Get Display Info
    
    func getWorkoutName(for item: ScheduleItem, from workouts: [UserWorkout]) -> String? {
        guard item.type == .workout, let workoutId = item.workoutId else { return nil }
        return workouts.first { $0.id == workoutId }?.name
    }
    
    func getItemDisplayInfo(_ item: ScheduleItem, from workouts: [UserWorkout]) -> (icon: String, title: String, color: Color) {
        switch item.type {
        case .workout:
            return (
                icon: "dumbbell.fill",
                title: getWorkoutName(for: item, from: workouts) ?? "Workout",
                color: Theme.terracotta
            )
            
        case .run:
            return (
                icon: item.runType?.icon ?? "figure.run",
                title: item.runType?.rawValue ?? "Run",
                color: Theme.sage
            )
            
        case .rest:
            return (
                icon: "bed.double.fill",
                title: "Rest Day",
                color: Theme.restDay
            )
            
        case .busy:
            return (
                icon: "briefcase.fill",
                title: "Busy",
                color: Theme.busyDay
            )
        }
    }
}

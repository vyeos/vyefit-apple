//
//  ScheduleView.swift
//  vyefit
//
//  Schedule tab for managing weekly workout/run schedules.
//

import SwiftUI

struct ScheduleView: View {
    @Environment(WorkoutStore.self) private var workoutStore
    @State private var scheduleStore = ScheduleStore()
    @State private var showingSettings = false
    @State private var showingCreateSheet = false
    @State private var editingSchedule: Schedule?
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if scheduleStore.schedules.isEmpty {
                        emptyStateView
                    } else {
                        currentScheduleView
                        allSchedulesView
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Theme.background)
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !scheduleStore.schedules.isEmpty {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("New Schedule")
                                .font(.system(size: 14, weight: .medium, design: .serif))
                        }
                        .foregroundStyle(Theme.terracotta)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                ScheduleEditorView(scheduleStore: scheduleStore)
            }
            .sheet(item: $editingSchedule) { schedule in
                ScheduleEditorView(scheduleStore: scheduleStore, editingSchedule: schedule)
            }
            .sheet(isPresented: $showingSettings) {
                ScheduleSettingsView(scheduleStore: scheduleStore)
            }
        }
        .environment(scheduleStore)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(Theme.stone.opacity(0.5))
            
            Text("No Schedules Yet")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
            
            Text("Create a weekly schedule to plan your workouts and runs. You can set up different schedules and rotate between them.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Schedule")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Theme.terracotta)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 10)
        }
        .padding(40)
    }
    
    // MARK: - Current Schedule View
    
    private var currentScheduleView: some View {
        VStack(spacing: 16) {
            if let schedule = scheduleStore.currentSchedule {
                // Schedule header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(schedule.name)
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                        
                        if let description = schedule.description {
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 12) {
                            Label("\(schedule.workoutDays)", systemImage: "dumbbell.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.terracotta)
                            
                            Label("\(schedule.runDays)", systemImage: "figure.run")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.sage)
                            
                            Label("\(schedule.restDays)", systemImage: "bed.double.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.restDay)
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color(hex: schedule.color))
                        .frame(width: 16, height: 16)
                }
                .padding(20)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 20)
                
                // Weekly view
                weeklyScheduleView(schedule: schedule)
            } else {
                noActiveScheduleView
            }
        }
    }
    
    private var noActiveScheduleView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Theme.stone.opacity(0.5))
            
            Text("No Active Schedule")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
            
            Text("Activate a schedule in settings or create a new one.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingSettings = true
            } label: {
                Text("Open Settings")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.terracotta)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
    
    private func weeklyScheduleView(schedule: Schedule) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(schedule.days) { day in
                    DayRow(
                        day: day,
                        isToday: day.day == DayOfWeek.from(date: Date()),
                        workouts: workoutStore.workouts,
                        scheduleStore: scheduleStore
                    )
                    
                    if day.day != .sunday {
                        Divider()
                            .padding(.leading, 56)
                            .padding(.trailing, 20)
                    }
                }
            }
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - All Schedules View
    
    private var allSchedulesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Schedules")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Text("\(scheduleStore.allSchedules.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.sand.opacity(0.3))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(scheduleStore.allSchedules) { schedule in
                    ScheduleCard(
                        schedule: schedule,
                        isActive: schedule.isActive,
                        repeatMode: scheduleStore.repeatMode,
                        onEdit: { editingSchedule = schedule },
                        onToggleActive: {
                            scheduleStore.activateSchedule(id: schedule.id)
                        },
                        onRemoveFromCycle: {
                            scheduleStore.deactivateSchedule(id: schedule.id)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Day Row

struct DayRow: View {
    let day: ScheduleDay
    let isToday: Bool
    let workouts: [UserWorkout]
    let scheduleStore: ScheduleStore
    
    var body: some View {
        HStack(spacing: 12) {
            // Day indicator
            VStack(spacing: 4) {
                Text(day.day.shortName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isToday ? Theme.cream : Theme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(isToday ? Theme.terracotta : Color.clear)
                    .clipShape(Circle())
            }
            .frame(width: 48)
            
            // Content
            if day.items.isEmpty {
                Text("No activities")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
                    .italic()
            } else {
                HStack(spacing: 8) {
                    ForEach(day.items.prefix(3)) { item in
                        let info = scheduleStore.getItemDisplayInfo(item, from: workouts)
                        HStack(spacing: 4) {
                            Image(systemName: info.icon)
                                .font(.system(size: 10))
                            Text(info.title)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(info.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(info.color.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    if day.items.count > 3 {
                        Text("+\(day.items.count - 3)")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.sand.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Schedule Card

struct ScheduleCard: View {
    let schedule: Schedule
    let isActive: Bool
    let repeatMode: ScheduleRepeatMode
    let onEdit: () -> Void
    let onToggleActive: () -> Void
    let onRemoveFromCycle: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 14) {
                // Color indicator
                Circle()
                    .fill(Color(hex: schedule.color))
                    .frame(width: 12, height: 12)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    HStack(spacing: 12) {
                        Text("\(schedule.totalItems) activities")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        
                        if isActive {
                            Text(repeatMode == .cyclic ? "In Cycle" : "Active")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.cream)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.sage)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                // Toggle or menu
                if repeatMode == .cyclic && isActive {
                    // In cyclic mode, show menu to remove
                    Menu {
                        Button(role: .destructive, action: onRemoveFromCycle) {
                            Label("Remove from Cycle", systemImage: "minus.circle")
                        }
                    } label: {
                        Text("#\(schedule.order + 1)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Theme.sand.opacity(0.3))
                            .clipShape(Circle())
                    }
                } else {
                    Button(action: onToggleActive) {
                        Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(isActive ? Theme.sage : Theme.stone.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Theme.sage.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View

struct ScheduleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var scheduleStore: ScheduleStore
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Schedule Mode") {
                    Picker("Repeat Mode", selection: $scheduleStore.repeatMode) {
                        ForEach(ScheduleRepeatMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    Text(scheduleStore.repeatMode.description)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                if scheduleStore.repeatMode == .cyclic {
                    Section("Active Schedules") {
                        if scheduleStore.activeSchedules.isEmpty {
                            Text("No schedules in cycle")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                        } else {
                            ForEach(scheduleStore.activeSchedules) { schedule in
                                HStack {
                                    Text("\(schedule.order + 1).")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Theme.textSecondary)
                                    
                                    Circle()
                                        .fill(Color(hex: schedule.color))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(schedule.name)
                                        .font(.system(size: 14))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.stone)
                                }
                            }
                            .onMove { source, destination in
                                scheduleStore.reorderSchedules(from: source, to: destination)
                            }
                        }
                        
                        let inactiveSchedules = scheduleStore.schedules.filter { !$0.isActive }
                        if !inactiveSchedules.isEmpty {
                            Menu {
                                ForEach(inactiveSchedules) { schedule in
                                    Button {
                                        scheduleStore.activateSchedule(id: schedule.id)
                                    } label: {
                                        Text(schedule.name)
                                        // Menu items are limited, using text only or system images.
                                        // Custom shapes like Circle are not standard in Menu buttons.
                                    }
                                }
                            } label: {
                                Label("Add Schedule to Cycle", systemImage: "plus")
                            }
                        }
                        
                        Text("Drag to reorder the cycle. Add existing schedules to the cycle using the button above.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset All Schedules", systemImage: "arrow.counterclockwise")
                    }
                    .alert("Reset All Schedules?", isPresented: $showingResetConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Reset", role: .destructive) {
                            scheduleStore.resetToDefaults()
                            dismiss()
                        }
                    } message: {
                        Text("This will delete all schedules and reset settings to default. This action cannot be undone.")
                    }
                }
            }
            .navigationTitle("Schedule Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ScheduleView()
        .environment(WorkoutStore())
}

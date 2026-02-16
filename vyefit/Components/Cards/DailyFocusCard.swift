//
//  DailyFocusCard.swift
//  vyefit
//
//  Card showing today's planned workout with a begin button.
//

import SwiftUI

struct DailyFocusCard: View {
    @Environment(WorkoutStore.self) private var workoutStore
    var scheduleStore: ScheduleStore
    
    private var todayItems: [ScheduleItem] {
        scheduleStore.todaySchedule?.items ?? []
    }
    
    private var isRestDay: Bool {
        todayItems.isEmpty || todayItems.allSatisfy { $0.type == .rest }
    }
    
    private var hasWorkout: Bool {
        todayItems.contains { $0.type == .workout }
    }
    
    private var hasRun: Bool {
        todayItems.contains { $0.type == .run }
    }
    
    private var firstWorkoutItem: ScheduleItem? {
        todayItems.first { $0.type == .workout }
    }
    
    private var firstRunItem: ScheduleItem? {
        todayItems.first { $0.type == .run }
    }
    
    private var scheduledWorkout: UserWorkout? {
        guard let item = firstWorkoutItem,
              let workoutId = item.workoutId else { return nil }
        return workoutStore.workouts.first { $0.id == workoutId }
    }
    
    private var isWorkoutCompleted: Bool {
        guard let workout = scheduledWorkout else { return false }
        let calendar = Calendar.current
        let todayWorkouts = HistoryStore.shared.workoutSessionRecords.filter {
            calendar.isDate($0.date, inSameDayAs: Date()) && $0.name == workout.name
        }
        return !todayWorkouts.isEmpty
    }
    
    private var isRunCompleted: Bool {
        guard firstRunItem != nil else { return false }
        let calendar = Calendar.current
        let todayRuns = HistoryStore.shared.runSessionRecords.filter {
            calendar.isDate($0.date, inSameDayAs: Date())
        }
        return !todayRuns.isEmpty
    }
    
    private var displayInfo: (icon: String, title: String, subtitle: String, color: Color, isRest: Bool, isCompleted: Bool) {
        if isRestDay {
            return (
                icon: "bed.double.fill",
                title: "Rest Day",
                subtitle: "Take time to recover",
                color: Theme.restDay,
                isRest: true,
                isCompleted: false
            )
        } else if hasWorkout, let workout = scheduledWorkout {
            let exerciseCount = workout.exercises.count
            if isWorkoutCompleted {
                return (
                    icon: "checkmark.circle.fill",
                    title: workout.name,
                    subtitle: "Workout completed",
                    color: Theme.sage,
                    isRest: false,
                    isCompleted: true
                )
            } else {
                return (
                    icon: "dumbbell.fill",
                    title: workout.name,
                    subtitle: "\(exerciseCount) exercises planned",
                    color: Theme.terracotta,
                    isRest: false,
                    isCompleted: false
                )
            }
        } else if hasRun, let runItem = firstRunItem {
            if isRunCompleted {
                return (
                    icon: "checkmark.circle.fill",
                    title: runItem.runType?.rawValue ?? "Run",
                    subtitle: "Run completed",
                    color: Theme.sage,
                    isRest: false,
                    isCompleted: true
                )
            } else {
                return (
                    icon: runItem.runType?.icon ?? "figure.run",
                    title: runItem.runType?.rawValue ?? "Run",
                    subtitle: "Run scheduled",
                    color: Theme.sage,
                    isRest: false,
                    isCompleted: false
                )
            }
        } else if todayItems.first(where: { $0.type == .busy }) != nil {
            return (
                icon: "briefcase.fill",
                title: "Busy",
                subtitle: "No workout planned",
                color: Theme.busyDay,
                isRest: true,
                isCompleted: false
            )
        } else {
            return (
                icon: "sun.max.fill",
                title: "Free Day",
                subtitle: "No schedule set",
                color: Theme.terracotta,
                isRest: true,
                isCompleted: false
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Focus")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(spacing: 14) {
                Image(systemName: displayInfo.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(displayInfo.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayInfo.title)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                    Text(displayInfo.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                if displayInfo.isCompleted {
                    // Show completed indicator
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14))
                        Text("Done")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Theme.sage)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.sage.opacity(0.15))
                    .clipShape(Capsule())
                } else if !displayInfo.isRest {
                    Button {
                        if hasWorkout, let workout = scheduledWorkout {
                            workoutStore.startSession(for: workout)
                        }
                    } label: {
                        Text("Begin")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.cream)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(displayInfo.color)
                            .clipShape(Capsule())
                    }
                } else {
                    // Show a rest indicator instead of button
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Rest")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Theme.sage)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.sage.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}

#Preview {
    DailyFocusCard(scheduleStore: ScheduleStore())
        .background(Theme.background)
}

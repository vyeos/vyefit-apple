//
//  DailyFocusCard.swift
//  vyefit
//
//  Card showing today's planned workout with a begin button.
//

import SwiftUI

struct DailyFocusCard: View {
    var scheduleStore: ScheduleStore
    var workoutStore: WorkoutStore
    
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
    
    private var displayInfo: (icon: String, title: String, subtitle: String, color: Color, isRest: Bool) {
        if isRestDay {
            return (
                icon: "bed.double.fill",
                title: "Rest Day",
                subtitle: "Take time to recover",
                color: Color.blue.opacity(0.6),
                isRest: true
            )
        } else if hasWorkout, let workoutItem = firstWorkoutItem {
            let workoutName = workoutStore.workouts.first { $0.id == workoutItem.workoutId }?.name ?? "Workout"
            let exerciseCount = workoutStore.workouts.first { $0.id == workoutItem.workoutId }?.exercises.count ?? 0
            return (
                icon: "dumbbell.fill",
                title: workoutName,
                subtitle: "\(exerciseCount) exercises planned",
                color: Theme.terracotta,
                isRest: false
            )
        } else if hasRun, let runItem = firstRunItem {
            return (
                icon: runItem.runType?.icon ?? "figure.run",
                title: runItem.runType?.rawValue ?? "Run",
                subtitle: "Run scheduled",
                color: Theme.sage,
                isRest: false
            )
        } else if let busyItem = todayItems.first(where: { $0.type == .busy }) {
            return (
                icon: "briefcase.fill",
                title: "Busy",
                subtitle: "No workout planned",
                color: Color.orange.opacity(0.7),
                isRest: true
            )
        } else {
            return (
                icon: "sun.max.fill",
                title: "Free Day",
                subtitle: "No schedule set",
                color: Theme.terracotta,
                isRest: true
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

                if !displayInfo.isRest {
                    Button {
                        // Start the workout - this would trigger navigation to ActiveWorkoutView
                        // For now, it's a placeholder that could be connected to workoutStore
                    } label: {
                        Text("Begin")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
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
    DailyFocusCard(scheduleStore: ScheduleStore(), workoutStore: WorkoutStore())
        .background(Theme.background)
}

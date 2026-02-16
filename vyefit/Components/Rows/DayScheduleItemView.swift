//
//  DayScheduleItemView.swift
//  vyefit
//

import SwiftUI

struct DayScheduleItemView: View {
    let item: ScheduleItem
    let workoutName: String?
    let isCompleted: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    init(item: ScheduleItem, workoutName: String? = nil, isCompleted: Bool = false, onDelete: @escaping () -> Void, onEdit: @escaping () -> Void) {
        self.item = item
        self.workoutName = workoutName
        self.isCompleted = isCompleted
        self.onDelete = onDelete
        self.onEdit = onEdit
    }
    
    private var displayInfo: (icon: String, title: String, color: Color) {
        switch item.type {
        case .workout:
            return (
                icon: "dumbbell.fill",
                title: workoutName ?? "Workout",
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
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: displayInfo.icon)
                .font(.system(size: 14))
                .foregroundStyle(displayInfo.color)
                .frame(width: 32, height: 32)
                .background(displayInfo.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(displayInfo.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.sage)
            } else {
                if let notes = item.notes, !notes.isEmpty {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary.opacity(0.6))
                }
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.stone)
                        .frame(width: 28, height: 28)
                }
            }
        }
        .padding(12)
        .background(Theme.cream.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isCompleted ? 0.7 : 1.0)
    }
}

#Preview {
    VStack(spacing: 8) {
        DayScheduleItemView(
            item: ScheduleItem.workout(UUID(), notes: "Heavy day"),
            workoutName: "Push Day",
            isCompleted: true,
            onDelete: {},
            onEdit: {}
        )
        
        DayScheduleItemView(
            item: ScheduleItem.run(.tempo),
            workoutName: nil,
            isCompleted: false,
            onDelete: {},
            onEdit: {}
        )
        
        DayScheduleItemView(
            item: ScheduleItem.rest(notes: "Recovery"),
            workoutName: nil,
            isCompleted: true,
            onDelete: {},
            onEdit: {}
        )
    }
    .padding()
    .background(Theme.background)
}

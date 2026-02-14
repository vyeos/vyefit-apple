//
//  DayScheduleItemView.swift
//  vyefit
//
//  Component for displaying a single schedule item within a day.
//

import SwiftUI

struct DayScheduleItemView: View {
    let item: ScheduleItem
    let workoutName: String?
    let onDelete: () -> Void
    let onEdit: () -> Void
    
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
                color: Color.blue.opacity(0.6)
            )
        case .busy:
            return (
                icon: "briefcase.fill",
                title: "Busy",
                color: Color.orange.opacity(0.7)
            )
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: displayInfo.icon)
                .font(.system(size: 14))
                .foregroundStyle(displayInfo.color)
                .frame(width: 32, height: 32)
                .background(displayInfo.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Title
            Text(displayInfo.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            // Notes indicator
            if let notes = item.notes, !notes.isEmpty {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
            }
            
            // Menu
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
        .padding(12)
        .background(Theme.cream.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 8) {
        DayScheduleItemView(
            item: ScheduleItem.workout(UUID(), notes: "Heavy day"),
            workoutName: "Push Day",
            onDelete: {},
            onEdit: {}
        )
        
        DayScheduleItemView(
            item: ScheduleItem.run(.tempo),
            workoutName: nil,
            onDelete: {},
            onEdit: {}
        )
        
        DayScheduleItemView(
            item: ScheduleItem.rest(notes: "Recovery"),
            workoutName: nil,
            onDelete: {},
            onEdit: {}
        )
    }
    .padding()
    .background(Theme.background)
}

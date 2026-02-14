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
    
    private var displayInfo: (icon: String, title: String, subtitle: String?, color: Color) {
        // Default values based on item type
        switch item.type {
        case .workout:
            if let name = workoutName {
                return (
                    icon: "dumbbell.fill",
                    title: name,
                    subtitle: item.duration != nil ? "\(item.duration!) min" : nil,
                    color: Theme.terracotta
                )
            }
            return (
                icon: "dumbbell.fill",
                title: "Workout",
                subtitle: item.duration != nil ? "\(item.duration!) min" : nil,
                color: Theme.terracotta
            )
        case .run:
            if let runType = item.runType {
                return (
                    icon: runType.icon,
                    title: runType.rawValue,
                    subtitle: item.duration != nil ? "\(item.duration!) min" : runType.description,
                    color: Theme.sage
                )
            }
            return (
                icon: "figure.run",
                title: "Run",
                subtitle: item.duration != nil ? "\(item.duration!) min" : nil,
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: displayInfo.icon)
                .font(.system(size: 14))
                .foregroundStyle(displayInfo.color)
                .frame(width: 32, height: 32)
                .background(displayInfo.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(displayInfo.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                if let subtitle = displayInfo.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
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
            item: ScheduleItem.workout(UUID(), duration: 60),
            workoutName: "Push Day",
            onDelete: {},
            onEdit: {}
        )
        
        DayScheduleItemView(
            item: ScheduleItem.run(.tempo, duration: 35),
            workoutName: nil,
            onDelete: {},
            onEdit: {}
        )
        
        DayScheduleItemView(
            item: ScheduleItem.rest(),
            workoutName: nil,
            onDelete: {},
            onEdit: {}
        )
    }
    .padding()
    .background(Theme.background)
}

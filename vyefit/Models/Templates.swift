//
//  Templates.swift
//  vyefit
//
//  Default templates for workouts, runs, and achievements.
//

import Foundation
import SwiftUI

enum Templates {
    
    // MARK: - Achievements
    
    static let achievements: [Achievement] = [
        Achievement(id: UUID(), title: "First Workout", description: "Complete your first workout", icon: "star.fill", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Iron Week", description: "Work out 7 days in a row", icon: "flame.fill", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Early Bird", description: "Complete 5 morning workouts", icon: "sun.max.fill", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Runner's High", description: "Run 10 km in a single session", icon: "figure.run", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Century Club", description: "Complete 100 workouts", icon: "trophy.fill", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Marathon Ready", description: "Run 42.2 km total", icon: "figure.run", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Heavy Lifter", description: "Lift 10,000 kg total volume", icon: "scalemass.fill", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Consistency King", description: "30-day workout streak", icon: "crown.fill", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Speed Demon", description: "Run 5K under 25 minutes", icon: "stopwatch.fill", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Calorie Crusher", description: "Burn 50,000 calories total", icon: "flame.circle.fill", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Leg Day Legend", description: "Complete 50 leg workouts", icon: "figure.strengthtraining.functional", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Night Owl", description: "Complete 20 evening workouts", icon: "moon.fill", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Yoga Master", description: "Complete 30 yoga sessions", icon: "figure.mind.and.body", isUnlocked: false, progress: 0.0),
        Achievement(id: UUID(), title: "Hydration Hero", description: "Log water intake for 14 days", icon: "drop.fill", isUnlocked: false, progress: 0.0),
    ]
    
    // MARK: - Week Schedule Helper
    
    static func weekSchedule(workouts: [WorkoutTemplate]) -> [WeekdaySchedule] {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        let days = [
            ("Monday", "M"), ("Tuesday", "T"), ("Wednesday", "W"),
            ("Thursday", "Th"), ("Friday", "F"), ("Saturday", "S"), ("Sunday", "Su")
        ]
        
        let todayIndex = (today + 5) % 7
        
        return days.enumerated().map { index, day in
            WeekdaySchedule(
                name: day.0,
                shortName: day.1,
                workout: nil,
                isToday: index == todayIndex
            )
        }
    }
}

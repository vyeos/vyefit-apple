//
//  Templates.swift
//  vyefit
//
//  Default templates for workouts, runs, and achievements.
//

import Foundation
import SwiftUI

enum Templates {
    
    // MARK: - Workout Templates
    
    static let workouts: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: UUID(),
            name: "Full Body Strength",
            exercises: [
                ExerciseTemplate(name: "Push-ups", sets: [SetTemplate(reps: 15, weight: 0, isCompleted: false), SetTemplate(reps: 15, weight: 0, isCompleted: false), SetTemplate(reps: 12, weight: 0, isCompleted: false)], muscleGroup: "Chest", icon: "figure.strengthtraining.traditional"),
                ExerciseTemplate(name: "Squats", sets: [SetTemplate(reps: 20, weight: 0, isCompleted: false), SetTemplate(reps: 20, weight: 0, isCompleted: false), SetTemplate(reps: 15, weight: 0, isCompleted: false)], muscleGroup: "Legs", icon: "figure.walk"),
                ExerciseTemplate(name: "Plank", sets: [SetTemplate(reps: 60, weight: 0, isCompleted: false), SetTemplate(reps: 45, weight: 0, isCompleted: false)], muscleGroup: "Core", icon: "figure.mind.and.body")
            ],
            colorHex: "D96C4B",
            icon: "figure.strengthtraining.traditional",
            lastPerformed: nil,
            scheduledDay: nil
        ),
        WorkoutTemplate(
            id: UUID(),
            name: "Upper Body Focus",
            exercises: [
                ExerciseTemplate(name: "Bench Press", sets: [SetTemplate(reps: 10, weight: 60, isCompleted: false), SetTemplate(reps: 10, weight: 60, isCompleted: false), SetTemplate(reps: 8, weight: 65, isCompleted: false)], muscleGroup: "Chest", icon: "figure.push"),
                ExerciseTemplate(name: "Pull-ups", sets: [SetTemplate(reps: 8, weight: 0, isCompleted: false), SetTemplate(reps: 6, weight: 0, isCompleted: false), SetTemplate(reps: 5, weight: 0, isCompleted: false)], muscleGroup: "Back", icon: "figure.climbing"),
                ExerciseTemplate(name: "Shoulder Press", sets: [SetTemplate(reps: 12, weight: 20, isCompleted: false), SetTemplate(reps: 10, weight: 22, isCompleted: false)], muscleGroup: "Shoulders", icon: "figure.strengthtraining.functional")
            ],
            colorHex: "8B7355",
            icon: "dumbbell.fill",
            lastPerformed: nil,
            scheduledDay: nil
        ),
        WorkoutTemplate(
            id: UUID(),
            name: "Core & Stability",
            exercises: [
                ExerciseTemplate(name: "Dead Bug", sets: [SetTemplate(reps: 12, weight: 0, isCompleted: false), SetTemplate(reps: 12, weight: 0, isCompleted: false)], muscleGroup: "Core", icon: "figure.mind.and.body"),
                ExerciseTemplate(name: "Bird Dog", sets: [SetTemplate(reps: 10, weight: 0, isCompleted: false), SetTemplate(reps: 10, weight: 0, isCompleted: false)], muscleGroup: "Core", icon: "figure.mind.and.body"),
                ExerciseTemplate(name: "Side Plank", sets: [SetTemplate(reps: 30, weight: 0, isCompleted: false), SetTemplate(reps: 30, weight: 0, isCompleted: false)], muscleGroup: "Core", icon: "figure.mind.and.body")
            ],
            colorHex: "7D8B6F",
            icon: "figure.mind.and.body",
            lastPerformed: nil,
            scheduledDay: nil
        ),
        WorkoutTemplate(
            id: UUID(),
            name: "Quick HIIT",
            exercises: [
                ExerciseTemplate(name: "Burpees", sets: [SetTemplate(reps: 10, weight: 0, isCompleted: false), SetTemplate(reps: 10, weight: 0, isCompleted: false), SetTemplate(reps: 8, weight: 0, isCompleted: false)], muscleGroup: "Full Body", icon: "figure.run"),
                ExerciseTemplate(name: "Mountain Climbers", sets: [SetTemplate(reps: 20, weight: 0, isCompleted: false), SetTemplate(reps: 20, weight: 0, isCompleted: false)], muscleGroup: "Core", icon: "figure.run"),
                ExerciseTemplate(name: "Jump Squats", sets: [SetTemplate(reps: 15, weight: 0, isCompleted: false), SetTemplate(reps: 12, weight: 0, isCompleted: false)], muscleGroup: "Legs", icon: "figure.walk")
            ],
            colorHex: "D96C4B",
            icon: "flame.fill",
            lastPerformed: nil,
            scheduledDay: nil
        )
    ]
    
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


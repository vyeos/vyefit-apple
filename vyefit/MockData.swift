//
//  MockData.swift
//  vyefit
//
//  Mock data models and sample data for UI prototyping.
//

import Foundation
import SwiftUI

// MARK: - Data Models

struct MockWorkout: Identifiable {
    let id = UUID()
    let name: String
    let exercises: [MockExercise]
    let color: Color
    let icon: String
    let lastPerformed: Date?
    let scheduledDay: String?
}

struct MockExercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: [MockSet]
    let muscleGroup: String
    let icon: String
}

struct MockSet: Identifiable {
    let id = UUID()
    let reps: Int
    let weight: Double
    let isCompleted: Bool
}

struct MockRunSession: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double // km
    let duration: TimeInterval // seconds
    let calories: Int
    let avgPace: Double // min/km
    let heartRateAvg: Int
    let heartRateMax: Int
}

struct MockWeekday: Identifiable {
    let id = UUID()
    let name: String
    let shortName: String
    let workout: MockWorkout?
    let isToday: Bool
}

struct MockAchievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let progress: Double // 0.0 to 1.0
}

struct MockStatCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let icon: String
    let trend: Double // percentage change
}

// MARK: - Sample Data

enum SampleData {

    // MARK: Exercises

    static let benchPressSets: [MockSet] = [
        MockSet(reps: 10, weight: 60, isCompleted: true),
        MockSet(reps: 8, weight: 70, isCompleted: true),
        MockSet(reps: 6, weight: 80, isCompleted: true),
        MockSet(reps: 6, weight: 80, isCompleted: false),
    ]

    static let squatSets: [MockSet] = [
        MockSet(reps: 8, weight: 100, isCompleted: true),
        MockSet(reps: 8, weight: 100, isCompleted: true),
        MockSet(reps: 6, weight: 110, isCompleted: true),
        MockSet(reps: 5, weight: 120, isCompleted: false),
    ]

    static let deadliftSets: [MockSet] = [
        MockSet(reps: 5, weight: 140, isCompleted: true),
        MockSet(reps: 5, weight: 140, isCompleted: true),
        MockSet(reps: 3, weight: 160, isCompleted: false),
    ]

    static let overheadPressSets: [MockSet] = [
        MockSet(reps: 10, weight: 40, isCompleted: true),
        MockSet(reps: 8, weight: 45, isCompleted: true),
        MockSet(reps: 8, weight: 45, isCompleted: false),
    ]

    static let pullUpSets: [MockSet] = [
        MockSet(reps: 10, weight: 0, isCompleted: true),
        MockSet(reps: 8, weight: 0, isCompleted: true),
        MockSet(reps: 6, weight: 5, isCompleted: false),
    ]

    static let curlSets: [MockSet] = [
        MockSet(reps: 12, weight: 14, isCompleted: true),
        MockSet(reps: 10, weight: 16, isCompleted: true),
        MockSet(reps: 10, weight: 16, isCompleted: false),
    ]

    static let exercises: [MockExercise] = [
        MockExercise(name: "Bench Press", sets: benchPressSets, muscleGroup: "Chest", icon: "figure.strengthtraining.traditional"),
        MockExercise(name: "Squat", sets: squatSets, muscleGroup: "Legs", icon: "figure.strengthtraining.functional"),
        MockExercise(name: "Deadlift", sets: deadliftSets, muscleGroup: "Back", icon: "figure.strengthtraining.traditional"),
        MockExercise(name: "Overhead Press", sets: overheadPressSets, muscleGroup: "Shoulders", icon: "figure.strengthtraining.traditional"),
        MockExercise(name: "Pull-ups", sets: pullUpSets, muscleGroup: "Back", icon: "figure.strengthtraining.functional"),
        MockExercise(name: "Bicep Curls", sets: curlSets, muscleGroup: "Arms", icon: "figure.strengthtraining.traditional"),
    ]

    // MARK: Workouts

    static let workouts: [MockWorkout] = [
        MockWorkout(
            name: "Push Day",
            exercises: [exercises[0], exercises[3]],
            color: .blue,
            icon: "figure.strengthtraining.traditional",
            lastPerformed: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            scheduledDay: "Monday"
        ),
        MockWorkout(
            name: "Pull Day",
            exercises: [exercises[2], exercises[4], exercises[5]],
            color: .purple,
            icon: "figure.strengthtraining.functional",
            lastPerformed: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            scheduledDay: "Wednesday"
        ),
        MockWorkout(
            name: "Leg Day",
            exercises: [exercises[1]],
            color: .orange,
            icon: "figure.walk",
            lastPerformed: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            scheduledDay: "Friday"
        ),
        MockWorkout(
            name: "Full Body",
            exercises: [exercises[0], exercises[1], exercises[2]],
            color: .green,
            icon: "figure.mixed.cardio",
            lastPerformed: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            scheduledDay: nil
        ),
    ]

    // MARK: Run Sessions

    static let runSessions: [MockRunSession] = [
        MockRunSession(date: Date(), distance: 5.2, duration: 1560, calories: 420, avgPace: 5.0, heartRateAvg: 155, heartRateMax: 178),
        MockRunSession(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, distance: 3.1, duration: 1020, calories: 260, avgPace: 5.5, heartRateAvg: 148, heartRateMax: 170),
        MockRunSession(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, distance: 10.0, duration: 3300, calories: 780, avgPace: 5.5, heartRateAvg: 152, heartRateMax: 175),
        MockRunSession(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, distance: 7.5, duration: 2400, calories: 610, avgPace: 5.33, heartRateAvg: 150, heartRateMax: 172),
    ]

    // MARK: Weekly Schedule

    static let weekSchedule: [MockWeekday] = {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date()) // 1=Sun, 2=Mon...
        let days = [
            ("Monday", "M"), ("Tuesday", "T"), ("Wednesday", "W"),
            ("Thursday", "Th"), ("Friday", "F"), ("Saturday", "S"), ("Sunday", "Su")
        ]
        let workoutMap: [Int: MockWorkout?] = [
            0: workouts[0], // Monday - Push
            2: workouts[1], // Wednesday - Pull
            4: workouts[2], // Friday - Legs
        ]
        // weekday component: Mon=2
        let todayIndex = (today + 5) % 7 // convert to 0=Mon

        return days.enumerated().map { index, day in
            MockWeekday(
                name: day.0,
                shortName: day.1,
                workout: workoutMap[index] ?? nil,
                isToday: index == todayIndex
            )
        }
    }()

    // MARK: Achievements

    static let achievements: [MockAchievement] = [
        MockAchievement(title: "First Workout", description: "Complete your first workout", icon: "star.fill", isUnlocked: true, progress: 1.0),
        MockAchievement(title: "Iron Week", description: "Work out 7 days in a row", icon: "flame.fill", isUnlocked: true, progress: 1.0),
        MockAchievement(title: "Century Club", description: "Complete 100 workouts", icon: "trophy.fill", isUnlocked: false, progress: 0.47),
        MockAchievement(title: "Marathon Ready", description: "Run 42.2 km total", icon: "figure.run", isUnlocked: false, progress: 0.61),
        MockAchievement(title: "Heavy Lifter", description: "Lift 10,000 kg total volume", icon: "scalemass.fill", isUnlocked: false, progress: 0.82),
        MockAchievement(title: "Consistency King", description: "30-day workout streak", icon: "crown.fill", isUnlocked: false, progress: 0.23),
    ]

    // MARK: Stat Cards

    static let statCards: [MockStatCard] = [
        MockStatCard(title: "This Week", value: "4", unit: "workouts", icon: "flame.fill", trend: 12.5),
        MockStatCard(title: "Total Volume", value: "12,450", unit: "kg", icon: "scalemass.fill", trend: 8.3),
        MockStatCard(title: "Run Distance", value: "25.8", unit: "km", icon: "figure.run", trend: -3.2),
        MockStatCard(title: "Avg Heart Rate", value: "152", unit: "bpm", icon: "heart.fill", trend: 1.1),
        MockStatCard(title: "Streak", value: "12", unit: "days", icon: "flame.fill", trend: 50.0),
        MockStatCard(title: "Calories", value: "2,070", unit: "kcal", icon: "bolt.fill", trend: 15.7),
    ]

    // MARK: Helpers

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    static func formatPace(_ pace: Double) -> String {
        let mins = Int(pace)
        let secs = Int((pace - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }

    static func relativeDateString(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

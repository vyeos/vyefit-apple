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

struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let timestamp: TimeInterval // seconds from start
    let heartRate: Int
}

struct RunSplit: Identifiable {
    let id = UUID()
    let kilometer: Int // 1, 2, 3...
    let pace: Double // min/km
    let elevationChange: Double // meters
}

struct MapCoordinate: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let timestamp: TimeInterval
}

struct MockRunSession: Identifiable {
    let id = UUID()
    let date: Date
    let name: String // e.g., "Morning Run"
    let location: String // e.g., "Central Park, NY"
    let distance: Double // km
    let duration: TimeInterval // seconds
    let calories: Int
    let avgPace: Double // min/km
    let heartRateAvg: Int
    let heartRateMax: Int
    let heartRateData: [HeartRateDataPoint] // HR over time
    let type: RunGoalType
    
    // Run-specific stats
    let elevationGain: Double // meters
    let elevationLoss: Double // meters
    let avgCadence: Int // steps per minute
    let splits: [RunSplit] // km splits
    let route: [MapCoordinate] // GPS coordinates
    
    // Pause tracking
    let wasPaused: Bool
    let totalElapsedTime: TimeInterval? // includes pauses
    let workingTime: TimeInterval? // excludes pauses
    
    var sessionType: SessionType { .run }
}

struct MockWorkoutSession: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
    let location: String // e.g. "Gym A"
    let duration: TimeInterval
    let calories: Int
    let exerciseCount: Int
    let heartRateAvg: Int
    let heartRateMax: Int
    let heartRateData: [HeartRateDataPoint] // HR over time
    
    // Reference to the workout template that was performed
    let workout: MockWorkout?
    
    // Pause tracking
    let wasPaused: Bool
    let totalElapsedTime: TimeInterval? // includes pauses
    let workingTime: TimeInterval? // excludes pauses
    
    var sessionType: SessionType { .workout }
}

enum SessionType {
    case workout
    case run
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
    
    static func generateHeartRateData(duration: TimeInterval, avgHR: Int, maxHR: Int) -> [HeartRateDataPoint] {
        var data: [HeartRateDataPoint] = []
        let points = Int(duration / 30) // Every 30 seconds
        for i in 0...points {
            let timestamp = TimeInterval(i * 30)
            let variation = Int.random(in: -15...15)
            let baseHR = avgHR + variation
            let hr = max(80, min(maxHR + 5, baseHR))
            data.append(HeartRateDataPoint(timestamp: timestamp, heartRate: hr))
        }
        return data
    }
    
    static func generateSplits(distance: Double, avgPace: Double) -> [RunSplit] {
        var splits: [RunSplit] = []
        let kmCount = Int(distance)
        for km in 1...kmCount {
            let paceVariation = Double.random(in: -0.3...0.3)
            let elevation = Double.random(in: -10...25)
            splits.append(RunSplit(kilometer: km, pace: avgPace + paceVariation, elevationChange: elevation))
        }
        return splits
    }
    
    static func generateRoute() -> [MapCoordinate] {
        // Mock route coordinates (simulating a loop)
        return [
            MapCoordinate(latitude: 40.7829, longitude: -73.9654, timestamp: 0),
            MapCoordinate(latitude: 40.7850, longitude: -73.9680, timestamp: 300),
            MapCoordinate(latitude: 40.7880, longitude: -73.9700, timestamp: 600),
            MapCoordinate(latitude: 40.7900, longitude: -73.9680, timestamp: 900),
            MapCoordinate(latitude: 40.7880, longitude: -73.9650, timestamp: 1200),
            MapCoordinate(latitude: 40.7850, longitude: -73.9630, timestamp: 1500),
            MapCoordinate(latitude: 40.7829, longitude: -73.9654, timestamp: 1800),
        ]
    }

    static let runSessions: [MockRunSession] = [
        MockRunSession(
            date: Date(),
            name: "Morning Run",
            location: "Central Park, NY",
            distance: 5.2,
            duration: 1560,
            calories: 420,
            avgPace: 5.0,
            heartRateAvg: 155,
            heartRateMax: 178,
            heartRateData: generateHeartRateData(duration: 1560, avgHR: 155, maxHR: 178),
            type: .distance,
            elevationGain: 45.0,
            elevationLoss: 42.0,
            avgCadence: 172,
            splits: generateSplits(distance: 5.2, avgPace: 5.0),
            route: generateRoute(),
            wasPaused: false,
            totalElapsedTime: nil,
            workingTime: nil
        ),
        MockRunSession(
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            name: "Quick Jog",
            location: "Brooklyn Bridge Park",
            distance: 3.1,
            duration: 1020,
            calories: 260,
            avgPace: 5.5,
            heartRateAvg: 148,
            heartRateMax: 170,
            heartRateData: generateHeartRateData(duration: 1020, avgHR: 148, maxHR: 170),
            type: .quickStart,
            elevationGain: 12.0,
            elevationLoss: 12.0,
            avgCadence: 168,
            splits: generateSplits(distance: 3.1, avgPace: 5.5),
            route: generateRoute(),
            wasPaused: false,
            totalElapsedTime: nil,
            workingTime: nil
        ),
        MockRunSession(
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            name: "Long Run",
            location: "West Side Highway",
            distance: 10.0,
            duration: 3300,
            calories: 780,
            avgPace: 5.5,
            heartRateAvg: 152,
            heartRateMax: 175,
            heartRateData: generateHeartRateData(duration: 3300, avgHR: 152, maxHR: 175),
            type: .time,
            elevationGain: 85.0,
            elevationLoss: 82.0,
            avgCadence: 170,
            splits: generateSplits(distance: 10.0, avgPace: 5.5),
            route: generateRoute(),
            wasPaused: false,
            totalElapsedTime: nil,
            workingTime: nil
        ),
        MockRunSession(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            name: "Interval Training",
            location: "McCarren Park Track",
            distance: 7.5,
            duration: 2400,
            calories: 610,
            avgPace: 5.33,
            heartRateAvg: 150,
            heartRateMax: 172,
            heartRateData: generateHeartRateData(duration: 2400, avgHR: 150, maxHR: 172),
            type: .intervals,
            elevationGain: 8.0,
            elevationLoss: 8.0,
            avgCadence: 175,
            splits: generateSplits(distance: 7.5, avgPace: 5.33),
            route: generateRoute(),
            wasPaused: true,
            totalElapsedTime: 2580,
            workingTime: 2400
        ),
        MockRunSession(
            date: Calendar.current.date(byAdding: .day, value: -12, to: Date())!,
            name: "Easy Run",
            location: "Prospect Park",
            distance: 5.0,
            duration: 1500,
            calories: 400,
            avgPace: 5.0,
            heartRateAvg: 145,
            heartRateMax: 165,
            heartRateData: generateHeartRateData(duration: 1500, avgHR: 145, maxHR: 165),
            type: .quickStart,
            elevationGain: 32.0,
            elevationLoss: 30.0,
            avgCadence: 166,
            splits: generateSplits(distance: 5.0, avgPace: 5.0),
            route: generateRoute(),
            wasPaused: false,
            totalElapsedTime: nil,
            workingTime: nil
        ),
        MockRunSession(
            date: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
            name: "Half Marathon",
            location: "NYC Marathon Route",
            distance: 21.1,
            duration: 7200,
            calories: 1500,
            avgPace: 5.7,
            heartRateAvg: 160,
            heartRateMax: 180,
            heartRateData: generateHeartRateData(duration: 7200, avgHR: 160, maxHR: 180),
            type: .distance,
            elevationGain: 156.0,
            elevationLoss: 154.0,
            avgCadence: 168,
            splits: generateSplits(distance: 21.1, avgPace: 5.7),
            route: generateRoute(),
            wasPaused: true,
            totalElapsedTime: 7650,
            workingTime: 7200
        ),
        MockRunSession(
            date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!,
            name: "Recovery Run",
            location: "East River Park",
            distance: 4.0,
            duration: 1200,
            calories: 300,
            avgPace: 5.0,
            heartRateAvg: 150,
            heartRateMax: 170,
            heartRateData: generateHeartRateData(duration: 1200, avgHR: 150, maxHR: 170),
            type: .quickStart,
            elevationGain: 15.0,
            elevationLoss: 15.0,
            avgCadence: 170,
            splits: generateSplits(distance: 4.0, avgPace: 5.0),
            route: generateRoute(),
            wasPaused: false,
            totalElapsedTime: nil,
            workingTime: nil
        ),
    ]
    
    // MARK: Workout Sessions
    
    static let workoutSessions: [MockWorkoutSession] = [
        MockWorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            name: "Push Day",
            location: "Gym A - Downtown",
            duration: 2700,
            calories: 380,
            exerciseCount: 5,
            heartRateAvg: 125,
            heartRateMax: 155,
            heartRateData: generateHeartRateData(duration: 2700, avgHR: 125, maxHR: 155),
            workout: workouts[0], // Push Day
            wasPaused: false,
            totalElapsedTime: nil,
            workingTime: nil
        ),
        MockWorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            name: "Pull Day",
            location: "Home Gym",
            duration: 2400,
            calories: 320,
            exerciseCount: 4,
            heartRateAvg: 120,
            heartRateMax: 148,
            heartRateData: generateHeartRateData(duration: 2400, avgHR: 120, maxHR: 148),
            workout: workouts[1], // Pull Day
            wasPaused: true,
            totalElapsedTime: 2700,
            workingTime: 2400
        ),
        MockWorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            name: "Leg Day",
            location: "Gym A - Downtown",
            duration: 3000,
            calories: 450,
            exerciseCount: 6,
            heartRateAvg: 135,
            heartRateMax: 165,
            heartRateData: generateHeartRateData(duration: 3000, avgHR: 135, maxHR: 165),
            workout: workouts[2], // Leg Day
            wasPaused: false,
            totalElapsedTime: nil,
            workingTime: nil
        ),
        MockWorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            name: "Full Body",
            location: "Gym B - Uptown",
            duration: 3600,
            calories: 520,
            exerciseCount: 8,
            heartRateAvg: 128,
            heartRateMax: 158,
            heartRateData: generateHeartRateData(duration: 3600, avgHR: 128, maxHR: 158),
            workout: workouts[3], // Full Body
            wasPaused: false,
            totalElapsedTime: nil,
            workingTime: nil
        ),
        MockWorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            name: "Push Day",
            location: "Gym A - Downtown",
            duration: 2700,
            calories: 380,
            exerciseCount: 5,
            heartRateAvg: 122,
            heartRateMax: 152,
            heartRateData: generateHeartRateData(duration: 2700, avgHR: 122, maxHR: 152),
            workout: workouts[0], // Push Day
            wasPaused: false,
            totalElapsedTime: nil,
            workingTime: nil
        ),
        MockWorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -18, to: Date())!,
            name: "Upper Body",
            location: "Home Gym",
            duration: 2400,
            calories: 340,
            exerciseCount: 5,
            heartRateAvg: 118,
            heartRateMax: 145,
            heartRateData: generateHeartRateData(duration: 2400, avgHR: 118, maxHR: 145),
            workout: nil, // Custom workout
            wasPaused: true,
            totalElapsedTime: 2760,
            workingTime: 2400
        ),
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
        // Completed
        MockAchievement(title: "First Workout", description: "Complete your first workout", icon: "star.fill", isUnlocked: true, progress: 1.0),
        MockAchievement(title: "Iron Week", description: "Work out 7 days in a row", icon: "flame.fill", isUnlocked: true, progress: 1.0),
        MockAchievement(title: "Early Bird", description: "Complete 5 morning workouts", icon: "sun.max.fill", isUnlocked: true, progress: 1.0),
        MockAchievement(title: "Runner's High", description: "Run 10 km in a single session", icon: "figure.run", isUnlocked: true, progress: 1.0),
        // In Progress (high priority to show)
        MockAchievement(title: "Century Club", description: "Complete 100 workouts", icon: "trophy.fill", isUnlocked: false, progress: 0.47),
        MockAchievement(title: "Marathon Ready", description: "Run 42.2 km total", icon: "figure.run", isUnlocked: false, progress: 0.61),
        MockAchievement(title: "Heavy Lifter", description: "Lift 10,000 kg total volume", icon: "scalemass.fill", isUnlocked: false, progress: 0.82),
        MockAchievement(title: "Consistency King", description: "30-day workout streak", icon: "crown.fill", isUnlocked: false, progress: 0.23),
        // More milestones
        MockAchievement(title: "Speed Demon", description: "Run 5K under 25 minutes", icon: "stopwatch.fill", isUnlocked: false, progress: 0.35),
        MockAchievement(title: "Calorie Crusher", description: "Burn 50,000 calories total", icon: "flame.circle.fill", isUnlocked: false, progress: 0.58),
        MockAchievement(title: "Leg Day Legend", description: "Complete 50 leg workouts", icon: "figure.strengthtraining.functional", isUnlocked: false, progress: 0.44),
        MockAchievement(title: "Night Owl", description: "Complete 20 evening workouts", icon: "moon.fill", isUnlocked: false, progress: 0.65),
        MockAchievement(title: "Yoga Master", description: "Complete 30 yoga sessions", icon: "figure.mind.and.body", isUnlocked: false, progress: 0.12),
        MockAchievement(title: "Hydration Hero", description: "Log water intake for 14 days", icon: "drop.fill", isUnlocked: false, progress: 0.79),
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

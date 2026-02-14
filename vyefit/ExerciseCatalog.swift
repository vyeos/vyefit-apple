//
//  ExerciseCatalog.swift
//  vyefit
//
//  Predefined exercise library organised by muscle group.
//

import Foundation

struct CatalogExercise: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String
    let muscleGroup: String
    let icon: String
    var lastPerformed: Date?

    func hash(into hasher: inout Hasher) { hasher.combine(name) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.name == rhs.name }
}

enum ExerciseCatalog {
    static let muscleGroups = ["Chest", "Back", "Shoulders", "Legs", "Arms", "Core"]

    private static func daysAgo(_ n: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: -n, to: Date())
    }

    static let all: [CatalogExercise] = [
        // ── Chest ──
        CatalogExercise(name: "Bench Press",         muscleGroup: "Chest",     icon: "figure.strengthtraining.traditional", lastPerformed: daysAgo(2)),
        CatalogExercise(name: "Incline Bench Press",  muscleGroup: "Chest",     icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Decline Bench Press",  muscleGroup: "Chest",     icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Dumbbell Fly",         muscleGroup: "Chest",     icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Cable Crossover",      muscleGroup: "Chest",     icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Push-Up",              muscleGroup: "Chest",     icon: "figure.strengthtraining.functional"),
        CatalogExercise(name: "Chest Dip",            muscleGroup: "Chest",     icon: "figure.strengthtraining.functional"),
        // ── Back ──
        CatalogExercise(name: "Deadlift",             muscleGroup: "Back",      icon: "figure.strengthtraining.traditional", lastPerformed: daysAgo(1)),
        CatalogExercise(name: "Pull-Up",              muscleGroup: "Back",      icon: "figure.strengthtraining.functional",  lastPerformed: daysAgo(1)),
        CatalogExercise(name: "Chin-Up",              muscleGroup: "Back",      icon: "figure.strengthtraining.functional"),
        CatalogExercise(name: "Lat Pulldown",         muscleGroup: "Back",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Barbell Row",          muscleGroup: "Back",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Seated Cable Row",     muscleGroup: "Back",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "T-Bar Row",            muscleGroup: "Back",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Face Pull",            muscleGroup: "Back",      icon: "figure.strengthtraining.traditional"),
        // ── Shoulders ──
        CatalogExercise(name: "Overhead Press",       muscleGroup: "Shoulders", icon: "figure.strengthtraining.traditional", lastPerformed: daysAgo(2)),
        CatalogExercise(name: "Lateral Raise",        muscleGroup: "Shoulders", icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Front Raise",          muscleGroup: "Shoulders", icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Rear Delt Fly",        muscleGroup: "Shoulders", icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Arnold Press",         muscleGroup: "Shoulders", icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Upright Row",          muscleGroup: "Shoulders", icon: "figure.strengthtraining.traditional"),
        // ── Legs ──
        CatalogExercise(name: "Squat",                muscleGroup: "Legs",      icon: "figure.strengthtraining.functional",  lastPerformed: daysAgo(3)),
        CatalogExercise(name: "Front Squat",          muscleGroup: "Legs",      icon: "figure.strengthtraining.functional"),
        CatalogExercise(name: "Leg Press",            muscleGroup: "Legs",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Romanian Deadlift",    muscleGroup: "Legs",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Leg Extension",        muscleGroup: "Legs",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Leg Curl",             muscleGroup: "Legs",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Calf Raise",           muscleGroup: "Legs",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Bulgarian Split Squat",muscleGroup: "Legs",      icon: "figure.strengthtraining.functional"),
        CatalogExercise(name: "Hip Thrust",           muscleGroup: "Legs",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Lunges",               muscleGroup: "Legs",      icon: "figure.walk"),
        // ── Arms ──
        CatalogExercise(name: "Bicep Curl",           muscleGroup: "Arms",      icon: "figure.strengthtraining.traditional", lastPerformed: daysAgo(1)),
        CatalogExercise(name: "Hammer Curl",          muscleGroup: "Arms",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Preacher Curl",        muscleGroup: "Arms",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Tricep Pushdown",      muscleGroup: "Arms",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Skull Crusher",        muscleGroup: "Arms",      icon: "figure.strengthtraining.traditional"),
        CatalogExercise(name: "Tricep Dip",           muscleGroup: "Arms",      icon: "figure.strengthtraining.functional"),
        CatalogExercise(name: "Concentration Curl",   muscleGroup: "Arms",      icon: "figure.strengthtraining.traditional"),
        // ── Core ──
        CatalogExercise(name: "Plank",                muscleGroup: "Core",      icon: "figure.core.training"),
        CatalogExercise(name: "Crunch",               muscleGroup: "Core",      icon: "figure.core.training"),
        CatalogExercise(name: "Hanging Leg Raise",    muscleGroup: "Core",      icon: "figure.core.training"),
        CatalogExercise(name: "Russian Twist",        muscleGroup: "Core",      icon: "figure.core.training"),
        CatalogExercise(name: "Cable Woodchop",       muscleGroup: "Core",      icon: "figure.core.training"),
        CatalogExercise(name: "Ab Rollout",           muscleGroup: "Core",      icon: "figure.core.training"),
    ]

    static func exercises(for group: String) -> [CatalogExercise] {
        all.filter { $0.muscleGroup == group }
    }
}

//
//  SessionRecords.swift
//  vyefit
//
//  Data models for completed workout sessions.
//

import Foundation
import SwiftUI
struct HeartRateDataPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: TimeInterval
    let heartRate: Int
    
    init(id: UUID = UUID(), timestamp: TimeInterval, heartRate: Int) {
        self.id = id
        self.timestamp = timestamp
        self.heartRate = heartRate
    }
}

struct WorkoutSessionRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let name: String
    let location: String
    let duration: TimeInterval
    let calories: Int
    let exerciseCount: Int
    let heartRateAvg: Int
    let heartRateMax: Int
    let heartRateData: [HeartRateDataPoint]
    
    let workoutTemplateName: String?
    
    let wasPaused: Bool
    let totalElapsedTime: TimeInterval?
    let workingTime: TimeInterval?
}

struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    var progress: Double
}

struct WeekdaySchedule: Identifiable {
    let id = UUID()
    let name: String
    let shortName: String
    let workout: WorkoutTemplate?
    let isToday: Bool
}

struct WorkoutTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var exercises: [ExerciseTemplate]
    let colorHex: String
    var icon: String
    var lastPerformed: Date?
    var scheduledDay: String?

    var color: Color { Color(hex: colorHex) }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: WorkoutTemplate, rhs: WorkoutTemplate) -> Bool {
        lhs.id == rhs.id
    }
}

struct ExerciseTemplate: Identifiable, Codable {
    var id: UUID = UUID()
    let name: String
    var sets: [SetTemplate]
    let muscleGroup: String
    let icon: String
}

struct SetTemplate: Identifiable, Codable {
    var id: UUID = UUID()
    var reps: Int
    var weight: Double
    var isCompleted: Bool
}

// MARK: - Helpers

func formatDuration(_ seconds: TimeInterval) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}

func relativeDateString(_ date: Date?) -> String {
    guard let date = date else { return "Never" }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}

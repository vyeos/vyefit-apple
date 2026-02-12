//
//  RunTypes.swift
//  vyefit
//
//  Models for different types of run sessions and goals.
//

import Foundation
import SwiftUI

enum RunGoalType: String, CaseIterable, Identifiable, Codable {
    case quickStart = "Quick Start"
    case time = "Time"
    case distance = "Distance"
    case pace = "Pace"
    case calories = "Calories"
    case heartRate = "Heart Rate Zone"
    case intervals = "Intervals"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .quickStart: return "figure.run"
        case .time: return "clock"
        case .distance: return "map"
        case .pace: return "speedometer"
        case .calories: return "flame"
        case .heartRate: return "heart.fill"
        case .intervals: return "timer"
        }
    }
}

struct RunConfiguration: Codable {
    var type: RunGoalType
    var targetValue: Double? // e.g., 30.0 (min), 5.0 (km), 500 (kcal)
    var targetPace: Double? // min/km
    var targetZone: Int? // 1-5
    
    // Interval specific
    var intervalWorkout: IntervalWorkout?
    
    static let defaultQuick = RunConfiguration(type: .quickStart)
}

struct RunTarget: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: RunGoalType
    var name: String // e.g., "5K Run", "30 min Jog"
    var value: Double? // Primary value (distance in km, time in sec, cals)
    var secondaryValue: Double? // e.g. minutes for pace (min part)
    var tertiaryValue: Double? // e.g. seconds for pace (sec part)
    
    // Display helper
    func description(unit: String) -> String {
        switch type {
        case .distance:
            return String(format: "%.1f %@", value ?? 0, unit)
        case .time:
            let h = Int((value ?? 0) / 3600)
            let m = Int(((value ?? 0).truncatingRemainder(dividingBy: 3600)) / 60)
            if h > 0 { return "\(h)h \(m)m" }
            return "\(m) min"
        case .calories:
            return "\(Int(value ?? 0)) kcal"
        case .pace:
            let m = Int(value ?? 0)
            let s = Int(secondaryValue ?? 0)
            return String(format: "%d:%02d /%@", m, s, unit)
        default:
            return name
        }
    }
}

// MARK: - Heart Rate Zones

struct HeartRateZone: Identifiable, Codable {
    var id: Int // Zone number 1-5
    var minBPM: Int
    var maxBPM: Int
    var name: String
    var description: String
    var colorHex: String
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    static let defaults: [HeartRateZone] = [
        HeartRateZone(id: 1, minBPM: 100, maxBPM: 119, name: "Warm Up", description: "Light effort, easy breathing", colorHex: "A3C4BC"), // Soft Sage
        HeartRateZone(id: 2, minBPM: 120, maxBPM: 139, name: "Fat Burn", description: "Comfortable pace, conversational", colorHex: "8CA680"), // Sage
        HeartRateZone(id: 3, minBPM: 140, maxBPM: 159, name: "Aerobic", description: "Moderate effort, improves endurance", colorHex: "EAD2AC"), // Sand/Gold
        HeartRateZone(id: 4, minBPM: 160, maxBPM: 179, name: "Anaerobic", description: "Hard effort, faster pace", colorHex: "CC7359"), // Terracotta
        HeartRateZone(id: 5, minBPM: 180, maxBPM: 200, name: "Maximum", description: "Maximum effort, sprinting", colorHex: "C45B45") // Deep Red
    ]
}

// MARK: - Intervals

enum IntervalStepType: String, Codable {
    case work = "Work"
    case rest = "Rest"
}

enum IntervalDurationType: String, Codable, CaseIterable {
    case distance = "Distance"
    case time = "Time"
}

struct IntervalStep: Identifiable, Codable {
    var id = UUID()
    var type: IntervalStepType
    var durationType: IntervalDurationType
    var value: Double // seconds or km
}

struct IntervalWorkout: Identifiable, Codable {
    var id = UUID()
    var name: String
    var warmupEnabled: Bool
    var warmupDuration: Double // seconds (time based usually)
    var cooldownEnabled: Bool
    var cooldownDuration: Double // seconds
    var repeats: Int
    var workStep: IntervalStep
    var restStep: IntervalStep
    
    static let defaultInterval = IntervalWorkout(
        name: "Standard Intervals",
        warmupEnabled: false,
        warmupDuration: 300,
        cooldownEnabled: false,
        cooldownDuration: 300,
        repeats: 5,
        workStep: IntervalStep(type: .work, durationType: .time, value: 60), // 1 min
        restStep: IntervalStep(type: .rest, durationType: .time, value: 60)   // 1 min
    )
}

// Helper for Hex Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

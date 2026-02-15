//
//  WorkoutType.swift
//  vyefit
//
//  Workout types corresponding to HealthKit activity types.
//

import Foundation
import HealthKit

enum WorkoutType: String, CaseIterable, Identifiable, Codable {
    case traditionalStrengthTraining = "Strength Training"
    case functionalStrengthTraining = "Functional Strength"
    case running = "Running"
    case cycling = "Cycling"
    case hiit = "HIIT"
    case yoga = "Yoga"
    case pilates = "Pilates"
    case coreTraining = "Core Training"
    case cardio = "Cardio"
    case walking = "Walking"
    case swimming = "Swimming"
    case other = "Other"
    
    var id: String { rawValue }
    
    var hkActivityType: HKWorkoutActivityType {
        switch self {
        case .traditionalStrengthTraining: return .traditionalStrengthTraining
        case .functionalStrengthTraining: return .functionalStrengthTraining
        case .running: return .running
        case .cycling: return .cycling
        case .hiit: return .highIntensityIntervalTraining
        case .yoga: return .yoga
        case .pilates: return .pilates
        case .coreTraining: return .coreTraining
        case .cardio: return .mixedCardio
        case .walking: return .walking
        case .swimming: return .swimming
        case .other: return .other
        }
    }
    
    var icon: String {
        switch self {
        case .traditionalStrengthTraining: return "dumbbell.fill"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .hiit: return "flame.fill"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .coreTraining: return "figure.core.training"
        case .cardio: return "heart.fill"
        case .walking: return "figure.walk"
        case .swimming: return "figure.pool.swim"
        case .other: return "figure.mixed.cardio"
        }
    }
}

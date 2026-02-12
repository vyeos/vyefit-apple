//
//  RunTargetStore.swift
//  vyefit
//
//  Store for managing saved run targets and interval workouts.
//

import Foundation
import SwiftUI

@Observable
class RunTargetStore {
    static let shared = RunTargetStore()
    
    var savedTargets: [RunTarget] = []
    var savedIntervals: [IntervalWorkout] = []
    
    // Default Targets
    let defaultDistanceTargets: [RunTarget] = [
        RunTarget(type: .distance, name: "5K Run", value: 5.0),
        RunTarget(type: .distance, name: "10K Run", value: 10.0),
        RunTarget(type: .distance, name: "Half Marathon", value: 21.1),
        RunTarget(type: .distance, name: "Marathon", value: 42.2)
    ]
    
    let defaultTimeTargets: [RunTarget] = [
        RunTarget(type: .time, name: "Quick Jog", value: 900), // 15 min
        RunTarget(type: .time, name: "Morning Run", value: 1800),
        RunTarget(type: .time, name: "Lunch Break", value: 2700),
        RunTarget(type: .time, name: "Long Run", value: 3600)
    ]
    
    let defaultCaloriesTargets: [RunTarget] = [
        RunTarget(type: .calories, name: "Light Burn", value: 200),
        RunTarget(type: .calories, name: "Moderate Burn", value: 400),
        RunTarget(type: .calories, name: "Heavy Burn", value: 600)
    ]
    
    let defaultPaceTargets: [RunTarget] = [
        RunTarget(type: .pace, name: "5:00 min/km", value: 5, secondaryValue: 0),
        RunTarget(type: .pace, name: "6:00 min/km", value: 6, secondaryValue: 0),
        RunTarget(type: .pace, name: "7:30 min/km", value: 7, secondaryValue: 30)
    ]
    
    init() {
        // Load from storage if implemented, else use defaults + empty saved
    }
    
    func defaultTargets(for type: RunGoalType) -> [RunTarget] {
        switch type {
        case .distance: return defaultDistanceTargets
        case .time: return defaultTimeTargets
        case .calories: return defaultCaloriesTargets
        case .pace: return defaultPaceTargets
        default: return []
        }
    }
    
    func customTargets(for type: RunGoalType) -> [RunTarget] {
        return savedTargets.filter { $0.type == type }
    }
    
    func targets(for type: RunGoalType) -> [RunTarget] {
        return defaultTargets(for: type) + customTargets(for: type)
    }
    
    func addTarget(_ target: RunTarget) {
        savedTargets.append(target)
        // Persist logic here
    }
    
    func saveInterval(_ interval: IntervalWorkout) {
        savedIntervals.append(interval)
    }
}

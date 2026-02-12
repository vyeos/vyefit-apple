//
//  RunSession.swift
//  vyefit
//
//  Manages the state of an active run session.
//

import SwiftUI
import Combine

@Observable
class RunSession {
    let configuration: RunConfiguration
    var state: RunState = .active
    var elapsedSeconds: Int = 0
    
    var currentDistance: Double = 0
    var currentHeartRate: Int = 75
    var activeCalories: Int = 0
    
    private var timer: AnyCancellable?
    private var startDate: Date = Date()
    
    enum RunState {
        case active
        case paused
        case completed
    }
    
    var primaryMetric: RunGoalType {
        configuration.type
    }
    
    init(configuration: RunConfiguration) {
        self.configuration = configuration
        self.startDate = Date()
        startTimer()
    }
    
    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.tick()
        }
    }
    
    func stopTimer() {
        timer?.cancel()
    }
    
    private func tick() {
        if state == .active {
            elapsedSeconds += 1
            
            if elapsedSeconds % 3 == 0 {
                currentDistance += 0.002 + Double.random(in: 0...0.003)
            }
            
            if elapsedSeconds % 5 == 0 {
                currentHeartRate = Int.random(in: 100...170)
                activeCalories += 1
            }
        }
    }
    
    func togglePause() {
        if state == .active {
            state = .paused
        } else if state == .paused {
            state = .active
        }
    }
    
    func endRun() {
        state = .completed
        stopTimer()
    }
    
    var currentPace: String {
        if currentDistance < 0.01 {
            return "--:--"
        }
        let paceSeconds = Double(elapsedSeconds) / currentDistance
        let paceMin = Int(paceSeconds / 60)
        let paceSec = Int(paceSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", paceMin, paceSec)
    }
    
    var formattedTime: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
    
    var formattedDistance: String {
        String(format: "%.2f", currentDistance)
    }
    
    var targetProgress: Double? {
        guard let target = configuration.targetValue else { return nil }
        
        switch configuration.type {
        case .distance:
            return min(currentDistance / target, 1.0)
        case .time:
            return min(Double(elapsedSeconds) / target, 1.0)
        case .calories:
            return min(Double(activeCalories) / target, 1.0)
        default:
            return nil
        }
    }
    
    var targetRemaining: String? {
        guard let target = configuration.targetValue else { return nil }
        
        switch configuration.type {
        case .distance:
            let remaining = max(target - currentDistance, 0)
            return String(format: "%.2f km left", remaining)
        case .time:
            let remaining = max(Int(target) - elapsedSeconds, 0)
            let m = remaining / 60
            let s = remaining % 60
            return String(format: "%d:%02d left", m, s)
        case .calories:
            let remaining = max(Int(target) - activeCalories, 0)
            return "\(remaining) kcal left"
        default:
            return nil
        }
    }
}

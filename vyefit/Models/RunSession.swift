//
//  RunSession.swift
//  vyefit
//
//  Manages the state of an active run session.
//

import SwiftUI
import Combine
import HealthKit

@Observable
class RunSession {
    let configuration: RunConfiguration
    var state: RunState = .active
    var elapsedSeconds: Int = 0
    
    var currentDistance: Double = 0
    var currentHeartRate: Int = 75
    var activeCalories: Int = 0
    
    // Interval tracking
    var currentPhase: IntervalPhase = .warmup
    var currentStepIndex: Int = 0
    var stepElapsedSeconds: Int = 0
    var stepDistance: Double = 0
    var stepCalories: Int = 0
    private var flatSteps: [IntervalStep] = []
    private var intervalWarmupDuration: Double = 0
    private var intervalCooldownDuration: Double = 0
    private var intervalWarmupEnabled: Bool = false
    private var intervalCooldownEnabled: Bool = false
    
    private var timer: AnyCancellable?
    private var startDate: Date = Date()
    private var pauseStartDate: Date?
    private var totalPausedSeconds: TimeInterval = 0
    private var healthController: HealthKitWorkoutController?
    private var finishedWorkout: HKWorkout?
    
    // Previous distance/calories for per-step delta tracking
    private var prevTickDistance: Double = 0
    private var prevTickCalories: Int = 0
    
    enum RunState {
        case active
        case paused
        case completed
    }
    
    var primaryMetric: RunGoalType {
        configuration.type
    }
    
    var currentZone: HeartRateZone? {
        HeartRateZone.defaults.first { zone in
            currentHeartRate >= zone.minBPM && currentHeartRate <= zone.maxBPM
        }
    }
    
    var isIntervalRun: Bool {
        configuration.type == .intervals
    }

    var isHealthBacked: Bool {
        healthController != nil
    }
    
    init(configuration: RunConfiguration, healthController: HealthKitWorkoutController? = nil) {
        self.configuration = configuration
        self.startDate = Date()
        self.healthController = healthController
        
        // Setup interval state
        if let iw = configuration.intervalWorkout {
            flatSteps = iw.steps
            intervalWarmupEnabled = iw.warmupEnabled
            intervalCooldownEnabled = iw.cooldownEnabled
            intervalWarmupDuration = iw.warmupStep.value
            intervalCooldownDuration = iw.cooldownStep.value
            
            if iw.warmupEnabled {
                currentPhase = .warmup
            } else if !iw.steps.isEmpty {
                currentPhase = iw.steps[0].type == .work ? .work : .rest
                currentStepIndex = 0
            } else {
                currentPhase = .completed
            }
        }
        
        if let healthController {
            wireHealthController(healthController)
            healthController.start()
        }
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
        guard state == .active else { return }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(startDate) - totalPausedSeconds
        elapsedSeconds = max(Int(elapsed), 0)
        
        // If not HealthKit-backed, keep lightweight simulation
        var distDelta: Double = 0
        var calDelta: Int = 0
        if healthController == nil {
            if elapsedSeconds % 3 == 0 {
                distDelta = 0.002 + Double.random(in: 0...0.003)
                currentDistance += distDelta
            }
            if elapsedSeconds % 5 == 0 {
                currentHeartRate = Int.random(in: 100...170)
                activeCalories += 1
                calDelta = 1
            }
        }
        
        // Interval logic
        if isIntervalRun && currentPhase != .completed {
            stepElapsedSeconds += 1
            stepDistance += distDelta
            stepCalories += calDelta
            
            checkStepAdvance()
        }
    }
    
    private func checkStepAdvance() {
        switch currentPhase {
        case .warmup:
            if Double(stepElapsedSeconds) >= intervalWarmupDuration {
                advanceFromWarmup()
            }
        case .work, .rest:
            guard currentStepIndex < flatSteps.count else {
                advanceToCooldownOrEnd()
                return
            }
            let step = flatSteps[currentStepIndex]
            let met: Bool
            switch step.durationType {
            case .time:
                met = Double(stepElapsedSeconds) >= step.value
            case .distance:
                met = stepDistance >= step.value
            case .calories:
                met = Double(stepCalories) >= step.value
            }
            if met {
                advanceStep()
            }
        case .cooldown:
            if Double(stepElapsedSeconds) >= intervalCooldownDuration {
                currentPhase = .completed
            }
        case .completed:
            break
        }
    }
    
    private func advanceFromWarmup() {
        resetStepCounters()
        if !flatSteps.isEmpty {
            currentStepIndex = 0
            currentPhase = flatSteps[0].type == .work ? .work : .rest
        } else {
            advanceToCooldownOrEnd()
        }
    }
    
    private func advanceStep() {
        resetStepCounters()
        currentStepIndex += 1
        if currentStepIndex < flatSteps.count {
            let next = flatSteps[currentStepIndex]
            currentPhase = next.type == .work ? .work : .rest
        } else {
            advanceToCooldownOrEnd()
        }
    }
    
    private func advanceToCooldownOrEnd() {
        resetStepCounters()
        if intervalCooldownEnabled {
            currentPhase = .cooldown
        } else {
            currentPhase = .completed
        }
    }
    
    private func resetStepCounters() {
        stepElapsedSeconds = 0
        stepDistance = 0
        stepCalories = 0
    }
    
    func togglePause() {
        if state == .active {
            state = .paused
            pauseStartDate = Date()
            healthController?.pause()
        } else if state == .paused {
            state = .active
            if let pauseStartDate {
                totalPausedSeconds += Date().timeIntervalSince(pauseStartDate)
                self.pauseStartDate = nil
            }
            healthController?.resume()
        }
    }
    
    @MainActor
    func togglePauseAsync() async {
        // Update UI state on main actor quickly
        if state == .active {
            state = .paused
            pauseStartDate = Date()
            healthController?.pause()
        } else if state == .paused {
            state = .active
            if let pauseStartDate {
                totalPausedSeconds += Date().timeIntervalSince(pauseStartDate)
                self.pauseStartDate = nil
            }
            healthController?.resume()
        }
        // Placeholder for any heavy work to be done off-main if needed
        await Task.yield()
    }
    
    @MainActor
    func endRunAsync() async {
        state = .completed
        stopTimer()
        if let healthController {
            await withCheckedContinuation { continuation in
                healthController.end { [weak self] workout in
                    self?.finishedWorkout = workout
                    continuation.resume()
                }
            }
        } else {
            await Task.yield()
        }
    }
    
    func endRun() {
        state = .completed
        stopTimer()
        healthController?.end()
    }
    
    // MARK: - Formatted outputs
    
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
        guard let target = configuration.targetValue, target > 0 else { return nil }
        
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
        guard let target = configuration.targetValue, target > 0 else { return nil }
        
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
    
    // MARK: - Interval display helpers
    
    var currentPhaseName: String {
        currentPhase.rawValue.uppercased()
    }
    
    var currentPhaseColor: Color {
        switch currentPhase {
        case .warmup: return Theme.stone
        case .work: return Theme.terracotta
        case .rest: return Theme.sage
        case .cooldown: return Theme.stone
        case .completed: return Theme.sage
        }
    }
    
    var stepProgressText: String? {
        guard isIntervalRun, currentPhase == .work || currentPhase == .rest else { return nil }
        return "Step \(currentStepIndex + 1) of \(flatSteps.count)"
    }
    
    var stepRemainingText: String? {
        guard isIntervalRun else { return nil }
        switch currentPhase {
        case .warmup:
            return formatSecondsRemaining(intervalWarmupDuration - Double(stepElapsedSeconds))
        case .cooldown:
            return formatSecondsRemaining(intervalCooldownDuration - Double(stepElapsedSeconds))
        case .work, .rest:
            guard currentStepIndex < flatSteps.count else { return nil }
            let step = flatSteps[currentStepIndex]
            switch step.durationType {
            case .time:
                return formatSecondsRemaining(step.value - Double(stepElapsedSeconds))
            case .distance:
                let remaining = max(step.value - stepDistance, 0)
                return String(format: "%.2f km left", remaining)
            case .calories:
                let remaining = max(Int(step.value) - stepCalories, 0)
                return "\(remaining) kcal left"
            }
        case .completed:
            return "Done"
        }
    }
    
    var nextStepPreview: String? {
        guard isIntervalRun else { return nil }
        switch currentPhase {
        case .warmup:
            if let first = flatSteps.first {
                return "Next: \(first.type.rawValue) \(formatStepValue(first))"
            }
            return nil
        case .work, .rest:
            let nextIdx = currentStepIndex + 1
            if nextIdx < flatSteps.count {
                let next = flatSteps[nextIdx]
                return "Next: \(next.type.rawValue) \(formatStepValue(next))"
            } else if intervalCooldownEnabled {
                return "Next: Cooldown \(formatSecondsShort(intervalCooldownDuration))"
            }
            return "Next: Finish"
        case .cooldown:
            return "Next: Finish"
        case .completed:
            return nil
        }
    }
    
    private func formatSecondsRemaining(_ seconds: Double) -> String {
        let s = max(Int(seconds), 0)
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d left", m, sec)
    }
    
    private func formatSecondsShort(_ seconds: Double) -> String {
        let s = Int(seconds)
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
    
    private func formatStepValue(_ step: IntervalStep) -> String {
        switch step.durationType {
        case .time:
            return formatSecondsShort(step.value)
        case .distance:
            return String(format: "%.2f km", step.value)
        case .calories:
            return "\(Int(step.value)) kcal"
        }
    }

    func consumeFinishedWorkout() -> HKWorkout? {
        defer { finishedWorkout = nil }
        return finishedWorkout
    }

    private func wireHealthController(_ controller: HealthKitWorkoutController) {
        controller.onMetrics = { [weak self] metrics in
            guard let self else { return }
            self.currentDistance = metrics.distanceMeters / 1000.0
            self.activeCalories = Int(metrics.activeEnergyKcal)
            self.currentHeartRate = Int(metrics.heartRateBpm)
        }
        controller.onStateChange = { [weak self] state in
            guard let self else { return }
            switch state {
            case .running: self.state = .active
            case .paused: self.state = .paused
            case .ended: self.state = .completed
            default: break
            }
        }
    }
}

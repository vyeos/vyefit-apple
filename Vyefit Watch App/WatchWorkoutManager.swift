//
//  WatchWorkoutManager.swift
//  Vyefit Watch App
//

import Foundation
import Combine
import HealthKit
@preconcurrency import CoreLocation

@MainActor
    final class WatchWorkoutManager: NSObject, ObservableObject {
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distanceMeters: Double = 0
    @Published var cadenceSpm: Double = 0
    @Published var elapsedSeconds: Int = 0
    @Published var currentActivityType: HKWorkoutActivityType = .traditionalStrengthTraining
    @Published var currentLocationType: HKWorkoutSessionLocationType = .indoor
    
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var locationManager: CLLocationManager?
    private var lastLocation: CLLocation?
    private var startDate: Date?
    private var ticker: Timer?
    private var lastMetricsSend: Date?
    
    override init() {
        super.init()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        var readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) { readTypes.insert(heartRate) }
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { readTypes.insert(energy) }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) { readTypes.insert(distance) }
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { readTypes.insert(steps) }
        
        let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { _, _ in }
    }
    
    func start(activity: HKWorkoutActivityType, location: HKWorkoutSessionLocationType) {
        requestAuthorization()
        let config = HKWorkoutConfiguration()
        config.activityType = activity
        config.locationType = location
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            self.session = session
            self.builder = builder
            session.delegate = self
            builder.delegate = self
            isRunning = true
            currentActivityType = activity
            currentLocationType = location
            startDate = Date()
            session.startActivity(with: startDate!)
            builder.beginCollection(withStart: startDate!) { _, _ in }
            startRouteTrackingIfNeeded(location: location)
            startTicker()
        } catch {
            isRunning = false
        }
    }

    @MainActor
    func end() {
        // Keep a simple sync entry point for existing call sites
        Task { [weak self] in
            guard let self else { return }
            await self.endAsync()
        }
    }

    @MainActor
    func endAsync() async {
        // Capture references by value to avoid capturing `self` in @Sendable closures
        let builder = self.builder
        let routeBuilder = self.routeBuilder
        let locationManager = self.locationManager
        let hkSession = self.session

        // Stop timer and location immediately
        self.ticker?.invalidate()
        self.ticker = nil
        locationManager?.stopUpdatingLocation()
        
        // End the HealthKit session first - this tells watchOS to stop the workout
        hkSession?.end()

        // End collection using async alternative via continuation
        if let builder {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                builder.endCollection(withEnd: Date()) { _, _ in
                    continuation.resume()
                }
            }
        }

        // Finish workout using async alternative via continuation
        let workout: HKWorkout? = await withCheckedContinuation { (continuation: CheckedContinuation<HKWorkout?, Never>) in
            builder?.finishWorkout { workout, _ in
                continuation.resume(returning: workout)
            }
        }

        // Finish route (if any) before updating UI state
        if let workout, let routeBuilder {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                routeBuilder.finishRoute(with: workout, metadata: nil) { _, _ in
                    continuation.resume()
                }
            }
            WatchConnectivityManager.shared.sendEnded(uuid: workout.uuid)
        } else {
            WatchConnectivityManager.shared.sendEnded(uuid: nil)
        }
        
        // Reset all state
        self.isRunning = false
        self.isPaused = false
        self.heartRate = 0
        self.activeEnergy = 0
        self.distanceMeters = 0
        self.cadenceSpm = 0
        self.elapsedSeconds = 0
        self.session = nil
        self.builder = nil
        self.routeBuilder = nil
        self.locationManager = nil
        self.startDate = nil
        self.lastMetricsSend = nil
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        session?.pause()
        isPaused = true
        WatchConnectivityManager.shared.sendPause()
    }
    
    func resume() {
        guard isRunning, isPaused else { return }
        session?.resume()
        isPaused = false
        WatchConnectivityManager.shared.sendResume()
    }
    
    private func startRouteTrackingIfNeeded(location: HKWorkoutSessionLocationType) {
        guard location == .outdoor else { return }
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        locationManager = manager
        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: .local())
    }
    
    private func updateElapsed() {
        if let startDate {
            elapsedSeconds = max(Int(Date().timeIntervalSince(startDate)), 0)
        }
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateElapsed()
            }
        }
    }
}

extension WatchWorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) { }
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
           collectedTypes.contains(heartRateType),
           let stats = workoutBuilder.statistics(for: heartRateType) {
            let unit = HKUnit.count().unitDivided(by: .minute())
            heartRate = stats.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
        }
        
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           collectedTypes.contains(energyType),
           let stats = workoutBuilder.statistics(for: energyType) {
            activeEnergy = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        }
        
        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
           collectedTypes.contains(distanceType),
           let stats = workoutBuilder.statistics(for: distanceType) {
            distanceMeters = stats.sumQuantity()?.doubleValue(for: .meter()) ?? 0
        }
        
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount),
           collectedTypes.contains(stepsType),
           let stats = workoutBuilder.statistics(for: stepsType) {
            let steps = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
            let minutes = max(workoutBuilder.elapsedTime / 60.0, 1.0 / 60.0)
            cadenceSpm = steps / minutes
        }
        
        updateElapsed()
        let now = Date()
        if let last = lastMetricsSend, now.timeIntervalSince(last) < 5 {
            return
        }
        lastMetricsSend = now
        let activityLabel: String
        switch workoutBuilder.workoutConfiguration.activityType {
        case .running:
            activityLabel = "run"
        default:
            activityLabel = "workout"
        }
        WatchConnectivityManager.shared.sendMetrics(
            activity: activityLabel,
            heartRate: heartRate,
            distanceMeters: distanceMeters,
            activeEnergyKcal: activeEnergy,
            cadenceSpm: cadenceSpm,
            elapsedSeconds: elapsedSeconds
        )
    }
}

extension WatchWorkoutManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let routeBuilder else { return }
        routeBuilder.insertRouteData(locations) { _, _ in }
        
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        var samples: [HKQuantitySample] = []
        for location in locations {
            if let last = lastLocation {
                let delta = location.distance(from: last)
                if delta > 0 {
                    let quantity = HKQuantity(unit: .meter(), doubleValue: delta)
                    let sample = HKQuantitySample(type: distanceType, quantity: quantity, start: last.timestamp, end: location.timestamp)
                    samples.append(sample)
                }
            }
            lastLocation = location
        }
        
        if !samples.isEmpty {
            builder?.add(samples) { _, _ in }
        }
    }
}


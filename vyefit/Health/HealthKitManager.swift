//
//  HealthKitManager.swift
//  vyefit
//
//  HealthKit integration for workout history.
//

import Foundation
import HealthKit
import CoreLocation
import Combine

final class HealthKitManager: NSObject, ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    private let lastSyncKey = "healthLastSyncDate"

    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var authorizationError: String?

    private override init() {
        super.init()
        refreshAuthorizationStatus()
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization(readWorkouts: Bool, writeWorkouts: Bool, readVitals: Bool, completion: @escaping (Bool, Error?) -> Void) {
        guard isHealthDataAvailable else {
            completion(false, nil)
            return
        }

        var readTypes: Set<HKObjectType> = []
        var writeTypes: Set<HKSampleType> = []

        if readWorkouts {
            readTypes.insert(HKObjectType.workoutType())
            readTypes.insert(HKSeriesType.workoutRoute())
            if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) { readTypes.insert(distance) }
            if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { readTypes.insert(energy) }
            if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { readTypes.insert(steps) }
        }

        if readVitals {
            if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) { readTypes.insert(heartRate) }
        }

        if writeWorkouts {
            writeTypes.insert(HKObjectType.workoutType())
        }

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.authorizationError = error?.localizedDescription
                self?.refreshAuthorizationStatus()
                completion(success, error)
            }
        }
    }

    func refreshAuthorizationStatus() {
        let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        DispatchQueue.main.async {
            self.isAuthorized = status == .sharingAuthorized
        }
    }

    func importLatestWorkoutsIfNeeded(force: Bool = false, completion: ((Int) -> Void)? = nil) {
        let stored = UserDefaults.standard.object(forKey: "healthReadWorkouts")
        let readEnabled = stored == nil ? true : UserDefaults.standard.bool(forKey: "healthReadWorkouts")
        guard readEnabled else {
            completion?(0)
            return
        }
        
        // For force refresh or first sync, fetch from start of today to ensure we get all today's sessions
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        let since: Date?
        if force {
            since = startOfToday
        } else if let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            // Use the earlier of lastSync or startOfToday to ensure we don't miss today's sessions
            since = min(lastSync, startOfToday)
        } else {
            since = startOfToday
        }
        
        importWorkouts(since: since) { [weak self] count in
            UserDefaults.standard.set(Date(), forKey: self?.lastSyncKey ?? "")
            completion?(count)
        }
    }
    
    func importTodayWorkouts(completion: ((Int) -> Void)? = nil) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        importWorkouts(since: startOfToday) { count in
            completion?(count)
        }
    }

    func importWorkouts(since: Date?, completion: @escaping (Int) -> Void) {
        guard isAuthorized else {
            completion(0)
            return
        }

        let predicate: NSPredicate? = since.map { HKQuery.predicateForSamples(withStart: $0, end: nil, options: .strictStartDate) }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let self, let workouts = samples as? [HKWorkout] else {
                DispatchQueue.main.async { completion(0) }
                return
            }

            let group = DispatchGroup()
            var importedCount = 0

            for workout in workouts {
                group.enter()
                self.buildCompletedWorkout(from: workout) { completed in
                    if HistoryStore.shared.importWorkout(completed) {
                        importedCount += 1
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(importedCount)
            }
        }

        healthStore.execute(query)
    }

    func importWorkoutSample(_ workout: HKWorkout, completion: @escaping (Bool) -> Void) {
        buildCompletedWorkout(from: workout) { completed in
            completion(HistoryStore.shared.importWorkout(completed))
        }
    }

    func importWorkout(uuid: UUID, completion: @escaping (Bool) -> Void) {
        let predicate = HKQuery.predicateForObject(with: uuid)
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: 1, sortDescriptors: nil) { [weak self] _, samples, _ in
            guard let self else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            guard let workout = samples?.first as? HKWorkout else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.importWorkoutSample(workout) { success in
                DispatchQueue.main.async { completion(success) }
            }
        }
        healthStore.execute(query)
    }

    func deleteWorkout(uuid: UUID, completion: @escaping (Bool) -> Void) {
        guard isAuthorized else {
            completion(false)
            return
        }
        let predicate = HKQuery.predicateForObject(with: uuid)
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: 1, sortDescriptors: nil) { [weak self] _, samples, _ in
            guard let self else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            guard let workout = samples?.first as? HKWorkout else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.healthStore.delete(workout) { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
        }
        healthStore.execute(query)
    }

    func startWorkoutController(activityType: HKWorkoutActivityType, location: HKWorkoutSessionLocationType) -> HealthKitWorkoutController? {
        guard isHealthDataAvailable, isAuthorized else { return nil }
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = location

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            let controller = HealthKitWorkoutController(healthStore: healthStore, session: session, builder: builder, locationType: location)
            return controller
        } catch {
            return nil
        }
    }

    // MARK: - Builders

    private func buildCompletedWorkout(from workout: HKWorkout, completion: @escaping (CompletedWorkout) -> Void) {
        var calories = 0
        let group = DispatchGroup()
        var heartRateAvg = 0
        var heartRateMax = 0
        var heartRateData: [HeartRateDataPoint] = []

        group.enter()
        fetchHeartRateStats(for: workout) { avg, max in
            heartRateAvg = avg
            heartRateMax = max
            group.leave()
        }

        group.enter()
        fetchHeartRateSeries(for: workout) { data in
            heartRateData = data
            group.leave()
        }
        
        group.enter()
        fetchActiveEnergy(for: workout) { kcal in
            calories = kcal
            group.leave()
        }

        group.notify(queue: .main) {
            let completed = CompletedWorkout(
                id: workout.uuid,
                date: workout.startDate,
                name: workout.workoutActivityType.name,
                location: workout.workoutActivityType.locationLabel,
                duration: workout.duration,
                calories: calories,
                exerciseCount: 0,
                heartRateAvg: heartRateAvg,
                heartRateMax: heartRateMax,
                heartRateData: heartRateData,
                workoutName: workout.workoutActivityType.name,
                workoutType: workout.workoutActivityType.name,
                wasPaused: false,
                totalElapsedTime: workout.duration,
                workingTime: workout.duration
            )
            completion(completed)
        }
    }

    private func fetchHeartRateStats(for workout: HKWorkout, completion: @escaping (Int, Int) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(0, 0)
            return
        }

        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: [.discreteAverage, .discreteMax]) { _, statistics, _ in
            let unit = HKUnit.count().unitDivided(by: .minute())
            let avg = Int(statistics?.averageQuantity()?.doubleValue(for: unit) ?? 0)
            let max = Int(statistics?.maximumQuantity()?.doubleValue(for: unit) ?? 0)
            completion(avg, max)
        }
        healthStore.execute(query)
    }

    private func fetchHeartRateSeries(for workout: HKWorkout, completion: @escaping ([HeartRateDataPoint]) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion([])
            return
        }

        let predicate = HKQuery.predicateForObjects(from: workout)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            let unit = HKUnit.count().unitDivided(by: .minute())
            let points: [HeartRateDataPoint] = (samples as? [HKQuantitySample])?.map { sample in
                HeartRateDataPoint(timestamp: sample.startDate.timeIntervalSince(workout.startDate), heartRate: Int(sample.quantity.doubleValue(for: unit)))
            } ?? []
            completion(points)
        }
        healthStore.execute(query)
    }

    private func fetchActiveEnergy(for workout: HKWorkout, completion: @escaping (Int) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: [.cumulativeSum]) { _, statistics, _ in
            let kcal = Int(statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
            completion(kcal)
        }
        healthStore.execute(query)
    }
}

final class HealthKitWorkoutController: NSObject {
    private let healthStore: HKHealthStore
    private let session: HKWorkoutSession
    private let builder: HKLiveWorkoutBuilder
    private let locationType: HKWorkoutSessionLocationType
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var locationManager: CLLocationManager?
    private var lastLocation: CLLocation?
    private var totalDistanceMeters: Double = 0

    var onMetrics: ((HealthKitMetrics) -> Void)?
    var onStateChange: ((HKWorkoutSessionState) -> Void)?

    init(healthStore: HKHealthStore, session: HKWorkoutSession, builder: HKLiveWorkoutBuilder, locationType: HKWorkoutSessionLocationType) {
        self.healthStore = healthStore
        self.session = session
        self.builder = builder
        self.locationType = locationType
        super.init()
        session.delegate = self
        builder.delegate = self
    }

    func start() {
        let startDate = Date()
        session.startActivity(with: startDate)
        builder.beginCollection(withStart: startDate) { _, _ in }
        startRouteTrackingIfNeeded()
    }

    func pause() {
        session.pause()
    }

    func resume() {
        session.resume()
    }

    func end(completion: ((HKWorkout?) -> Void)? = nil) {
        session.end()
        builder.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.builder.finishWorkout { workout, _ in
                guard let self else {
                    DispatchQueue.main.async { completion?(workout) }
                    return
                }
                if let workout, let routeBuilder = self.routeBuilder, self.locationType == .outdoor {
                    self.locationManager?.stopUpdatingLocation()
                    routeBuilder.finishRoute(with: workout, metadata: nil) { _, _ in
                        DispatchQueue.main.async { completion?(workout) }
                    }
                } else {
                    self.locationManager?.stopUpdatingLocation()
                    DispatchQueue.main.async { completion?(workout) }
                }
            }
        }
    }

    private func startRouteTrackingIfNeeded() {
        guard locationType == .outdoor else { return }
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        locationManager = manager
        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: .local())
    }
}

extension HealthKitWorkoutController: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.onStateChange?(toState)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        var metrics = HealthKitMetrics()

        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), collectedTypes.contains(distanceType),
           let stats = workoutBuilder.statistics(for: distanceType) {
            metrics.distanceMeters = stats.sumQuantity()?.doubleValue(for: .meter()) ?? 0
        }

        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned), collectedTypes.contains(energyType),
           let stats = workoutBuilder.statistics(for: energyType) {
            metrics.activeEnergyKcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        }

        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate), collectedTypes.contains(heartRateType),
           let stats = workoutBuilder.statistics(for: heartRateType) {
            let unit = HKUnit.count().unitDivided(by: .minute())
            metrics.heartRateBpm = stats.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
        }

        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount),
           collectedTypes.contains(stepsType),
           let stats = workoutBuilder.statistics(for: stepsType) {
            let steps = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
            let minutes = max(workoutBuilder.elapsedTime / 60.0, 1.0 / 60.0)
            metrics.cadenceSpm = steps / minutes
        }

        DispatchQueue.main.async {
            self.onMetrics?(metrics)
        }
    }
}

extension HealthKitWorkoutController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let routeBuilder else { return }
        routeBuilder.insertRouteData(locations) { _, _ in }
        
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        var samples: [HKQuantitySample] = []
        for location in locations {
            if let last = lastLocation {
                let delta = location.distance(from: last)
                if delta > 0 {
                    totalDistanceMeters += delta
                    let quantity = HKQuantity(unit: .meter(), doubleValue: delta)
                    let sample = HKQuantitySample(type: distanceType, quantity: quantity, start: last.timestamp, end: location.timestamp)
                    samples.append(sample)
                }
            }
            lastLocation = location
        }
        
        if !samples.isEmpty {
            builder.add(samples) { _, _ in }
        }
    }
}

struct HealthKitMetrics {
    var distanceMeters: Double = 0
    var activeEnergyKcal: Double = 0
    var heartRateBpm: Double = 0
    var cadenceSpm: Double = 0
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        default: return "Workout"
        }
    }

    var locationLabel: String {
        switch self {
        case .running, .walking, .cycling: return "Outdoor"
        default: return "Indoor"
        }
    }
}

//
//  HealthKitManager.swift
//  vyefit
//
//  HealthKit integration for workouts and runs.
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
        let since = force ? nil : UserDefaults.standard.object(forKey: lastSyncKey) as? Date
        importWorkouts(since: since) { [weak self] count in
            UserDefaults.standard.set(Date(), forKey: self?.lastSyncKey ?? "")
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
                if workout.workoutActivityType == .running {
                    group.enter()
                    self.buildCompletedRun(from: workout) { completed in
                        if HistoryStore.shared.importRun(completed) {
                            importedCount += 1
                        }
                        group.leave()
                    }
                } else {
                    group.enter()
                    self.buildCompletedWorkout(from: workout) { completed in
                        if HistoryStore.shared.importWorkout(completed) {
                            importedCount += 1
                        }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                completion(importedCount)
            }
        }

        healthStore.execute(query)
    }

    func importWorkoutSample(_ workout: HKWorkout, completion: @escaping (Bool) -> Void) {
        if workout.workoutActivityType == .running {
            buildCompletedRun(from: workout) { completed in
                completion(HistoryStore.shared.importRun(completed))
            }
        } else {
            buildCompletedWorkout(from: workout) { completed in
                completion(HistoryStore.shared.importWorkout(completed))
            }
        }
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
            let controller = HealthKitWorkoutController(healthStore: healthStore, session: session, builder: builder)
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

    private func buildCompletedRun(from workout: HKWorkout, completion: @escaping (CompletedRun) -> Void) {
        let distanceMeters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let distanceKm = distanceMeters / 1000.0
        var calories = 0

        let group = DispatchGroup()
        var heartRateAvg = 0
        var heartRateMax = 0
        var cadenceAvg = 0
        var route: [MapCoordinate] = []
        var splits: [RunSplit] = []
        var elevationGain: Double = 0
        var elevationLoss: Double = 0
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
        fetchCadenceAverage(for: workout) { avg in
            cadenceAvg = avg
            group.leave()
        }

        group.enter()
        fetchRoute(for: workout) { coords, gain, loss in
            route = coords
            elevationGain = gain
            elevationLoss = loss
            group.leave()
        }

        group.enter()
        fetchSplits(for: workout) { runSplits in
            splits = runSplits
            group.leave()
        }
        
        group.enter()
        fetchActiveEnergy(for: workout) { kcal in
            calories = kcal
            group.leave()
        }

        group.notify(queue: .main) {
            let avgPace = distanceKm > 0 ? (workout.duration / 60.0) / distanceKm : 0
            let completed = CompletedRun(
                id: workout.uuid,
                date: workout.startDate,
                name: RunGoalType.quickStart.rawValue,
                location: workout.workoutActivityType.locationLabel,
                distance: distanceKm,
                duration: workout.duration,
                calories: calories,
                avgPace: avgPace,
                heartRateAvg: heartRateAvg,
                heartRateMax: heartRateMax,
                heartRateData: heartRateData,
                type: RunGoalType.quickStart.rawValue,
                elevationGain: elevationGain,
                elevationLoss: elevationLoss,
                avgCadence: cadenceAvg,
                splits: splits,
                route: route,
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

    private func fetchCadenceAverage(for workout: HKWorkout, completion: @escaping (Int) -> Void) {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }

        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: [.cumulativeSum]) { _, statistics, _ in
            let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            let minutes = max(workout.duration / 60.0, 1.0)
            let cadence = Int(steps / minutes)
            completion(cadence)
        }
        healthStore.execute(query)
    }

    private func fetchRoute(for workout: HKWorkout, completion: @escaping ([MapCoordinate], Double, Double) -> Void) {
        let routeType = HKSeriesType.workoutRoute()

        let predicate = HKQuery.predicateForObjects(from: workout)
        let routeQuery = HKSampleQuery(sampleType: routeType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            guard let self else { return }
            guard let routes = samples as? [HKWorkoutRoute], let route = routes.first else {
                completion([], 0, 0)
                return
            }

            var coords: [MapCoordinate] = []
            var elevationGain: Double = 0
            var elevationLoss: Double = 0
            var lastAltitude: Double?

            let locationQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, _ in
                let newLocations = locations ?? []
                for location in newLocations {
                    coords.append(MapCoordinate(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        timestamp: location.timestamp.timeIntervalSince1970
                    ))

                    if location.verticalAccuracy >= 0 {
                        let altitude = location.altitude
                        if let last = lastAltitude {
                            let diff = altitude - last
                            if diff > 0 { elevationGain += diff }
                            if diff < 0 { elevationLoss += abs(diff) }
                        }
                        lastAltitude = altitude
                    }
                }

                if done {
                    completion(coords, elevationGain, elevationLoss)
                }
            }

            self.healthStore.execute(locationQuery)
        }

        healthStore.execute(routeQuery)
    }

    private func fetchSplits(for workout: HKWorkout, completion: @escaping ([RunSplit]) -> Void) {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion([])
            return
        }

        let predicate = HKQuery.predicateForObjects(from: workout)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: distanceType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                completion([])
                return
            }

            var splits: [RunSplit] = []
            var cumulative: Double = 0
            var nextKm: Double = 1000
            var lastSplitTime: Date = samples.first?.startDate ?? workout.startDate

            for sample in samples {
                let meters = sample.quantity.doubleValue(for: .meter())
                cumulative += meters

                while cumulative >= nextKm {
                    let splitTime = sample.endDate
                    let splitDuration = splitTime.timeIntervalSince(lastSplitTime)
                    let pace = splitDuration / 60.0
                    let kmIndex = Int(nextKm / 1000)
                    splits.append(RunSplit(kilometer: kmIndex, pace: pace, elevationChange: 0))
                    lastSplitTime = splitTime
                    nextKm += 1000
                }
            }

            completion(splits)
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

    var onMetrics: ((HealthKitMetrics) -> Void)?
    var onStateChange: ((HKWorkoutSessionState) -> Void)?

    init(healthStore: HKHealthStore, session: HKWorkoutSession, builder: HKLiveWorkoutBuilder) {
        self.healthStore = healthStore
        self.session = session
        self.builder = builder
        super.init()
        session.delegate = self
        builder.delegate = self
    }

    func start() {
        let startDate = Date()
        session.startActivity(with: startDate)
        builder.beginCollection(withStart: startDate) { _, _ in }
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
                DispatchQueue.main.async { completion?(workout) }
            }
        }
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

        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount), collectedTypes.contains(stepsType),
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

//
//  WatchConnectivityManager.swift
//  vyefit
//
//  Watch integration is intentionally disabled.
//

import Foundation
import SwiftUI

@MainActor
final class WatchConnectivityManager: ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published private(set) var isReachable: Bool = false
    @Published private(set) var isPaired: Bool = false
    @Published private(set) var isWatchAppInstalled: Bool = false

    var onMetrics: ((WatchMetricsPayload) -> Void)?
    var onPauseFromWatch: (() -> Void)?
    var onResumeFromWatch: (() -> Void)?
    var onEndFromWatch: (() -> Void)?
    var onStartFromWatch: ((String, String, String?) -> Void)?

    private init() {}

    func activate() {}
    func updateApplicationContext() {}
    func sendStartWorkout(activity: String, location: String, workoutId: String? = nil) {}
    func endWorkout() {}
    func pauseWorkout() {}
    func resumeWorkout() {}
}

struct WatchMetricsPayload {
    let activity: String
    let elapsedSeconds: Int
    let distanceMeters: Double
    let activeEnergyKcal: Double
    let heartRateBpm: Double
    let cadenceSpm: Double
}

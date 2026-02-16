//
//  HealthIntegrationView.swift
//  vyefit
//
//  Detail screen for health integrations.
//

import SwiftUI

struct HealthIntegrationView: View {
    @AppStorage("healthReadWorkouts") private var healthReadWorkouts = true
    @AppStorage("healthWriteWorkouts") private var healthWriteWorkouts = false
    @AppStorage("healthReadVitals") private var healthReadVitals = true
    @AppStorage("healthMindfulMinutes") private var healthMindfulMinutes = false
    @AppStorage("connectStrava") private var connectStrava = false
    @AppStorage("connectGarmin") private var connectGarmin = false
    @StateObject private var healthManager = HealthKitManager.shared
    @State private var lastSyncText: String = "Not synced yet"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard("Apple Health") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Read workouts", isOn: $healthReadWorkouts)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)
                            .onChange(of: healthReadWorkouts) { _, _ in
                                requestAuthorization()
                            }

                        Toggle("Write workouts", isOn: $healthWriteWorkouts)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)
                            .onChange(of: healthWriteWorkouts) { _, _ in
                                requestAuthorization()
                            }

                        Toggle("Read heart rate & vitals", isOn: $healthReadVitals)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)
                            .onChange(of: healthReadVitals) { _, _ in
                                requestAuthorization()
                            }

                        Toggle("Share mindful minutes", isOn: $healthMindfulMinutes)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)
                            .disabled(true)
                            .opacity(0.45)

                        Divider()

                        Text(healthManager.isAuthorized ? "Connected" : "Not connected")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(healthManager.isAuthorized ? Theme.sage : Theme.textSecondary)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last sync")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                                Text(lastSyncText)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Spacer()
                            Button("Sync Now") {
                                syncHistory()
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.cream)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Theme.terracotta)
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                        }
                    }
                }

                SettingsCard("Connected Apps") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Strava", isOn: $connectStrava)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.terracotta)
                            .disabled(true)
                            .opacity(0.45)

                        Toggle("Garmin", isOn: $connectGarmin)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.terracotta)
                            .disabled(true)
                            .opacity(0.45)

                        Text("Strava and Garmin are not connected in this build.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("Health Integration")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            healthManager.refreshAuthorizationStatus()
            refreshSyncLabel()
        }
    }

    private func requestAuthorization() {
        healthManager.requestAuthorization(
            readWorkouts: healthReadWorkouts,
            writeWorkouts: healthWriteWorkouts,
            readVitals: healthReadVitals
        ) { _, _ in }
    }

    private func syncHistory() {
        healthManager.importLatestWorkoutsIfNeeded(force: true) { _ in
            refreshSyncLabel()
        }
    }

    private func refreshSyncLabel() {
        let lastSync = UserDefaults.standard.object(forKey: "healthLastSyncDate") as? Date
        if let lastSync {
            lastSyncText = lastSync.formatted(date: .abbreviated, time: .shortened)
        } else {
            lastSyncText = "Not synced yet"
        }
    }
}

#Preview {
    NavigationStack {
        HealthIntegrationView()
    }
}

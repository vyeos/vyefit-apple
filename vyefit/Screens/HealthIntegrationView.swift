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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard("Apple Health") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Read workouts", isOn: $healthReadWorkouts)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)

                        Toggle("Write workouts", isOn: $healthWriteWorkouts)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)

                        Toggle("Read heart rate & vitals", isOn: $healthReadVitals)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)

                        Toggle("Share mindful minutes", isOn: $healthMindfulMinutes)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)
                    }
                }

                SettingsCard("Connected Apps") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Strava", isOn: $connectStrava)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.terracotta)

                        Toggle("Garmin", isOn: $connectGarmin)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.terracotta)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("Health Integration")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        HealthIntegrationView()
    }
}

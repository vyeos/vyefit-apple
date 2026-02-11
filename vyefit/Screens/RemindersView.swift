//
//  RemindersView.swift
//  vyefit
//
//  Detail screen for reminder preferences.
//

import SwiftUI

struct RemindersView: View {
    private enum HydrationInterval: Int, CaseIterable, Identifiable {
        case one = 1
        case two = 2
        case three = 3
        case four = 4

        var id: Int { rawValue }

        var label: String {
            "\(rawValue)h"
        }
    }

    @AppStorage("workoutReminders") private var workoutReminders = true
    @AppStorage("hydrationReminders") private var hydrationReminders = false
    @AppStorage("mindfulnessReminders") private var mindfulnessReminders = false
    @AppStorage("hydrationIntervalHours") private var hydrationIntervalHours = HydrationInterval.two.rawValue

    @State private var workoutTime = Date()
    @State private var hydrationTime = Date()
    @State private var mindfulnessTime = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard("Workout") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Workout reminders", isOn: $workoutReminders)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.terracotta)

                        reminderTimeRow(title: "Preferred time", date: $workoutTime, enabled: workoutReminders, tint: Theme.terracotta)
                    }
                }

                SettingsCard("Hydration") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Hydration check-ins", isOn: $hydrationReminders)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Check-in interval")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)

                            Picker("Check-in interval", selection: $hydrationIntervalHours) {
                                ForEach(HydrationInterval.allCases) { interval in
                                    Text(interval.label)
                                        .tag(interval.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(Theme.sage)
                        }
                        .opacity(hydrationReminders ? 1 : 0.45)
                        .disabled(!hydrationReminders)

                        reminderTimeRow(title: "First reminder", date: $hydrationTime, enabled: hydrationReminders, tint: Theme.sage)
                    }
                }

                SettingsCard("Mindfulness") {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Mindful minutes prompt", isOn: $mindfulnessReminders)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.stone)

                        Text("Prompts you to log short mindfulness breaks.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)

                        reminderTimeRow(title: "Preferred time", date: $mindfulnessTime, enabled: mindfulnessReminders, tint: Theme.stone)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.large)
    }

    private func reminderTimeRow(title: String, date: Binding<Date>, enabled: Bool, tint: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            DatePicker("", selection: date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(tint)
        }
        .opacity(enabled ? 1 : 0.45)
        .disabled(!enabled)
    }
}

#Preview {
    NavigationStack {
        RemindersView()
    }
}

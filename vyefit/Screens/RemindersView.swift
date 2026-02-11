//
//  RemindersView.swift
//  vyefit
//
//  Detail screen for reminder preferences.
//

import SwiftUI

struct RemindersView: View {
    @AppStorage("workoutReminders") private var workoutReminders = true
    @AppStorage("hydrationReminders") private var hydrationReminders = false
    @AppStorage("mindfulnessReminders") private var mindfulnessReminders = false

    @State private var workoutTime = Date()
    @State private var hydrationTime = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard("Workout") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Workout reminders", isOn: $workoutReminders)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.terracotta)

                        reminderTimeRow(title: "Preferred time", date: $workoutTime, enabled: workoutReminders)
                    }
                }

                SettingsCard("Hydration") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Hydration check-ins", isOn: $hydrationReminders)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)

                        reminderTimeRow(title: "First reminder", date: $hydrationTime, enabled: hydrationReminders)
                    }
                }

                SettingsCard("Mindfulness") {
                    Toggle("Mindful minutes prompt", isOn: $mindfulnessReminders)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.sage)
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.large)
    }

    private func reminderTimeRow(title: String, date: Binding<Date>, enabled: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            DatePicker("", selection: date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Theme.terracotta)
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

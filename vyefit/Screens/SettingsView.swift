//
//  SettingsView.swift
//  vyefit
//
//  Settings page accessible from You tab.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme = "System"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Settings
                VStack(spacing: 0) {
                    NavigationLink {
                        UnitsMeasurementsView()
                    } label: {
                        SettingRow(icon: "scalemass", title: "Units & Measurements")
                    }

                    NavigationLink {
                        HealthIntegrationView()
                    } label: {
                        SettingRow(icon: "heart", title: "Health Integration")
                    }

                    NavigationLink {
                        RemindersView()
                    } label: {
                        SettingRow(icon: "bell", title: "Reminders")
                    }

                    NavigationLink {
                        BackupSyncView()
                    } label: {
                        SettingRow(icon: "icloud", title: "Backup & Sync")
                    }
                }
                .buttonStyle(.plain)
                .tint(Theme.terracotta)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 20)

                // Appearance
                VStack(alignment: .leading, spacing: 12) {
                    Label("Appearance", systemImage: "paintbrush")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(.segmented)
                    .tint(Theme.terracotta)
                }
                .padding(20)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 20)
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

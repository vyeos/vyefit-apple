//
//  BackupSyncView.swift
//  vyefit
//
//  Detail screen for backup and sync preferences.
//

import SwiftUI

struct BackupSyncView: View {
    @AppStorage("syncEnabled") private var syncEnabled = true
    @AppStorage("wifiOnlyBackup") private var wifiOnlyBackup = true
    @AppStorage("autoBackup") private var autoBackup = true

    @State private var lastBackupDate: Date? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard("Sync") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("iCloud Sync", isOn: $syncEnabled)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)

                        Toggle("Wi-Fi only", isOn: $wifiOnlyBackup)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)
                            .disabled(!syncEnabled)
                            .opacity(syncEnabled ? 1 : 0.45)
                    }
                }

                SettingsCard("Backup") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Auto backup", isOn: $autoBackup)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.terracotta)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Last backup")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)

                                Text(lastBackupText)
                                    .font(.system(size: 15, weight: .semibold, design: .serif))
                                    .foregroundStyle(Theme.textPrimary)
                            }

                            Spacer()

                            Button("Back Up Now") {
                                lastBackupDate = Date()
                                syncEnabled = true
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
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("Backup & Sync")
        .navigationBarTitleDisplayMode(.large)
    }

    private var lastBackupText: String {
        guard let lastBackupDate else {
            return "Not backed up yet"
        }

        return lastBackupDate.formatted(date: .abbreviated, time: .shortened)
    }
}

#Preview {
    NavigationStack {
        BackupSyncView()
    }
}

//
//  ProfileView.swift
//  vyefit
//
//  You tab — user avatar, name, and settings list.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("userName") private var userName = "Rudra Patel"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Theme.sand)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(Theme.stone)
                            )

                        TextField("Your name", text: $userName)
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .tint(Theme.terracotta)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 24)

                        Text("Mindful Mover")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.sage)
                    }
                    .padding(.top)

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
                            AppearanceView()
                        } label: {
                            SettingRow(icon: "paintbrush", title: "Appearance")
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
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ProfileView()
}

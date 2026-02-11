//
//  ProfileView.swift
//  vyefit
//
//  You tab — user avatar, name, and settings list.
//

import SwiftUI

struct ProfileView: View {
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

                        Text("Rudra Patel")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)

                        Text("Mindful Mover")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.sage)
                    }
                    .padding(.top)

                    // Settings
                    VStack(spacing: 0) {
                        SettingRow(icon: "scalemass", title: "Units & Measurements")
                        SettingRow(icon: "heart", title: "Health Integration")
                        SettingRow(icon: "bell", title: "Reminders")
                        SettingRow(icon: "paintbrush", title: "Appearance")
                        SettingRow(icon: "icloud", title: "Backup & Sync")
                    }
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

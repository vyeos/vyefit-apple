//
//  AppearanceView.swift
//  vyefit
//
//  Detail screen for appearance preferences.
//

import SwiftUI

struct AppearanceView: View {
    private enum AppTheme: String, CaseIterable, Identifiable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var id: String { rawValue }
    }

    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard("Theme") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Theme", selection: $appTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.rawValue)
                                    .tag(theme.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Theme.terracotta)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
}

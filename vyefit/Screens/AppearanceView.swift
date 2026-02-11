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

    private enum AccentOption: String, CaseIterable, Identifiable {
        case terracotta = "Terracotta"
        case sage = "Sage"
        case stone = "Stone"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .terracotta:
                return Theme.terracotta
            case .sage:
                return Theme.sage
            case .stone:
                return Theme.stone
            }
        }
    }

    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue
    @AppStorage("accentColor") private var accentColor = AccentOption.terracotta.rawValue
    var body: some View {
        let accent = Theme.accent(for: accentColor)
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
                        .tint(accent)
                    }
                }

                SettingsCard("Accent Color") {
                    HStack(spacing: 14) {
                        ForEach(AccentOption.allCases) { option in
                            Button {
                                accentColor = option.rawValue
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Theme.bark, lineWidth: accentColor == option.rawValue ? 2 : 0)
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Theme.textPrimary)
                                            .opacity(accentColor == option.rawValue ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(option.rawValue))
                        }

                        Spacer()
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

//
//  SettingRow.swift
//  vyefit
//
//  Single settings row with icon, title, and chevron.
//

import SwiftUI

struct SettingRow: View {
    let icon: String
    let title: String
    @AppStorage("accentColor") private var accentColor = "Terracotta"

    private var accent: Color {
        Theme.accent(for: accentColor)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(accent)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accent.opacity(0.6))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 0) {
        SettingRow(icon: "scalemass", title: "Units & Measurements")
        SettingRow(icon: "heart", title: "Health Integration")
    }
    .background(Theme.cream)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .padding()
}

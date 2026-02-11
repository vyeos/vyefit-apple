//
//  WellnessCard.swift
//  vyefit
//
//  Small stat card used on the dashboard for key metrics.
//

import SwiftUI

struct WellnessCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    HStack(spacing: 14) {
        WellnessCard(icon: "flame.fill", value: "4", label: "Workouts\nthis week", color: Theme.terracotta)
        WellnessCard(icon: "heart.fill", value: "152", label: "Avg Heart\nRate", color: Theme.sage)
    }
    .padding()
    .background(Theme.background)
}

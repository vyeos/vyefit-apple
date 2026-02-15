//
//  RunMiniStat.swift
//  vyefit
//
//  Small stat cell used in the Run screen's summary grid.
//

import SwiftUI

struct RunMiniStat: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
        RunMiniStat(value: "25.8", unit: "km", label: "Distance")
        RunMiniStat(value: "5:00", unit: "/km", label: "Best Pace")
        RunMiniStat(value: "2,070", unit: "kcal", label: "Burned")
    }
    .background(Theme.cream)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .padding()
}

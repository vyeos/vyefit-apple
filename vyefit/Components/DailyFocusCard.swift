//
//  DailyFocusCard.swift
//  vyefit
//
//  Card showing today's planned workout with a begin button.
//

import SwiftUI

struct DailyFocusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Focus")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(spacing: 14) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.terracotta)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Push Day")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                    Text("2 exercises planned")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Button {
                } label: {
                    Text("Begin")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.terracotta)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}

#Preview {
    DailyFocusCard()
        .background(Theme.background)
}

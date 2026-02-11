//
//  MilestoneRow.swift
//  vyefit
//
//  Achievement/milestone row with progress indicator.
//

import SwiftUI

struct MilestoneRow: View {
    let achievement: MockAchievement

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: achievement.icon)
                .font(.system(size: 16))
                .foregroundStyle(achievement.isUnlocked ? Theme.terracotta : Theme.stone)
                .frame(width: 38, height: 38)
                .background(achievement.isUnlocked ? Theme.terracotta.opacity(0.1) : Theme.sand)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Text(achievement.description)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.sage)
            } else {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.sand)
                        .frame(width: 50, height: 4)
                    Capsule()
                        .fill(Theme.sage)
                        .frame(width: 50 * achievement.progress, height: 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
}

#Preview {
    VStack {
        MilestoneRow(achievement: SampleData.achievements[0])
        MilestoneRow(achievement: SampleData.achievements[2])
    }
    .background(Theme.background)
}

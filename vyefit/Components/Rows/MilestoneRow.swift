//
//  MilestoneRow.swift
//  vyefit
//
//  Achievement/milestone row with progress indicator.
//

import SwiftUI

struct MilestoneRow: View {
    let achievement: Achievement

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
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(achievement.progress * 100))%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.sage)
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.stone.opacity(0.35))
                            .frame(width: 60, height: 6)
                        Capsule()
                            .fill(Theme.sage)
                            .frame(width: 60 * achievement.progress, height: 6)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

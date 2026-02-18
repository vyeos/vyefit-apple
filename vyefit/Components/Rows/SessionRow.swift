//
//  SessionRow.swift
//  vyefit
//
//  Workout session row used in lists.
//

import SwiftUI

struct SessionRow: View {
    let session: WorkoutSessionRecord

    var body: some View {
        NavigationLink(destination: SessionDetailView(workoutSession: session)) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.terracotta.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.terracotta)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.name)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if session.exerciseCount > 0 {
                            Text("\(session.exerciseCount) exercises")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                            Text("•")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.stone)
                        }

                        Text(session.date, format: .dateTime.weekday(.abbreviated))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.terracotta)
                        Text("\(session.calories)")
                            .foregroundStyle(Theme.terracotta)
                    }
                    .font(.system(size: 12, weight: .medium))

                    Text(formatDuration(session.duration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.stone)
                }
            }
            .padding(12)
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

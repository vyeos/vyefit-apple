//
//  WorkoutCard.swift
//  vyefit
//
//  Card displaying a workout with its exercises and a start button.
//

import SwiftUI

struct WorkoutCard: View {
    let workout: MockWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(workout.name)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(SampleData.relativeDateString(workout.lastPerformed))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }

            Divider()
                .background(Theme.sand)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(workout.exercises) { exercise in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.sage.opacity(0.5))
                            .frame(width: 6, height: 6)
                        Text(exercise.name)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text("\(exercise.sets.count) sets")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.stone)
                    }
                }
            }

            Button {
            } label: {
                Text("Start")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.terracotta)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(18)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    WorkoutCard(workout: SampleData.workouts[0])
        .padding()
        .background(Theme.background)
}

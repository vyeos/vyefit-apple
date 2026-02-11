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
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: workout.icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.terracotta)
                .frame(width: 38, height: 38)
                .background(Theme.terracotta.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(workout.name)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)

            Text("\(workout.exercises.count) exercises")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 0)

            Text(SampleData.relativeDateString(workout.lastPerformed))
                .font(.system(size: 10))
                .foregroundStyle(Theme.stone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
        WorkoutCard(workout: SampleData.workouts[0])
        WorkoutCard(workout: SampleData.workouts[1])
        WorkoutCard(workout: SampleData.workouts[2])
        WorkoutCard(workout: SampleData.workouts[3])
    }
    .padding(20)
    .background(Theme.background)
}

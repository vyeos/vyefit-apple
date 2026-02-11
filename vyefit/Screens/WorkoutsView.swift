//
//  WorkoutsView.swift
//  vyefit
//
//  Train tab — list of workouts with exercises and start button.
//

import SwiftUI

struct WorkoutsView: View {
    @Environment(WorkoutStore.self) private var workoutStore
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // User-created workouts
                    if !workoutStore.workouts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MY WORKOUTS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .tracking(1)
                                .padding(.leading, 4)

                            ForEach(workoutStore.workouts) { workout in
                                UserWorkoutCard(
                                    workout: workout,
                                    onDelete: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            workoutStore.remove(id: workout.id)
                                        }
                                    }
                                )
                            }
                        }

                        Divider()
                            .background(Theme.sand)
                            .padding(.vertical, 4)

                        Text("TEMPLATES")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .tracking(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                    }

                    // Sample/template workouts
                    ForEach(SampleData.workouts) { workout in
                        WorkoutCard(workout: workout)
                    }

                }
                .padding(20)
            }
            .background(Theme.background)
                .navigationTitle("Train")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showCreateSheet = true } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Create Workout")
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                            }
                            .foregroundStyle(Theme.terracotta)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .clipShape(Capsule())
                        }
                    }
                }
            .sheet(isPresented: $showCreateSheet) {
                CreateWorkoutView()
            }
        }
    }
}

// MARK: - User Workout Card

struct UserWorkoutCard: View {
    let workout: UserWorkout
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: workout.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.terracotta)
                    .frame(width: 30, height: 30)
                    .background(Theme.terracotta.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(workout.name)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.stone)
                        .frame(width: 28, height: 28)
                }
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
                        Text(exercise.muscleGroup)
                            .font(.system(size: 10))
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
    WorkoutsView()
        .environment(WorkoutStore())
}

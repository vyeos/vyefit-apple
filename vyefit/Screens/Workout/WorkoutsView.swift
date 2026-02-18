//
//  WorkoutsView.swift
//  vyefit
//
//  Train tab — list of workouts with exercises and start button.
//

import SwiftUI

struct WorkoutsView: View {
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(RunStore.self) private var runStore
    @State private var showCreateSheet = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var editingWorkout: UserWorkout?
    @State private var showActiveSessionAlert = false
    @State private var workoutToConfirmStart: UserWorkout?
    @State private var collapsedWorkoutIDs: Set<UUID> = []

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
                                    isCollapsed: Binding(
                                        get: { collapsedWorkoutIDs.contains(workout.id) },
                                        set: { isCollapsed in
                                            if isCollapsed {
                                                collapsedWorkoutIDs.insert(workout.id)
                                            } else {
                                                collapsedWorkoutIDs.remove(workout.id)
                                            }
                                        }
                                    ),
                                    onEdit: {
                                        editingWorkout = workout
                                    },
                                    onDelete: {
							        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
							        	withAnimation(.easeInOut(duration: 0.25)) {
							        		workoutStore.remove(id: workout.id)
                                            collapsedWorkoutIDs.remove(workout.id)
							        	}
							        }
                                    },
                                    onStart: {
                                        if workoutStore.activeSession != nil || runStore.activeSession != nil {
                                            showActiveSessionAlert = true
                                        } else {
                                            workoutToConfirmStart = workout
                                        }
                                    }
                                )
                            }
                        }

                        Divider()
                            .background(Theme.sand)
                            .padding(.vertical, 4)
                    }

                    Text("TEMPLATES")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .tracking(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 4)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                        ForEach(Templates.workouts) { workout in
                            Button { selectedTemplate = workout } label: {
                                WorkoutCard(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
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
            .sheet(item: $selectedTemplate) { template in
                CreateWorkoutView(template: template)
            }
            .sheet(item: $editingWorkout) { workout in
                CreateWorkoutView(editing: workout)
            }
            .alert("Session in Progress", isPresented: $showActiveSessionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if runStore.activeSession != nil {
                    Text("Please finish your current run before starting a new workout.")
                } else {
                    Text("Please finish your current workout before starting a new one.")
                }
            }
            .alert(
                "Start Workout?",
                isPresented: Binding(
                    get: { workoutToConfirmStart != nil },
                    set: { isPresented in
                        if !isPresented {
                            workoutToConfirmStart = nil
                        }
                    }
                ),
                presenting: workoutToConfirmStart
            ) { workout in
                Button("Cancel", role: .cancel) { }
                Button("Start") {
                    workoutStore.startSession(for: workout)
                    workoutToConfirmStart = nil
                }
            } message: { workout in
                Text("Start \(workout.name)?")
            }
        }
    }
}

// MARK: - User Workout Card

struct UserWorkoutCard: View {
    let workout: UserWorkout
    @Binding var isCollapsed: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onStart: () -> Void

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

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.stone)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
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

            if !isCollapsed {
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
                    onStart()
                } label: {
                    Text("Start")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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

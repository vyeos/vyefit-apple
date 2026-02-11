//
//  ActiveWorkoutView.swift
//  vyefit
//
//  The main tracking screen during a workout.
//

import SwiftUI
import UIKit

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @State private var showEndConfirmation = false
    @State private var showAppleWatchPrompt = false
    var onEnd: () -> Void
    
    init(session: WorkoutSession, onEnd: @escaping () -> Void) {
        self.session = session
        self.onEnd = onEnd
    }
    
    var body: some View {
        NavigationStack {
            TabView {
                LogView(session: session)
                    .tabItem {
                        Label("Log", systemImage: "list.bullet.clipboard")
                    }
                
                StatsView(session: session)
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
            }
            .tint(Theme.terracotta)
            .toolbarBackground(Theme.background, for: .bottomBar)
            .toolbarBackground(.visible, for: .bottomBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(session.workout.name)
                            .font(.headline)
                        Text(formatDuration(session.elapsedSeconds))
                            .font(.caption)
                            .foregroundStyle(Theme.terracotta)
                            .monospacedDigit()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Minimize") {
                        dismiss()
                    }
                    .font(.system(size: 14))
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End") {
                        showEndConfirmation = true
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.terracotta)
                }
            }
            .alert("End Workout?", isPresented: $showEndConfirmation) {
                Button("End Workout", role: .destructive) {
                    onEnd()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Start on Apple Watch?", isPresented: $showAppleWatchPrompt) {
                Button("Start \(session.workout.workoutType.rawValue)") {
                    // Logic to start HKWorkoutSession would go here
                }
                Button("Skip", role: .cancel) { }
            } message: {
                Text("Do you want to track this \(session.workout.workoutType.rawValue) workout on your Apple Watch?")
            }
            .onAppear {
                if !session.hasShownWatchPrompt {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAppleWatchPrompt = true
                        session.hasShownWatchPrompt = true
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

struct LogView: View {
    var session: WorkoutSession
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    if session.state != .paused {
                        if session.isResting {
                            RestTimerBanner(session: session)
                        } else {
                            StartNextSetBanner()
                        }
                    }
                    
                    ForEach(Array(session.activeExercises.enumerated()), id: \.element.id) { index, activeExercise in
                        ExerciseLogCard(session: session, exerciseIndex: index)
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            if session.state == .paused {
                // Full screen overlay with touch blocking and blur
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { }
                
                VStack(spacing: 16) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.sage)
                    Text("Workout Paused")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Button {
                        withAnimation { session.togglePause() }
                    } label: {
                        Text("Resume")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Theme.sage)
                            .clipShape(Capsule())
                    }
                }
                .padding(32)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            }
        }
    }
}

struct RestTimerBanner: View {
    var session: WorkoutSession
    
    var body: some View {
        HStack {
            Image(systemName: "timer")
                .font(.title2)
            VStack(alignment: .leading) {
                Text("Resting")
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                Text(formatRestTime(session.restSecondsRemaining))
                    .font(.title3)
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }
            Spacer()
            Button("Skip") {
                withAnimation {
                    session.cancelRestTimer()
                }
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding()
        .background(Theme.terracotta)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct StartNextSetBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "dumbbell.fill")
                .font(.title2)
            VStack(alignment: .leading) {
                Text("Ready")
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                Text("Start Next Set")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding()
        .background(Theme.sage)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ExerciseLogCard: View {
    var session: WorkoutSession
    let exerciseIndex: Int
    @State private var weightUnit = "kg"
    
    var activeExercise: ActiveExercise {
        session.activeExercises[exerciseIndex]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: activeExercise.exercise.icon)
                    .foregroundStyle(Theme.terracotta)
                Text(activeExercise.exercise.name)
                    .font(.headline)
                Spacer()
                
                Picker("Unit", selection: $weightUnit) {
                    Text("kg").tag("kg")
                    Text("lbs").tag("lbs")
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
            }
            
            Divider()
            
            // Header
            HStack {
                Text("Set")
                    .frame(width: 30)
                Text("Previous")
                    .frame(maxWidth: .infinity)
                Text(weightUnit)
                    .frame(width: 60)
                Text("Reps")
                    .frame(width: 60)
                Text("✓")
                    .frame(width: 40)
                Spacer()
                    .frame(width: 30)
            }
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
            
            // Sets
            ForEach(Array(activeExercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                SetRow(
                    setIndex: setIndex + 1,
                    set: set,
                    onToggle: {
                        session.completeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
                    },
                    onUpdate: { reps, weight in
                        session.activeExercises[exerciseIndex].sets[setIndex].reps = reps
                        session.activeExercises[exerciseIndex].sets[setIndex].weight = weight
                    },
                    onDelete: {
                        withAnimation {
                            session.removeSet(from: exerciseIndex, at: setIndex)
                        }
                    }
                )
            }
            
            Button {
                withAnimation {
                    session.addSet(to: exerciseIndex)
                }
            } label: {
                Text("+ Add Set")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.terracotta)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.terracotta.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SetRow: View {
    let setIndex: Int
    let set: WorkoutSet
    let onToggle: () -> Void
    let onUpdate: (Int?, Double?) -> Void
    let onDelete: () -> Void
    
    @State private var weightText: String
    @State private var repsText: String
    
    init(setIndex: Int, set: WorkoutSet, onToggle: @escaping () -> Void, onUpdate: @escaping (Int?, Double?) -> Void, onDelete: @escaping () -> Void) {
        self.setIndex = setIndex
        self.set = set
        self.onToggle = onToggle
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        
        _weightText = State(initialValue: set.weight.map { String($0) } ?? "")
        _repsText = State(initialValue: set.reps.map { String($0) } ?? "")
    }
    
    var body: some View {
        HStack {
            Text("\(setIndex)")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 30)
                .foregroundStyle(Theme.stone)
            
            Text("-") // Placeholder for previous
                .font(.system(size: 14))
                .foregroundStyle(Theme.stone)
                .frame(maxWidth: .infinity)
            
            TextField("-", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .padding(.vertical, 8)
                .background(set.isCompleted ? Theme.sage.opacity(0.2) : Theme.sand)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: weightText) { _, newValue in
                    onUpdate(Int(repsText), Double(newValue))
                }
            
            TextField("-", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .padding(.vertical, 8)
                .background(set.isCompleted ? Theme.sage.opacity(0.2) : Theme.sand)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: repsText) { _, newValue in
                    onUpdate(Int(newValue), Double(weightText))
                }
            
            Button {
                onToggle()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? Theme.sage : Theme.stone.opacity(0.3))
            }
            .frame(width: 40)
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.stone.opacity(0.5))
            }
            .frame(width: 30)
        }
    }
}

struct StatsView: View {
    var session: WorkoutSession
    
    var body: some View {
        VStack(spacing: 20) {
            StatsCard(
                title: "Heart Rate",
                value: "\(session.currentHeartRate)",
                unit: "BPM",
                icon: "heart.fill",
                color: .red
            )
            
            StatsCard(
                title: "Active Calories",
                value: "\(session.activeCalories)",
                unit: "KCAL",
                icon: "flame.fill",
                color: .orange
            )
            
            StatsCard(
                title: "Time",
                value: formatDuration(session.elapsedSeconds),
                unit: "ELAPSED",
                icon: "clock.fill",
                color: .blue
            )
            
            Button {
                withAnimation {
                    session.togglePause()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: session.state == .active ? "pause.fill" : "play.fill")
                    Text(session.state == .active ? "Pause Workout" : "Resume Workout")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(session.state == .active ? Theme.terracotta : Theme.sage)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.background)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.stone)
                }
            }
            Spacer()
        }
        .padding()
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ActiveWorkoutView(
        session: WorkoutSession(workout: UserWorkout(id: UUID(), name: "Test Workout", workoutType: .traditionalStrengthTraining, exercises: [], icon: "dumbbell.fill", createdAt: Date())),
        onEnd: {}
    )
}

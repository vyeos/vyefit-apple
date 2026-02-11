//
//  MiniWorkoutPlayer.swift
//  vyefit
//
//  Floating mini-player for active workout when minimized.
//

import SwiftUI

struct MiniWorkoutPlayer: View {
    @Bindable var session: WorkoutSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: session.workout.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.terracotta)
                    .frame(width: 44, height: 44)
                    .background(Theme.terracotta.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.workout.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Group {
                        if session.state == .paused {
                            HStack(spacing: 4) {
                                Image(systemName: "pause.fill")
                                Text("Paused")
                            }
                            .foregroundStyle(Theme.sage)
                        } else if session.isResting {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                Text("Resting: \(formatDuration(session.restSecondsRemaining))")
                            }
                            .foregroundStyle(Theme.terracotta)
                        } else {
                            Text(currentExerciseName)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                
                Spacer()
                
                // Timer
                Text(formatDuration(session.elapsedSeconds))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                
                // Expand indicator
                Image(systemName: "chevron.up")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(10)
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 8) // Lift up from tab bar slightly if needed, or put above it
        }
        .buttonStyle(.plain)
    }
    
    private var currentExerciseName: String {
        guard session.currentExerciseIndex < session.activeExercises.count else { return "Workout" }
        return session.activeExercises[session.currentExerciseIndex].exercise.name
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if seconds >= 3600 {
            let h = seconds / 3600
            return String(format: "%d:%02d:%02d", h, m % 60, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

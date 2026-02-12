//
//  ActiveRunView.swift
//  vyefit
//
//  The main tracking screen during a run with big primary stat.
//

import SwiftUI

struct ActiveRunView: View {
    @Bindable var session: RunSession
    @Environment(\.dismiss) private var dismiss
    @State private var showEndConfirmation = false
    var onEnd: () -> Void
    @AppStorage("distanceUnit") private var distanceUnit = "Kilometers"
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    primaryMetricView
                    
                    secondaryMetricsGrid
                    
                    Spacer()
                    
                    controlButtons
                }
                .padding()
                .background(Theme.background)
                
                if session.state == .paused {
                    pausedOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            .alert("End Run?", isPresented: $showEndConfirmation) {
                Button("End Run", role: .destructive) {
                    onEnd()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    @ViewBuilder
    private var primaryMetricView: some View {
        VStack(spacing: 12) {
            Text(primaryMetricLabel)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
            
            Text(primaryMetricValue)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
            
            if let remaining = session.targetRemaining {
                Text(remaining)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.sage)
            }
            
            if let progress = session.targetProgress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Theme.terracotta)
                    .frame(width: 200)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var primaryMetricLabel: String {
        switch session.primaryMetric {
        case .distance: return "Distance"
        case .time: return "Time"
        case .calories: return "Calories"
        case .pace: return "Pace"
        case .heartRate: return "Heart Rate"
        case .quickStart: return "Time"
        case .intervals: return "Time"
        }
    }
    
    private var primaryMetricValue: String {
        switch session.primaryMetric {
        case .distance:
            let dist = distanceUnit == "Kilometers" ? session.currentDistance : session.currentDistance * 0.621371
            return String(format: "%.2f", dist)
        case .time, .quickStart, .intervals:
            return session.formattedTime
        case .calories:
            return "\(session.activeCalories)"
        case .pace:
            return session.currentPace
        case .heartRate:
            return "\(session.currentHeartRate)"
        }
    }
    
    private var secondaryMetricsGrid: some View {
        let metrics = secondaryMetrics
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(metrics, id: \.label) { metric in
                SecondaryMetricCard(
                    label: metric.label,
                    value: metric.value,
                    unit: metric.unit,
                    icon: metric.icon
                )
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var secondaryMetrics: [(label: String, value: String, unit: String, icon: String)] {
        var metrics: [(label: String, value: String, unit: String, icon: String)] = []
        
        switch session.primaryMetric {
        case .distance:
            metrics.append(("Time", session.formattedTime, "", "clock"))
            metrics.append(("Pace", session.currentPace, "/\(distanceUnit == "Kilometers" ? "km" : "mi")", "speedometer"))
        case .time, .quickStart:
            let dist = distanceUnit == "Kilometers" ? session.currentDistance : session.currentDistance * 0.621371
            metrics.append(("Distance", String(format: "%.2f", dist), distanceUnit == "Kilometers" ? "km" : "mi", "map"))
            metrics.append(("Pace", session.currentPace, "/\(distanceUnit == "Kilometers" ? "km" : "mi")", "speedometer"))
        case .calories:
            metrics.append(("Time", session.formattedTime, "", "clock"))
            let dist = distanceUnit == "Kilometers" ? session.currentDistance : session.currentDistance * 0.621371
            metrics.append(("Distance", String(format: "%.2f", dist), distanceUnit == "Kilometers" ? "km" : "mi", "map"))
        case .pace:
            metrics.append(("Time", session.formattedTime, "", "clock"))
            let dist = distanceUnit == "Kilometers" ? session.currentDistance : session.currentDistance * 0.621371
            metrics.append(("Distance", String(format: "%.2f", dist), distanceUnit == "Kilometers" ? "km" : "mi", "map"))
        case .heartRate:
            metrics.append(("Time", session.formattedTime, "", "clock"))
            let dist = distanceUnit == "Kilometers" ? session.currentDistance : session.currentDistance * 0.621371
            metrics.append(("Distance", String(format: "%.2f", dist), distanceUnit == "Kilometers" ? "km" : "mi", "map"))
        case .intervals:
            let dist = distanceUnit == "Kilometers" ? session.currentDistance : session.currentDistance * 0.621371
            metrics.append(("Distance", String(format: "%.2f", dist), distanceUnit == "Kilometers" ? "km" : "mi", "map"))
            metrics.append(("Pace", session.currentPace, "/\(distanceUnit == "Kilometers" ? "km" : "mi")", "speedometer"))
        }
        
        metrics.append(("Heart Rate", "\(session.currentHeartRate)", "bpm", "heart.fill"))
        metrics.append(("Calories", "\(session.activeCalories)", "kcal", "flame.fill"))
        
        return metrics
    }
    
    private var controlButtons: some View {
        VStack(spacing: 16) {
            Button {
                withAnimation {
                    session.togglePause()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: session.state == .active ? "pause.fill" : "play.fill")
                    Text(session.state == .active ? "Pause Run" : "Resume Run")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(session.state == .active ? Theme.terracotta : Theme.sage)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var pausedOverlay: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.sage)
                Text("Run Paused")
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
        .contentShape(Rectangle())
        .onTapGesture { }
    }
}

struct SecondaryMetricCard: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.stone)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ActiveRunView(
        session: RunSession(configuration: RunConfiguration(type: .distance, targetValue: 5.0)),
        onEnd: {}
    )
}

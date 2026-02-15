//
//  MiniRunPlayer.swift
//  vyefit
//
//  Floating mini-player for active run when minimized.
//

import SwiftUI

struct MiniRunPlayer: View {
    @Bindable var session: RunSession
    let onTap: () -> Void
    @AppStorage("distanceUnit") private var distanceUnit = "Kilometers"
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "figure.run")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.terracotta)
                    .frame(width: 44, height: 44)
                    .background(Theme.terracotta.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(runTypeLabel)
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
                        } else {
                            Text(primaryMetricSummary)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                
                Spacer()
                
                Text(session.formattedTime)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                
                Image(systemName: "chevron.up")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(10)
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Theme.bark.opacity(0.12), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
    }
    
    private var runTypeLabel: String {
        switch session.configuration.type {
        case .quickStart: return "Quick Run"
        case .time: return "Time Run"
        case .distance: return "Distance Run"
        case .pace: return "Pace Run"
        case .calories: return "Calorie Run"
        case .heartRate: return "HR Zone Run"
        case .intervals: return "Interval Run"
        }
    }
    
    private var primaryMetricSummary: String {
        let unit = distanceUnit == "Kilometers" ? "km" : "mi"
        let dist = distanceUnit == "Kilometers" ? session.currentDistance : session.currentDistance * 0.621371
        
        switch session.configuration.type {
        case .distance:
            return String(format: "%.2f %@", dist, unit)
        case .time:
            return session.formattedTime
        case .calories:
            return "\(session.activeCalories) kcal"
        case .pace:
            return session.currentPace + " min/\(unit)"
        case .heartRate:
            return "\(session.currentHeartRate) bpm"
        default:
            return String(format: "%.2f %@", dist, unit)
        }
    }
}

#Preview {
    MiniRunPlayer(
        session: RunSession(configuration: RunConfiguration(type: .distance, targetValue: 5.0)),
        onTap: {}
    )
}

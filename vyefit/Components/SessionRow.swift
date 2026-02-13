//
//  SessionRow.swift
//  vyefit
//
//  Run session row used on Dashboard and Run screens.
//

import SwiftUI

struct SessionRow: View {
    let run: MockRunSession

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.sage.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: run.type.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.sage)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(run.type.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                
                HStack(spacing: 6) {
                    Text(String(format: "%.2f km", run.distance))
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("•")
                        .foregroundStyle(Theme.stone)
                    
                    Text(run.date, format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(Theme.textSecondary)
                }
                .font(.system(size: 13))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.terracotta)
                    Text("\(run.calories)")
                        .foregroundStyle(Theme.terracotta)
                }
                .font(.system(size: 12, weight: .medium))
                
                Text(SampleData.formatDuration(run.duration))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.stone)
            }
        }
        .padding(12)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 8) {
        SessionRow(run: SampleData.runSessions[0])
            .padding(.horizontal, 20)
        SessionRow(run: SampleData.runSessions[1])
            .padding(.horizontal, 20)
    }
    .padding(.vertical)
    .background(Theme.background)
}

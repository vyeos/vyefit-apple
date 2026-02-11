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
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.sage)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(run.distance, specifier: "%.1f") km Run")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Text(run.date, style: .date)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text(SampleData.formatDuration(run.duration))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.stone)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
}

#Preview {
    SessionRow(run: SampleData.runSessions[0])
        .background(Theme.background)
}

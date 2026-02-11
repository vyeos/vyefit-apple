//
//  JournalEntryRow.swift
//  vyefit
//
//  Single day entry in the weekly journal reflection.
//

import SwiftUI

struct JournalEntryRow: View {
    let day: String
    let activity: String
    let mood: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.sage)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(day)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Text(activity)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text(mood)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.sage)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.sage.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        JournalEntryRow(day: "Monday", activity: "Push Day - Bench Press, OHP", mood: "energized")
        JournalEntryRow(day: "Tuesday", activity: "Rest Day", mood: "recovered")
    }
    .padding()
}

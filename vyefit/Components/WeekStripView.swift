//
//  WeekStripView.swift
//  vyefit
//
//  Horizontal week calendar strip showing scheduled workout days.
//

import SwiftUI

struct WeekStripView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 0) {
                ForEach(SampleData.weekSchedule) { day in
                    VStack(spacing: 10) {
                        Text(day.shortName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(day.isToday ? .white : Theme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(day.isToday ? Theme.terracotta : Color.clear)
                            .clipShape(Circle())

                        if day.workout != nil {
                            Circle()
                                .fill(Theme.sage)
                                .frame(width: 6, height: 6)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}

#Preview {
    WeekStripView()
        .background(Theme.background)
}

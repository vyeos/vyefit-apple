//
//  RunView.swift
//  vyefit
//
//  Run tab — start running, stats summary, and run history.
//

import SwiftUI

struct RunView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Gentle start
                    VStack(spacing: 18) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.sage)

                        Text("Time for a run")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)

                        Text("Fresh air and movement")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)

                        Button {
                        } label: {
                            Text("Start Running")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.sage)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(28)
                    .background(Theme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 20)

                    // Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                        RunMiniStat(value: "25.8", unit: "km", label: "Distance")
                        RunMiniStat(value: "5:00", unit: "/km", label: "Best Pace")
                        RunMiniStat(value: "2,070", unit: "kcal", label: "Burned")
                    }
                    .background(Theme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 20)

                    // Run history
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past Runs")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 20)

                        ForEach(SampleData.runSessions) { run in
                            SessionRow(run: run)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("Run")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    RunView()
}

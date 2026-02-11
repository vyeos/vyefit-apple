//
//  WorkoutsView.swift
//  vyefit
//
//  Train tab — list of workouts with exercises and start button.
//

import SwiftUI

struct WorkoutsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(SampleData.workouts) { workout in
                        WorkoutCard(workout: workout)
                    }

                    Button {
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14))
                            Text("New Workout")
                                .font(.system(size: 14, weight: .medium, design: .serif))
                        }
                        .foregroundStyle(Theme.terracotta)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(Theme.terracotta.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                    }
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle("Train")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    WorkoutsView()
}

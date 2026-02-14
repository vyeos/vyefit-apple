//
//  RunView.swift
//  vyefit
//
//  Run tab — start various run types, view stats and history.
//

import SwiftUI
import os.log

struct RunView: View {
    @Environment(RunStore.self) private var runStore
    @Environment(WorkoutStore.self) private var workoutStore
    @State private var selectedRunType: RunGoalType?
    @State private var showActiveSessionAlert = false
    
    private var hasActiveSession: Bool {
        runStore.activeSession != nil || workoutStore.activeSession != nil
    }
    
    // Stats Calculation
    var longestRun: MockRunSession? {
        SampleData.runSessions.max(by: { $0.distance < $1.distance })
    }
    
    var fastestPaceRun: MockRunSession? {
        // Lower pace value is faster (min/km)
        SampleData.runSessions.min(by: { $0.avgPace < $1.avgPace })
    }
    
    var maxCaloriesRun: MockRunSession? {
        SampleData.runSessions.max(by: { $0.calories < $1.calories })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Personal Bests
                    statsSection
                    
                    // Run Types Grid
                    runTypesSection
                    
                    // Recent History
                    historySection
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("Run")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedRunType) { type in
                RunConfigSheet(type: type)
            }
            .alert("Session in Progress", isPresented: $showActiveSessionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if runStore.activeSession != nil {
                    Text("Please finish your current run before starting a new one.")
                } else {
                    Text("Please finish your current workout before starting a new run.")
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Start a Run")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Quick Start Card
            Button {
                if hasActiveSession {
                    showActiveSessionAlert = true
                } else {
                    selectedRunType = .quickStart
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hasActiveSession ? "Session in Progress" : "Quick Run")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(hasActiveSession ? "Finish current session first" : "Just run, open ended")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: hasActiveSession ? "lock.fill" : "figure.run")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
                .padding(20)
                .background(hasActiveSession ? Theme.textSecondary.opacity(0.5) : Theme.terracotta)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var runTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GOALS & TARGETS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                RunTypeCard(type: .distance, action: { selectedRunType = .distance })
                RunTypeCard(type: .time, action: { selectedRunType = .time })
                RunTypeCard(type: .pace, action: { selectedRunType = .pace })
                RunTypeCard(type: .calories, action: { selectedRunType = .calories })
            }
            .padding(.horizontal, 20)
            
            Text("ADVANCED")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                RunTypeCard(type: .heartRate, action: { selectedRunType = .heartRate })
                // RunTypeCard(type: .intervals, action: { selectedRunType = .intervals })
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PERSONAL BESTS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if let longest = longestRun {
                        StatHighlightCard(
                            label: "Longest Run",
                            value: String(format: "%.1f", longest.distance),
                            unit: "km",
                            icon: "map.fill",
                            color: Theme.sage
                        )
                    }
                    
                    if let fastest = fastestPaceRun {
                        StatHighlightCard(
                            label: "Fastest Pace",
                            value: String(format: "%.2f", fastest.avgPace),
                            unit: "min/km",
                            icon: "speedometer",
                            color: Theme.stone
                        )
                    }
                    
                    if let maxCal = maxCaloriesRun {
                        StatHighlightCard(
                            label: "Max Burn",
                            value: "\(maxCal.calories)",
                            unit: "kcal",
                            icon: "flame.fill",
                            color: Theme.terracotta
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HISTORY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1)
                .padding(.horizontal, 20)
                
            NavigationLink(destination: AllSessionsView(filter: .run)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("All Run Sessions")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("View your complete running history")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.stone)
                }
                .padding(16)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Components

struct RunTypeCard: View {
    let type: RunGoalType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.terracotta)
                    .frame(width: 38, height: 38)
                    .background(Theme.terracotta.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text(type.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct StatHighlightCard: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.stone)
                .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 110)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}


#Preview {
    RunView()
}


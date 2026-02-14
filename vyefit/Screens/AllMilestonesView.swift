//
//  AllMilestonesView.swift
//  vyefit
//
//  View all milestones with filter options.
//

import SwiftUI

enum MilestoneFilter: String, CaseIterable {
    case all = "All"
    case inProgress = "In Progress"
    case completed = "Completed"
}

struct AllMilestonesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedFilter: MilestoneFilter = .all
    
    private var progressBarColor: Color {
        colorScheme == .dark ? Theme.terracotta : Theme.sage
    }
    
    private var filteredAchievements: [MockAchievement] {
        switch selectedFilter {
        case .all:
            return SampleData.achievements
        case .inProgress:
            return SampleData.achievements.filter { !$0.isUnlocked }
        case .completed:
            return SampleData.achievements.filter { $0.isUnlocked }
        }
    }
    
    private var progressStats: (completed: Int, total: Int, percentage: Double) {
        let total = SampleData.achievements.count
        let completed = SampleData.achievements.filter { $0.isUnlocked }.count
        let percentage = total > 0 ? Double(completed) / Double(total) : 0
        return (completed, total, percentage)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Overview Card
                    progressOverviewCard
                    
                    // Filter Pills
                    filterSection
                    
                    // Milestones List
                    milestonesList
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("Milestones")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var progressOverviewCard: some View {
        VStack(spacing: 16) {
            // Stats
            HStack(spacing: 24) {
                StatItem(
                    value: "\(progressStats.completed)",
                    label: "Completed",
                    color: Theme.sage
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    value: "\(progressStats.total - progressStats.completed)",
                    label: "In Progress",
                    color: Theme.terracotta
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    value: "\(progressStats.total)",
                    label: "Total",
                    color: Theme.stone
                )
            }
            
            // Overall Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Overall Progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(progressStats.percentage * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.sage)
                }
                
                    // Progress bar with background
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.sand)
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(progressBarColor)
                            .frame(width: geometry.size.width * progressStats.percentage, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MilestoneFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .medium))
                            .foregroundStyle(selectedFilter == filter ? .white : Theme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Theme.terracotta : Theme.cream)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var milestonesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(filteredAchievements.count) Milestones")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                ForEach(filteredAchievements) { achievement in
                    MilestoneRow(achievement: achievement)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Theme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Helper Views

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

#Preview {
    AllMilestonesView()
}

//
//  ProfileView.swift
//  vyefit
//
//  You tab — user avatar, name, milestones, recent sessions, and settings.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("userName") private var userName = "Rudra Patel"
    @AppStorage("appTheme") private var appTheme = "System"
    
    private var currentMonthRuns: [MockRunSession] {
        let calendar = Calendar.current
        return SampleData.runSessions.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }
    
    private var currentMonthWorkouts: [MockWorkoutSession] {
        let calendar = Calendar.current
        return SampleData.workoutSessions.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Theme.sand)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(Theme.stone)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Your name", text: $userName)
                                .font(.system(size: 22, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.textPrimary)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .tint(Theme.terracotta)
                                .textFieldStyle(.plain)

                            Text("Mindful Mover")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.sage)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top)
                    
                    // Milestones
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Milestones")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)

                        ForEach(SampleData.achievements.prefix(4)) { a in
                            MilestoneRow(achievement: a)
                        }
                    }
                    .padding(20)
                    .background(Theme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    
                    // Recent Sessions
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Sessions")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            NavigationLink {
                                AllSessionsView()
                            } label: {
                                Text("View All")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.terracotta)
                            }
                        }
                        
                        if currentMonthRuns.isEmpty && currentMonthWorkouts.isEmpty {
                            Text("No sessions this month")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(currentMonthRuns.prefix(3)) { run in
                                    SessionRow(run: run)
																}
                                
                                ForEach(currentMonthWorkouts.prefix(2)) { workout in
                                    WorkoutSessionRow(session: workout)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Theme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)

                    // Settings
                    VStack(spacing: 0) {
                        NavigationLink {
                            UnitsMeasurementsView()
                        } label: {
                            SettingRow(icon: "scalemass", title: "Units & Measurements")
                        }

                        NavigationLink {
                            HealthIntegrationView()
                        } label: {
                            SettingRow(icon: "heart", title: "Health Integration")
                        }

                        NavigationLink {
                            RemindersView()
                        } label: {
                            SettingRow(icon: "bell", title: "Reminders")
                        }

                        NavigationLink {
                            BackupSyncView()
                        } label: {
                            SettingRow(icon: "icloud", title: "Backup & Sync")
                        }
                    }
                    .buttonStyle(.plain)
                    .tint(Theme.terracotta)
                    .background(Theme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)

                    // Appearance
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Appearance", systemImage: "paintbrush")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        
                        Picker("Theme", selection: $appTheme) {
                            Text("System").tag("System")
                            Text("Light").tag("Light")
                            Text("Dark").tag("Dark")
                        }
                        .pickerStyle(.segmented)
                        .tint(Theme.terracotta)
                    }
                    .padding(20)
                    .background(Theme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct WorkoutSessionRow: View {
    let session: MockWorkoutSession
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.terracotta.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.terracotta)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                
                HStack(spacing: 6) {
                    Text("\(session.exerciseCount) exercises")
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("•")
                        .foregroundStyle(Theme.stone)
                    
                    Text(session.date, format: .dateTime.weekday(.wide))
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
                    Text("\(session.calories) kcal")
                        .foregroundStyle(Theme.terracotta)
                }
                .font(.system(size: 12, weight: .medium))
                
                Text(SampleData.formatDuration(session.duration))
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
    ProfileView()
}

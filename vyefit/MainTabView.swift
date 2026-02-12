//
//  MainTabView.swift
//  vyefit
//
//  Root tab bar container.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 0
    @State private var workoutStore = WorkoutStore()
    @State private var runStore = RunStore()
    @AppStorage("appTheme") private var appTheme = "System"

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Image(systemName: "leaf.fill")
                        Text("Today")
                    }
                    .tag(0)

                WorkoutsView()
                    .tabItem {
                        Image(systemName: "dumbbell.fill")
                        Text("Train")
                    }
                    .tag(1)

                RunView()
                    .tabItem {
                        Image(systemName: "figure.run")
                        Text("Run")
                    }
                    .tag(2)

                JournalView()
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("Journal")
                    }
                    .tag(3)

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("You")
                    }
                    .tag(4)
            }
            .environment(workoutStore)
            .environment(runStore)
            .tint(Theme.terracotta)
            .toolbarBackground(Theme.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            
            if let session = workoutStore.activeSession, !workoutStore.showActiveWorkout {
                MiniWorkoutPlayer(session: session) {
                    workoutStore.showActiveWorkout = true
                }
                .padding(.bottom, 60)
            }
            
            if let session = runStore.activeSession, !runStore.showActiveRun {
                MiniRunPlayer(session: session) {
                    runStore.showActiveRun = true
                }
                .padding(.bottom, workoutStore.activeSession != nil ? 130 : 60)
            }
        }
        .fullScreenCover(isPresented: $workoutStore.showActiveWorkout) {
            if let session = workoutStore.activeSession {
                ActiveWorkoutView(session: session) {
                    workoutStore.endActiveSession()
                }
            }
        }
        .fullScreenCover(isPresented: $runStore.showActiveRun) {
            if let session = runStore.activeSession {
                ActiveRunView(session: session) {
                    runStore.endActiveSession()
                }
            }
        }
        .preferredColorScheme(preferredScheme)
    }

    private var preferredScheme: ColorScheme? {
        switch appTheme {
        case "Light":
            return .light
        case "Dark":
            return .dark
        default:
            return nil
        }
    }
}

#Preview {
    HomeView()
}

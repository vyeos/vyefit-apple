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
    @AppStorage("appTheme") private var appTheme = "System"
    @AppStorage("accentColor") private var accentColor = "Terracotta"

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
            .tint(tintColor)
            .toolbarBackground(Theme.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            
            if let session = workoutStore.activeSession, !workoutStore.showActiveWorkout {
                MiniWorkoutPlayer(session: session) {
                    workoutStore.showActiveWorkout = true
                }
                .padding(.bottom, 60) // Adjust for tab bar
            }
        }
        .fullScreenCover(isPresented: $workoutStore.showActiveWorkout) {
            if let session = workoutStore.activeSession {
                ActiveWorkoutView(session: session) {
                    workoutStore.endActiveSession()
                }
            }
        }
        .preferredColorScheme(preferredScheme)
    }

    private var tintColor: Color {
        switch accentColor {
        case "Sage":
            return Theme.sage
        case "Stone":
            return Theme.stone
        default:
            return Theme.terracotta
        }
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

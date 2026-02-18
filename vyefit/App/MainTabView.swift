//
//  MainTabView.swift
//  vyefit
//
//  Root tab bar container.
//

import SwiftUI
import Combine

struct HomeView: View {
    @State private var selectedTab = 0
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

                ScheduleView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Schedule")
                    }
                    .tag(3)

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("You")
                    }
                    .tag(4)
            }
            .environment(WorkoutStore.shared)
            .environment(RunStore.shared)
            .tint(Theme.terracotta)
            .toolbarBackground(Theme.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            
            if let session = WorkoutStore.shared.activeSession, !WorkoutStore.shared.showActiveWorkout {
                MiniWorkoutPlayer(session: session) {
                    WorkoutStore.shared.showActiveWorkout = true
                }
                .padding(.bottom, 60)
            }
            
        }
        .fullScreenCover(isPresented: Binding(
            get: { WorkoutStore.shared.showActiveWorkout },
            set: { WorkoutStore.shared.showActiveWorkout = $0 }
        )) {
            if let session = WorkoutStore.shared.activeSession {
                ActiveWorkoutView(
                    session: session,
                    onEnd: { WorkoutStore.shared.endActiveSession() },
                    onDiscard: { WorkoutStore.shared.discardActiveSession() }
                )
            }
        }
        .onAppear {
            HealthKitManager.shared.importLatestWorkoutsIfNeeded()
            
            // Setup WatchConnectivity callbacks
            let watchManager = WatchConnectivityManager.shared
            
            // Handle workout ended from watch
            watchManager.onWorkoutEnded = { uuid in
                // Import completed workouts from Apple Health/Watch.
                if let uuid {
                    HealthKitManager.shared.importWorkout(uuid: uuid) { _ in }
                } else {
                    HealthKitManager.shared.importLatestWorkoutsIfNeeded(force: true)
                }
            }
            
            // Ensure session is activated
            watchManager.activate { success in
                if success {
                    print("[MainTabView] WatchConnectivity activated successfully")
                } else {
                    print("[MainTabView] WatchConnectivity activation failed or not supported")
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

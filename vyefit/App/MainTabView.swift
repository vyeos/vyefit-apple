//
//  MainTabView.swift
//  vyefit
//
//  Root tab bar container.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 0
    @AppStorage("appTheme") private var appTheme = "System"

    var body: some View {
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

                ScheduleView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Schedule")
                    }
                    .tag(2)

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("You")
                    }
                    .tag(3)
            }
        .environment(WorkoutStore.shared)
        .environment(RunStore.shared)
        .tint(Theme.terracotta)
        .toolbarBackground(Theme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
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

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
            
            if let session = RunStore.shared.activeSession, !RunStore.shared.showActiveRun {
                MiniRunPlayer(session: session) {
                    RunStore.shared.showActiveRun = true
                }
                .padding(.bottom, WorkoutStore.shared.activeSession != nil ? 130 : 60)
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
        .fullScreenCover(isPresented: Binding(
            get: { RunStore.shared.showActiveRun },
            set: { RunStore.shared.showActiveRun = $0 }
        )) {
            if let session = RunStore.shared.activeSession {
                ActiveRunView(
                    session: session,
                    onEnd: { RunStore.shared.endActiveSession() },
                    onDiscard: { RunStore.shared.discardActiveSession() }
                )
            }
        }
        .onAppear {
            HealthKitManager.shared.importLatestWorkoutsIfNeeded()
            WatchConnectivityManager.shared.onWorkoutEnded = { uuid in
                if let uuid {
                    HealthKitManager.shared.importWorkout(uuid: uuid) { _ in }
                } else {
                    HealthKitManager.shared.importLatestWorkoutsIfNeeded(force: true)
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

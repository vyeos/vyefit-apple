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
        .tint(Theme.terracotta)
        .preferredColorScheme(.light)
    }
}

#Preview {
    HomeView()
}

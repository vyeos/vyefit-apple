//
//  vyefitApp.swift
//  vyefit
//
//  Created by Rudra Patel on 10/02/26.
//

import SwiftUI
import CoreData

@main
struct vyefitApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

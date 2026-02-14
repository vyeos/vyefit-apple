//
//  Persistence.swift
//  vyefit
//
//  Created by Rudra Patel on 10/02/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
#if DEBUG
            let nsError = error as NSError
            assertionFailure("Unresolved error: \(nsError), \(nsError.userInfo)")
#else
            print("Core Data preview save error: \(error)")
#endif
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "vyefit")
        if inMemory {
            if let description = container.persistentStoreDescriptions.first {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
#if DEBUG
                assertionFailure("Unresolved error: \(error), \(error.userInfo)")
#else
                print("Core Data load error: \(error)")
#endif
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

//
//  Mac_GeniusApp.swift
//  Mac Genius
//
//  Created by Aidan Leuenberger on 6/4/23.
//

import SwiftUI

@main
struct Mac_GeniusApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

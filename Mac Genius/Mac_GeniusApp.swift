//
//  Mac_GeniusApp.swift
//  Mac Genius
//
//  Created by Aidan Leuenberger on 6/20/23.
//

import SwiftUI
import Firebase


@main
struct Mac_GeniusApp: App {
        init() {
               FirebaseApp.configure()
           }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

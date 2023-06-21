//
//  Mac_GeniusApp.swift
//  Mac Genius
//
//  Created by Aidan Leuenberger on 6/20/23.
//

import SwiftUI
import Firebase

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
    }
}

@main
struct Mac_GeniusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

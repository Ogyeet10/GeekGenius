//
//  GeekGeniusApp.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import Firebase
import OneSignal

@main
struct GeekGeniusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var userSettings = UserSettings() // Add this line
    @StateObject private var tipsStore = TipsStore()


    init() {
        FirebaseApp.configure() //Configure Firebase
    }

    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environmentObject(appState)
                .environmentObject(LaunchStateManager())
                .environmentObject(tipsStore)
        }
    }
}


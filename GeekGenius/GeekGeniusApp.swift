//
//  GeekGeniusApp.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import Firebase
import IQKeyboardManagerSwift
import OneSignal

@main
struct GeekGeniusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var userSettings = UserSettings() // Add this line

    init() {
        FirebaseApp.configure()
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 25 // Set your desired distance
    }

    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environmentObject(appState)
                .environmentObject(LaunchStateManager())
                
        }
    }
}


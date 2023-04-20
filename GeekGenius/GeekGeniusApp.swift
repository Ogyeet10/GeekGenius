//
//  GeekGeniusApp.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import Firebase


struct GeekGeniusApp: App {
    private let appState = AppState()
    var body: some Scene {
           WindowGroup {
               MainView()
                   .environmentObject(appState)
           }
       }
   }

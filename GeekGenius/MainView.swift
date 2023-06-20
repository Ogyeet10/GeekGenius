//
//  MainView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var appState: AppState
    @ObservedObject var userSettings = UserSettings()
    
    var body: some View {
        Group {
            if appState.isGuest || appState.isLoggedIn {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }
                        .tag(0)
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }
                        .tag(1)
                    
                    SettingsView()
                        .environmentObject(userSettings)
                        .tabItem {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                        .tag(2)
                }
            } else {
                NavigationView {
                    VStack {
                        LoginView(isSignedIn: $appState.isLoggedIn) // Updated
                            .environmentObject(appState)
                        
                    }
                }
            }
        }
        .onChange(of: appState.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                print("Logged in, showing TabView")
            } else {
                print("Not logged in, showing LoginView")
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AppState())
            .environmentObject(UserSettings())
    }
}

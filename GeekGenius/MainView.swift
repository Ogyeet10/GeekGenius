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
    @EnvironmentObject private var tipsStore: TipsStore
    // Create a @StateObject for the TipsStore

    struct SettingsViewWrapper: View {
        @EnvironmentObject private var tipsStore: TipsStore
        @EnvironmentObject var appState: AppState

        var body: some View {
            SettingsView().cardVw
                .environmentObject(tipsStore)
                .environmentObject(appState)
                .onAppear {
                    print("MainView SettingsViewWrapper SettingsView tipsStore: \(tipsStore)")
                }
                .onAppear {
                    print("SettingsViewWrapper tipsStore: \(tipsStore)")
                }
        }
    }


    var body: some View {
        Group {
            if appState.isGuest || appState.isLoggedIn {
                TabView(selection: $selectedTab) {
            VStack {
                EmptyView()
            }
            .onAppear {
                print("MainView TabView tipsStore: \(tipsStore)")
            }
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
                        .environmentObject(tipsStore)
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
        .overlay(alignment: .bottom) {
            
            if SettingsView().showThanks {
                VStack(spacing: 8) {
                    
                    Text("Thank You 💕")
                        .font(.system(.title2, design: .rounded).bold())
                        .multilineTextAlignment(.center)
                    
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                        .font(.system(.body, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                    
                    Button {
                        SettingsView().showThanks.toggle()
                    } label: {
                        Text("Close")
                            .font(.system(.title3, design: .rounded).bold())
                            .tint(.white)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .background(.blue, in: RoundedRectangle(cornerRadius: 10,
                                                                    style: .continuous))
                        
                    }
                }
                .padding(16)
                .background(Color("card-background"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear() {
                    Task {
                        print("overlay shown")
                    }
                }
            }
            
        }
        .overlay {
            if appState.showTips {
                AnyView(
                    VStack {
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                appState.showTips.toggle()
                            }
                    
                        SettingsViewWrapper()
                            .environmentObject(tipsStore)
                            .environmentObject(appState)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            
                    }
                )
            } else {
                AnyView(EmptyView())
            }
        }
        .animation(.spring(), value: appState.showTips)

        .animation(.spring(), value: SettingsView().showThanks)
        .onChange(of: tipsStore.action) { action in
            
            if action == .successful {
                
                appState.showTips = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    
                    appState.showThanks.toggle()
                    
                }
                
                tipsStore.reset()
            }
            
        }
        .alert(isPresented: $tipsStore.hasError, error: tipsStore.error) { }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AppState())
            .environmentObject(UserSettings())
            .environmentObject(TipsStore())
    }
}

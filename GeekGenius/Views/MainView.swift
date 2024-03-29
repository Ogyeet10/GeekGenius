//
//  MainView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import StoreKit
import UIKit

struct MainView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var appState: AppState
    @ObservedObject var userSettings = UserSettings()
    // Create a @StateObject for the TipsStore
    @EnvironmentObject private var tipsStore: TipsStore
    // Computed property to check if MainChatView should be shown
    private var shouldShowMainChatView: Bool {
        appState.isDelisha || appState.isAidan
    }

    var body: some View {
        Group {
            if appState.needsIntroduction && appState.isDelisha {
                ChatIntroductionView()
                    .transition(.asymmetric(insertion: .scale, removal: .opacity)) // Example of an animation
            } else {
                if appState.isGuest || appState.isLoggedIn {
                    TabView(selection: $selectedTab) {
                        HomeView()
                            .tabItem {
                                Image(systemName: "house")
                                Text("Home")
                            }
                            .tag(0)
                        
                        // Conditionally display MainChatView
                        if shouldShowMainChatView {
                            MainChatView()
                                .tabItem {
                                    Image(systemName: "message")
                                    Text("Chat")
                                }
                                .tag(1)
                        }
                        
                        ProfileView()
                            .tabItem {
                                Image(systemName: "person")
                                Text("Profile")
                            }
                            .tag(shouldShowMainChatView ? 2 : 1)
                        
                        SettingsView()
                            .environmentObject(userSettings)
                            .environmentObject(tipsStore)
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                            .tag(shouldShowMainChatView ? 3 : 2)
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
        }
        
        .onChange(of: appState.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                print("Logged in, showing TabView")
            } else {
                print("Not logged in, showing LoginView")
            }
        }
        .onChange(of: appState.isDelisha) { _ in
            if shouldShowMainChatView {
                selectedTab = 1
            }
        }
        .onChange(of: appState.isAidan) { _ in
            if shouldShowMainChatView {
                selectedTab = 1
            }
        }
        .sheet(isPresented: $appState.navigateToFutureChatView) {
            FutureChatView()
                .interactiveDismissDisabled(appState.isAidan ? false : true)
        }
        .overlay(alignment: .bottom) {
            
            if appState.showThanks {
                VStack(spacing: 8) {
                    
                    Text("Wow.")
                        .font(.system(.title2, design: .rounded).bold())
                        .multilineTextAlignment(.center)
                    
                    Text("I did not expect you to do that. In a future update you will get a symbol by your name in comments based on your contribution. Thanks for supporting future GeekGenius development.")
                        .font(.system(.body, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                    
                    Button {
                        appState.showThanks.toggle()
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
                    
                        
                            
                    }
                )
                cardVw()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                AnyView(EmptyView())
            }
        }
        .animation(.spring(), value: appState.showTips)

        .animation(.spring(), value: appState.showThanks)
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



extension UIDevice {
    var modelName: String {
        #if targetEnvironment(simulator)
            if let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] {
                if simulatorName == "Del" {
                    return "iPhone XR"
                }
            }
        #endif
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.compactMap { $0.value as? Int8 }.map { String(Character(UnicodeScalar(UInt8($0)))) }.joined()

        switch identifier {
            case "iPhone11,8": return "iPhone XR"
            // MARK: - REMOVE LATER
            case "iPhone12,1": return "iPhone XR"
            // ... other cases for other models
            default: return identifier
        }
    }
}



struct cardVw: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tipsStore: TipsStore
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button {
                    
                   appState.showTips.toggle()
                } label: {
                    Image(systemName: "xmark")
                        .symbolVariant(.circle.fill)
                        .font(.system(.largeTitle, design: .rounded).bold())
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.gray, .gray.opacity(0.2))
                }
            }
            
            Text("Love the app?")
                .font(.system(.title2, design: .rounded).bold())
                .multilineTextAlignment(.center)
            
            Text("Whether you love a new feature or simply appreciate what I'm doing, your tip will be greatly appreciated. I'm the only one working on this app, so thank you for supporting the future of GeekGenius.")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
            
            ForEach(tipsStore.items ?? [Product]()) { item in
                HStack {
                    Text(item.displayName)
                        .font(.system(.title3, design: .rounded).bold())
                    
                    Spacer()
                    Button(item.displayPrice) {
                        Task {
                            await tipsStore.purchase(item)
                        }
                    }
                    .tint(.blue)
                    .buttonStyle(.bordered)
                    .font(.callout.bold())
                }
                .padding(16)
                .background(Color("cell-background"),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .background(Color("card-background"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(8)
        .overlay(alignment: .top) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .clipShape(Squircle(cornerRadius: 15)) // Adjust this value to match your preference
                .offset(y: -25)
                }
    }
    func configureProductVw(_ item: Product) -> some View {
            
            HStack {
                VStack(alignment: .leading,
                       spacing: 3) {
                    Text(item.displayName)
                        .font(.system(.title3, design: .rounded).bold())
                    Text(item.description)
                        .font(.system(.callout, design: .rounded).weight(.regular))
                }
                
                Spacer()
                
                Button(item.displayPrice) {
                    Task {
                        await tipsStore.purchase(item)
                    }
                }
                .tint(.blue)
                .buttonStyle(.bordered)
                .font(.callout.bold())
            }
            .padding(16)
            .background(Color("cell-background"),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            
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

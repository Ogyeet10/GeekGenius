//
//  OnboardingView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 6/7/23.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var launchStateManager: LaunchStateManager
    @StateObject private var tipsStore = TipsStore()


    var body: some View {
        if launchStateManager.isFirstLaunch {
            VStack {
                OnboardingScreenView(
                    title: "Welcome to GeekGenius",
                    detail: "This app contains tech videos for all of my classmates(or other users) updated weekly along with other features including video release notifications a comprehensive settings menu and a profile feature. Also for those who don't know GeekGenius is free until Sep 10th."
                )
                Button(action: {
                    launchStateManager.isFirstLaunch = false
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 50)
            }
        } else if launchStateManager.showWhatsNew {
            VStack {
                WhatsNewScreenView(
                    title: "What's New in GeekGenius v1.1",
                    items: [
                        WhatsNewItem(icon: "captions.bubble", title: "Comments", description: "Comment on videos to interact with me and other creators."),
                        WhatsNewItem(icon: "info.circle", title: "Updated About info", description: "Updated info on about screen to reflect the current state of the app."),
                        WhatsNewItem(icon: "app.badge", title: "Push Notifications", description: "Now with improved push notifications you can get updated the second new content is out."),
                        WhatsNewItem(icon: "bandage", title: "Bug fixes", description: "Various bug fixes and performance improvements.")
                    ]
                )
                Button(action: {
                    launchStateManager.showWhatsNew = false
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 50)
            }
        } else {
            MainView()
                .environmentObject(tipsStore)
        }
    }
}

struct WhatsNewItem {
    let icon: String
    let title: String
    let description: String
}


struct OnboardingScreenView: View {
    var title: String
    var detail: String

    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .clipShape(Squircle(cornerRadius: 55)) // Adjust this value to match your preference
                .padding(.bottom)
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(detail)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}


class LaunchStateManager: ObservableObject {
    @Published var isFirstLaunch: Bool {
        didSet {
            UserDefaults.standard.set(isFirstLaunch, forKey: "isFirstLaunch")
        }
    }
    
    @Published var showWhatsNew: Bool {
        didSet {
            UserDefaults.standard.set(showWhatsNew, forKey: "showWhatsNew")
        }
    }

    init() {
        self.isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") as? Bool ?? true
        self.showWhatsNew = false // Initialize with a dummy value
        self.showWhatsNew = checkForAppUpdate() // Compute the correct value
    }
    
    init(isFirstLaunch: Bool, showWhatsNew: Bool) {
        self.isFirstLaunch = isFirstLaunch
        self.showWhatsNew = showWhatsNew
    }

    func checkForAppUpdate() -> Bool {
        // Get current app version
        let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        // Get previous version (if any)
        let previousAppVersion = UserDefaults.standard.string(forKey: "appVersion")

        // Save current version to user defaults
        UserDefaults.standard.set(currentAppVersion, forKey: "appVersion")

        // Return whether the app has been updated
        return currentAppVersion != previousAppVersion
    }
}

struct WhatsNewScreenView: View {
    var title: String
    var items: [WhatsNewItem]

    var body: some View {
        VStack() {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Squircle(cornerRadius: 24)) // Adjust this value to match your preference
                .padding(.bottom)
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            ScrollView {
                ForEach(items, id: \.title) { item in
                    HStack() {
                        Image(systemName: item.icon)
                            .resizable()
                            .foregroundColor(.accentColor)
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .padding(.horizontal)
                        

                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(item.description)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) // This line has been added
                    }
                    .padding(.vertical)
                    
                }
            }
        }
        .padding()
    }
}




struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView()
                .previewDevice("iPhone 14 Pro Max")
                .environmentObject(AppState())
                .environmentObject(LaunchStateManager(isFirstLaunch: true, showWhatsNew: false)) // Show onboarding screen
                .previewDisplayName("Welcome View")
            OnboardingView()
                .previewDevice("iPhone 14 Pro Max")
                .environmentObject(AppState())
                .environmentObject(LaunchStateManager(isFirstLaunch: false, showWhatsNew: true)) // Show what's new screen
                .previewDisplayName("Whats New View")
            OnboardingView()
                .previewDevice("iPhone 14 Pro Max")
                .environmentObject(AppState())
                .environmentObject(LaunchStateManager(isFirstLaunch: false, showWhatsNew: false)) // Show main view
            
                .previewDisplayName("Log On view")   
        }
    }
}


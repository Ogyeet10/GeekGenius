//
//  OnboardingView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 6/7/23.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var launchStateManager: LaunchStateManager

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
        } else {
            MainView()
        }
    }
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
    
    init() {
        self.isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") as? Bool ?? true
    }
}



struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .previewDevice("iPhone 14 Pro Max")
            .environmentObject(AppState())
            .environmentObject(LaunchStateManager())
        
    }
}

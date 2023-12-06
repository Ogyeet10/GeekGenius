//
//  ChatIntroductionView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 11/22/23.
//

import SwiftUI

struct ChatIntroductionView: View {
    @EnvironmentObject var appState: AppState
    @State private var alertIndex = 0 // Current index in the alert sequence
    @State private var showingGradient = true
    @State private var showAlert = false // State to control alert presentation
    
    // Define your alerts here
    var alerts: [IntroAlertItem] = [
        IntroAlertItem(title: "Welp.", message: "At this point, you already know what's going on here.", dismissButton: "I think..."),
        IntroAlertItem(title: "And well,", message: "If you don't, I'm kind of screwed.", dismissButton: "Definitely."),
        IntroAlertItem(title: "Info", message: "Since you’ve been (mostly) verified, GeekGenius will now enable the new feature for you.", dismissButton: "Continue"),
        IntroAlertItem(title: "The app may close, be prepared.", message: "If the app does close, just open it again and GeekGenius will redirect you to the new feature.", dismissButton: "Ok."),
        IntroAlertItem(title: "Due to what I'm about to show.", message: "Additional verification will be required within the bounds of the new feature itself.", dismissButton: "Got it."),
        IntroAlertItem(title: "As a precaution,", message: "Most features will be locked without verification.", dismissButton: "I understand"),
        IntroAlertItem(title: "Honor system", message: "Please DO NOT share anything you're about to see with anyone.", dismissButton: "I Won't."),
        IntroAlertItem(title: "Warning", message: "GeekGenius is now going to enable the new feature. We will attempt to do it without a restart (of the app) first, but one may be required.", dismissButton: "Let's Do This.")
    ]
    
    var body: some View {
        VStack {
            // Show the gradient as the background
            if showingGradient {
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.pink]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
            } else {
                // Placeholder content, customize as needed
                Text("Welcome to GeekGenius!")
                    .padding()
            }
        }
        .onAppear {
            // Start the alert sequence when the view appears
            self.showAlertSequence()
        }
        .alert(isPresented: $showAlert) {
            // Configure the alert based on the current alert index
            let currentAlert = alerts[alertIndex]
            return Alert(
                title: Text(currentAlert.title),
                message: Text(currentAlert.message),
                dismissButton: .default(Text(currentAlert.dismissButton)) {
                    // Handle the dismissal of the alert
                    self.handleAlertDismissal()
                }
            )
        }
    }
    
    private func showAlertSequence() {
        if alertIndex < alerts.count {
            showAlert = true // Trigger the alert
        } else {
            appState.isDelisha = true
            SessionManager.shared.appState = appState
            SessionManager.shared.resetAndRecomputeDeviceId()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                appState.needsIntroduction = false
            }
        }
    }
    
    private func handleAlertDismissal() {
        // Increment the alert index to show the next alert
        alertIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showAlertSequence() // Call the sequence function again
        }
    }
}

struct IntroAlertItem: Identifiable {
    let id = UUID()
    var title: String
    var message: String
    var dismissButton: String
}

#Preview {
    ChatIntroductionView()
}

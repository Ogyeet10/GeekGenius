//
//  SettingsView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var selectedFrequency = 1
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    @EnvironmentObject var appState: AppState

    let frequencyOptions = ["Daily", "Weekly", "Monthly"]

    var body: some View {
        NavigationView {
            Form {
                // Account Settings Section
                Section(header: Text("Account Settings")) {
                    if let user = Auth.auth().currentUser {
                        Text("Username: \(user.email ?? "N/A")")
                    } else {
                        Text("Username: N/A")
                    }
                    
                    Button("Sign Out") {
                        signOut()
                    }
                }
                
                // Notification Settings Section
                Section(header: Text("Notification Settings")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    Picker("Notification Frequency", selection: $selectedFrequency) {
                        ForEach(frequencyOptions.indices, id: \.self) { index in
                            Text(frequencyOptions[index])
                        }
                    }
                }
                
                // App Preferences Section
                Section(header: Text("App Preferences")) {
                    // Add app preferences options here
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Settings")
                            .font(.headline)
                        Image(systemName: "gear")
                    }
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()
            appState.isLoggedIn = false
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
            errorAlertMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

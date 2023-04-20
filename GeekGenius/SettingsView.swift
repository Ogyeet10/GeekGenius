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
    @EnvironmentObject var appState: AppState

    let frequencyOptions = ["Daily", "Weekly", "Monthly"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Settings")) {
                    Text("Username: username@example.com")
                    Button("Sign Out") {
                        signOut()
                    }
                }
                
                Section(header: Text("Notification Settings")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Picker("Notification Frequency", selection: $selectedFrequency) {
                        Picker("Notification Frequency", selection: $selectedFrequency) {
                            ForEach(frequencyOptions.indices, id: \.self) { index in
                                Text(frequencyOptions[index])
                            }
                        }

                            
                        }
                    }
                }
                
                Section(header: Text("App Preferences")) {
                    // Add app preferences options here
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
        }
    private func signOut() {
        do {
            try Auth.auth().signOut()
            appState.isLoggedIn = false
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
            // Show an error message to the user
        }
    }
}



struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

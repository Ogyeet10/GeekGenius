//
//  SettingsView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import UIKit
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    @EnvironmentObject var appState: AppState
    @State private var isChangePasswordViewPresented = false
    @State private var showDeleteAccountAlert = false
    @State private var showCopiedAlert = false
    @EnvironmentObject var tipsStore: TipsStore
    @State var showTips = false
    @State var showThanks = false
    
    let frequencyOptions = ["Daily", "Weekly", "Monthly"]
    
    var body: some View {
        NavigationView {
            Form {
                // Account Settings Section
                Section(header: Text("Account Settings")) {
                    if let user = Auth.auth().currentUser {
                        Text("Username: \(user.email ?? "N/A")")
                            .onTapGesture {
                                UIPasteboard.general.string = user.email
                            }
                            .onLongPressGesture {
                                UIPasteboard.general.string = user.email
                                withAnimation {
                                    self.showCopiedAlert = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        self.showCopiedAlert = false
                                    }
                                }
                            }
                            .alert(isPresented: $showCopiedAlert) {
                                Alert(
                                    title: Text("Copied!"),
                                    message: Text("\(user.email ?? "N/A") copied to clipboard."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        Button("Sign Out") {
                            signOut()
                        }
                        Button("Change Password") {
                            isChangePasswordViewPresented = true
                        }
                        .sheet(isPresented: $isChangePasswordViewPresented) {
                            ChangePasswordView()
                        }
                        Button("Delete Account") {
                            showDeleteAccountAlert = true
                        }
                        .foregroundColor(.red)
                        .alert(isPresented: $showDeleteAccountAlert) {
                            Alert(
                                title: Text("Delete Account"),
                                message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                                primaryButton: .destructive(Text("Delete"), action: deleteAccount),
                                secondaryButton: .cancel()
                            )
                        }
                    } else {
                        Text("Not Loged in")
                            .fontWeight(.bold)
                        Button("Sign In") {
                            self.appState.isGuest = false
                                                }
                    }

                }
                
                
                
                // Notification Settings Section
                Section(header: Text("Notification Settings")) {
                    Toggle("Enable Notifications", isOn: $userSettings.notificationsEnabled)
                    
                    Picker("Notification Frequency", selection: $userSettings.selectedFrequency) {
                        ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.description)
                        }
                    }
                }
                
                // App Preferences Section
               /* Section(header: Text("App Preferences")) {
                    // Add app preferences options here
                    Text("Coming soon!")
                        .foregroundColor(Color.purple)
                        
                } */
                
                // Contact Me Section
                Section(header: Text("Contact Me")) {
                    HStack {
                        Text("Phone:")
                        Spacer()
                        Link("1-773-551-9899", destination: URL(string: "sms:17735519899")!)
                            .foregroundColor(.blue)
                    }
                    
                    
                    HStack {
                        Text("Email:")
                        Spacer()
                        Text("aidanml05@gmail.com")
                            .foregroundColor(.gray)
                    }
                    
                    // Add your Telegram details here
                    HStack {
                        Text("Telegram:")
                        Spacer()
                        Link("@Ogyeet10", destination: URL(string: "https://t.me/Ogyeet10")!)
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Tip Jar")) {
                    Button("Tip Jar") {
                        appState.showTips.toggle()
                    }
                    
                }
                
                Section(header: Text("About This App")) {
                    NavigationLink(destination: AboutView()) {
                        Text("App Info & Credits")
                    }
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
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    print(rootViewController.printHierarchy())
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
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        // Prepare Firebase Firestore and Storage references
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        // Get user's document from Firestore
        let docRef = db.collection("users").document(user.uid)
        
        // Get user's data
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let data = document.data() {
                    // Delete user's profile photo from Firebase Storage
                    if let profilePhotoURL = data["profilePhotoURL"] as? String {
                        let storageRef = storage.reference(forURL: profilePhotoURL)
                        storageRef.delete { error in
                            if let error = error {
                                print("Error deleting photo: \(error.localizedDescription)")
                                errorAlertMessage = error.localizedDescription
                                showErrorAlert = true
                            } else {
                                print("Photo deleted successfully")
                            }
                        }
                    }
                    
                    // Delete user's document from Firestore
                    docRef.delete { error in
                        if let error = error {
                            print("Error deleting document: \(error.localizedDescription)")
                            errorAlertMessage = error.localizedDescription
                            showErrorAlert = true
                        } else {
                            print("Document deleted successfully")
                        }
                    }
                    
                    // Delete the user from Firebase Authentication
                    user.delete { error in
                        if let error = error {
                            // An error occurred
                            print("Error deleting user: \(error.localizedDescription)")
                            errorAlertMessage = error.localizedDescription
                            showErrorAlert = true
                        } else {
                            // Account deleted
                            appState.isLoggedIn = false
                        }
                    }
                }
            } else if let error = error {
                print("Error getting document: \(error.localizedDescription)")
                errorAlertMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}



struct ProductsListView: View {
    
    @EnvironmentObject private var store: TipsStore

    var body: some View {
        
        ForEach(store.items ?? []) { item in
            ProductView(item: item)
        }
    }
}

struct ProductView: View {
    
    @EnvironmentObject private var store: TipsStore
    
    let item: Product
    var body: some View {
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
                // TODO: Handle purchase
            }
            .tint(.blue)
            .buttonStyle(.bordered)
            .font(.callout.bold())
        }
    }
}



extension UIViewController {
    func printHierarchy() {
        var next = self.parent
        while let parent = next {
            print(parent)
            next = parent.parent
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserSettings())
            .environmentObject(AppState())
            .environmentObject(TipsStore())
    }
}

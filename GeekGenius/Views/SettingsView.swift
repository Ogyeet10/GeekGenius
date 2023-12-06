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
    @State private var showVideoLimitInfo = false // State to control the info alert
    @StateObject var settingsViewVM = SettingsViewViewModel()
    @State private var selectedUserType: UserType = .none
    @State private var isInitialLoad = true
    @State private var showConfirmationAlert = false
    
    let frequencyOptions = ["Daily", "Weekly", "Monthly"]
    
    enum UserType: String, CaseIterable, Identifiable {
        case none = "None"
        case delisha = "Delisha"
        case aidan = "Aidan"
        
        var id: String { self.rawValue }
    }
    
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
                
                
                
                
                
                // App Preferences Section
                Section(header: Text("App Preferences")) {
                    HStack {
                        Button(action: {
                            showVideoLimitInfo = true
                        }) {
                            Image(systemName: "info.circle")
                        }
                        Stepper("Video Limit: \(appState.videoLimit)", value: $appState.videoLimit, in: 1...100)
                        
                        
                            .alert(isPresented: $showVideoLimitInfo) {
                                Alert(title: Text("Video Limit Info"),
                                      message: Text("The Video Limit controls the number of videos fetched from the server at once. Increasing this limit may affect the Home screen's loading speed."),
                                      dismissButton: .default(Text("Got it!")))
                            }
                    }
                }
                
                // Inside the Form in SettingsView
                Section(header: Text("Dev settings")) {
                    HStack {
                        Picker("User Type", selection: $selectedUserType) {
                            ForEach(UserType.allCases) { userType in
                                Text(userType.rawValue).tag(userType)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    NavigationLink(destination: ChatIntroductionView()) {
                        Text("Chat introduction view")
                    }
                    HStack {
                        Toggle(isOn: $appState.navigateToFutureChatView) {
                            Text("Open Survey")
                        }
                    }
                    
                }
#if DEBUG
                .alert(isPresented: $showConfirmationAlert) {
                    Alert(
                        title: Text("Confirm Change"),
                        message: Text("Are you sure you want to change the user type?"),
                        primaryButton: .destructive(Text("Confirm")) {
                            // Execute the switch-case logic here after confirmation
                            executeUserTypeChange(selectedUserType)
                        },
                        secondaryButton: .cancel()
                    )
                }
#endif

                
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
                
                // Conditionally render the Tip Jar section
                if !settingsViewVM.disableTipJar {
                    Section(header: Text("Tip Jar")) {
                        Button(action: {
                            appState.showTips.toggle()
                        }) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                Text("Tip Jar")
                            }
                        }
                        .foregroundColor(.green)
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
                loadSelectedUserType()
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    print(rootViewController.printHierarchy())
                }
            }
#if DEBUG
            .onReceive(appState.$isDelisha) { isDelisha in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if isDelisha {
                        selectedUserType = .delisha
                    }
                }
            }
            .onReceive(appState.$isAidan) { isAidan in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if isAidan {
                        selectedUserType = .aidan
                    }
                }
            }
            .onChange(of: selectedUserType) { newUserType in
                // Trigger the confirmation alert
                showConfirmationAlert = true
            }
#endif
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
#if DEBUG
    private func executeUserTypeChange(_ newUserType: UserType) {
        switch newUserType {
        case .delisha:
            appState.isDelisha = true
            appState.isAidan = false
            SessionManager().logout()
        case .aidan:
            appState.isDelisha = false
            appState.isAidan = true
            SessionManager().logout()
        case .none:
            appState.isDelisha = false
            appState.isAidan = false
            SessionManager().logout()
        }
        saveSelectedUserType(selectedUserType)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            exit(0)
        }
    }
    
    private func loadSelectedUserType() {
            if let savedUserType = UserDefaults.standard.string(forKey: "selectedUserType") {
                selectedUserType = UserType(rawValue: savedUserType) ?? .none
            }
        }

        private func saveSelectedUserType(_ userType: UserType) {
            UserDefaults.standard.set(userType.rawValue, forKey: "selectedUserType")
        }
#endif
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

class SettingsViewViewModel: ObservableObject {
    var db = Firestore.firestore()
    @Published var disableTipJar: Bool = false
    private var listener: ListenerRegistration?
    
    init() {
        self.fetchTipJarState()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func fetchTipJarState() {
        let docRef = db.collection("variables").document("disableTipJar")
        
        listener = docRef.addSnapshotListener { (document, error) in
            if let document = document, let data = document.data() {
                DispatchQueue.main.async {
                    self.disableTipJar = data["disabled"] as? Bool ?? false
                }
            }
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

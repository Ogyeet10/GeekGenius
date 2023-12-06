//
//  MainChatView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 11/8/23.
//

import SwiftUI
import Firebase

struct MainChatView: View {
    @State private var showActivityIndicator = false
    @EnvironmentObject var appState: AppState
    // Mirrors
    @State private var isDelisha: Bool = false
    @State private var isAidan: Bool = false
    
    var body: some View {
        ConversationsView()
            .onAppear {
                SessionManager().logout()
                authenticateUser()
            }
        // Add onChange modifiers
            .onChange(of: appState.isDelisha) { _ in
                authenticateUser()
            }
            .onChange(of: appState.isAidan) { _ in
                authenticateUser()
            }
    }
    
    private func authenticateUser() {
        // Assuming that `isDelisha` and `isAidan` are mutually exclusive and handled elsewhere.
        let deviceId = SessionManager.shared.deviceId  // "delisha" or "aidan" as hardcoded in SessionManager
        
        showActivityIndicator = true
        Firestore.firestore()
            .collection("users")
            .whereField("deviceId", isEqualTo: deviceId)
            .getDocuments { (snapshot, error) in
                showActivityIndicator = false
                guard let snapshot = snapshot, error == nil else {
                    print("Huh")
                    return
                }
                
                if let document = snapshot.documents.first {
                    let data = document.data()
                    var url: URL? = nil
                    if let string = data["avatarURL"] as? String {
                        url = URL(string: string)
                    }
                    let user = User(id: document.documentID, name: data["nickname"] as? String ?? "", avatarURL: url, isCurrentUser: true)
                    SessionManager.shared.storeUser(user)
                } else {
                    // Handle the case where the user is not found
                    print("User is not found")
                }
            }
    }
}

#Preview {
    MainChatView()
}

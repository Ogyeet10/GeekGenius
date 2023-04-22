//
//  AppState.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseAuth

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool

    init() {
        isLoggedIn = Auth.auth().currentUser != nil
    }

    func signIn() {
        isLoggedIn = true
    }
}

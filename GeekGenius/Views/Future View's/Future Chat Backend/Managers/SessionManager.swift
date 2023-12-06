//
//  SessionManager.swift
//  ChatFirestoreExample
//
//  Created by Alisa Mylnikova on 13.06.2023.
//

import Foundation
import ExyteChat
import UIKit

let hasCurrentSessionKey = "hasCurrentSession"
let currentUserKey = "currentUser"

class SessionManager {

    static let shared = SessionManager()
    
    var appState: AppState! // Keep a reference to the AppState

    static var currentUserId: String {
        shared.currentUser?.id ?? ""
    }

    static var currentUser: User? {
        shared.currentUser
    }
    
    func configure(with appState: AppState) {
        self.appState = appState
    }

    private var _deviceId: String?
    
    var deviceId: String {
        if let deviceId = _deviceId {
            return deviceId
        }
        return computeDeviceId()
    }
    
    func resetAndRecomputeDeviceId() {
        // Invalidate the current device ID
        _deviceId = nil
        // Recompute the device ID
        _deviceId = computeDeviceId()
    }
    
    private func computeDeviceId() -> String {
        if appState?.isDelisha == true {
            return "Delisha"
        } else if appState?.isAidan == true {
            return "Aidan"
        } else {
            return UIDevice.current.identifierForVendor?.uuidString ?? ""
        }
    }

    @Published private var currentUser: User?

    func storeUser(_ user: User) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
        UserDefaults.standard.set(true, forKey: hasCurrentSessionKey)
        currentUser = user
    }

    func loadUser() {
            if let data = UserDefaults.standard.data(forKey: "currentUser") {
                currentUser = try? JSONDecoder().decode(User.self, from: data)
            }
        }

    func logout() {
        //currentUser = nil
        UserDefaults.standard.set(false, forKey: hasCurrentSessionKey)
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
}

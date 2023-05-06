//
//  UserSettings.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/5/23.
//

import Foundation
import Combine

enum NotificationFrequency: Int, CaseIterable, CustomStringConvertible {
    case hourly = 3600
    case daily = 86400
    case weekly = 604800
    case monthly = 2592000

    var description: String {
        switch self {
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

class UserSettings: ObservableObject {
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    @Published var selectedFrequency: NotificationFrequency {
        didSet {
            UserDefaults.standard.set(selectedFrequency.rawValue, forKey: "selectedFrequency")
        }
    }
    
    init() {
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        let savedFrequencyValue = UserDefaults.standard.integer(forKey: "selectedFrequency")
        if let savedFrequency = NotificationFrequency(rawValue: savedFrequencyValue) {
            self.selectedFrequency = savedFrequency
        } else {
            self.selectedFrequency = .daily
        }
    }
}




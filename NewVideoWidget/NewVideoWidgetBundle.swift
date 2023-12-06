//
//  NewVideoWidgetBundle.swift
//  NewVideoWidget
//
//  Created by Aidan Leuenberger on 10/6/23.
//

import WidgetKit
import SwiftUI
import Firebase

@main
struct NewVideoWidgetBundle: WidgetBundle {
    init() {
            FirebaseApp.configure() //Configure Firebase
        }
    var body: some Widget {
        NewVideoWidget()
    }
}

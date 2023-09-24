//
//  test.swift
//  Mac Genius
//
//  Created by Aidan Leuenberger on 8/15/23.
//

import SwiftUI

struct test: View {
    var body: some View {
        NavigationView {
                    // Your content here
                }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Action") {
                    // Perform the action
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Another Action") {
                    // Perform another action
                }
            }
            // Add more toolbar items as needed
        }
    }
}

#Preview {
    test()
}

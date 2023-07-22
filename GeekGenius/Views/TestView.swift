//
//  TestView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/21/23.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        Text("Hello, this is a test view!")
            .onAppear {
                print("TestView appeared!")
            }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}

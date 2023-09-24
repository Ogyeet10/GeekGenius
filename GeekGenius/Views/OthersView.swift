//
//  OthersView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/26/23.
//

import SwiftUI

struct OthersView: View {
    let text = "You know who you are"
    let colors: [Color] = [.blue, .purple]
    @State private var animate = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .foregroundColor(animate ? colors[(index + 1) % colors.count] : colors[index % colors.count])
            }
        }
        .onAppear() {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}






struct OthersView_Previews: PreviewProvider {
    static var previews: some View {
        OthersView()
    }
}

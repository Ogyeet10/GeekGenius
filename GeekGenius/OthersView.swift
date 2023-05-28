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

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .foregroundColor(colors[index % colors.count])
            }
        }
        
    }
}





struct OthersView_Previews: PreviewProvider {
    static var previews: some View {
        OthersView()
    }
}

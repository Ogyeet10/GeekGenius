//
//  OverlayView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/6/23.
//

import SwiftUI

struct OverlayView: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Rectangle()
                    .foregroundColor(.black)
                    .frame(width: 80, height: 80)
            }
            Spacer()
        }
    }
}

struct OverlayView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayView()
    }
}

//
//  ProfileDetailView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 9/21/23.
//

import SwiftUI

struct ProfileDetailView: View {
    var user: UserDetails
    var body: some View {
        VStack {
            // Display user profile photo
            if let imageURL = URL(string: user.profileImageURL) {
                AsyncImage(url: imageURL) { phase in
                    if phase.image == nil {
                        Image(systemName: "person.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    } else if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }
                }
            }
            
            // Existing user details
            Text("User Profile")
            Text("Display Name: \(user.displayName)")
            // Add more user details here
        }
    }
}


#Preview {
    ProfileDetailView(user: UserDetails(id: "12345", displayName: "Aidan Leuenberger", profileImageURL: "https://firebasestorage.googleapis.com:443/v0/b/geekgenius-cf2f0.appspot.com/o/profileImages%2FWRQDKUUd7fPcA1Ex5uCpymuQ8Xr1.jpg?alt=media&token=82497c59-2933-4b05-8df7-f5d3e1779d65"))
        .previewDisplayName("Profile Detail View")
}

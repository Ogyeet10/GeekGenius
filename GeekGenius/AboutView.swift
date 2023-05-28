//
//  AboutView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/26/23.
//

import SwiftUI

struct AboutView: View {
    let dedications = [
        "Connor. C",
        "Jericho. E",
        "Leo. R",
        "And others",
    ]
    
    @State private var selection: String? = nil
    
    var body: some View {
        List {
            Section(header: Text("About")) {
                    Text("GeekGenius is a project by me (Aidan Leuenberger) for my friends and classmates. This app allows you to not only view and watch content made by me (and hopefully other classmates) to your heart's content. Unfortunately, the video player is designed sub-optimally because I needed to prevent you from getting the YouTube link. The app is not free for a couple of reasons - primarily I would not have nearly enough motivation to complete this app but I also wanted to give myself a reason to put actual work into the content and app to give you the best experience for your money. If this makes enough money, I will fully update the video player to look amazing, but this requires money and for this to be sustainable I have to know how much I will make to be able to accurately judge how much money I can put into this non-essential feature. I hope you’ll have as much fun as I did making it. Also, I will be actively updating this app as I set the launch date to the 29th of May and I had to rush some things. Updates will most likely be pushed every other weekend or sooner, and content will be pushed every weekend. BTW, I know about the broken notifications. I will be fixing that in the coming weeks. I will also be adding a froms feture this will hopefully be done in a few weeks at most. I will also be makeing content over the summer, just less often. Finally, I want to dedicate this app to these people:")
                }
                
                Section(header: Text("Dedications")) {
                    ForEach(dedications, id: \.self) { dedication in
                        if dedication == "And others" {
                            NavigationLink(destination: OthersView()) {
                                Text(dedication)
                            }
                        } else {
                            Text(dedication)
                        }
                    }
                }
                
            Text("Designed with ❤️ by Aidan & GPT-4")
                            .multilineTextAlignment(.center)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .navigationTitle("About")
                }
            }




struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

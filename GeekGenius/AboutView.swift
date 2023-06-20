//
//  AboutView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/26/23.
//

import SwiftUI
import FirebaseFirestore

struct AboutView: View {
    let dedications = [
        "Connor. C",
        "Jericho. E",
        "Leo. R",
        "And others",
    ]
    
    @State private var selection: String? = nil
    @StateObject var othersViewVM = OthersViewViewModel()

    var body: some View {
        List {
            Section(header: Text("About")) {
                //The app is not free for a couple of reasons - primarily I would not have nearly enough motivation to complete this app but I also wanted to give myself a reason to put actual work into the content and app to give you the best experience for your money. If this makes enough money, I will fully update the video player to look amazing, but this requires money and for this to be sustainable I have to know how much I will make to be able to accurately judge how much money I can put into this non-essential feature.
                Text("GeekGenius is a project by me (Aidan Leuenberger) for my friends and classmates. This app allows you to not only view and watch content made by me (and hopefully other classmates) to your heart's content. I hope you’ll have as much fun as I did making it. Also, I will be actively updating this app as I set the launch date to the 29th of May and I had to rush some things. Updates will most likely be pushed every other weekend or sooner, and content will be pushed every weekend. I will make content over the summer, just less often. Finally, I want to dedicate this app to these people:")
                }
                
            Section(header: Text("Dedications")) {
                ForEach(dedications, id: \.self) { dedication in
                    if dedication == "And others" && othersViewVM.isEnabled {
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

class OthersViewViewModel: ObservableObject {
    var db = Firestore.firestore()
    @Published var isEnabled: Bool = false
    private var listener: ListenerRegistration?

    init() {
        self.fetchViewState()
    }
    
    deinit {
        listener?.remove()
    }

    private func fetchViewState() {
        let docRef = db.collection("variables").document("disableOthersView")
        
        listener = docRef.addSnapshotListener { (document, error) in
            if let document = document, let data = document.data() {
                DispatchQueue.main.async {
                    self.isEnabled = data["enabled"] as? Bool ?? false
                }
            }
        }
    }
}





struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

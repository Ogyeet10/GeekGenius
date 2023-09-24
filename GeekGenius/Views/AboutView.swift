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
        "Brian. D",
        "And others",
    ]
    
    @State private var selection: String? = nil
    @StateObject var othersViewVM = OthersViewViewModel()
    @State private var animate: [Bool] = Array(repeating: false, count: 10) // For animation control
    
    // Function to trigger the wave-like animation
        func triggerWaveAnimation(for dedication: String) {
            for i in 0..<dedication.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    withAnimation(Animation.easeInOut(duration: 0.3)) {
                        animate[i] = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05 + 0.3) {
                    withAnimation(Animation.easeInOut(duration: 0.3)) {
                        animate[i] = false
                    }
                }
            }
        }
    
    var body: some View {
        List {
            Section(header: Text("About")) {
                //The app is not free for a couple of reasons - primarily I would not have nearly enough motivation to complete this app but I also wanted to give myself a reason to put actual work into the content and app to give you the best experience for your money. If this makes enough money, I will fully update the video player to look amazing, but this requires money and for this to be sustainable I have to know how much I will make to be able to accurately judge how much money I can put into this non-essential feature.
                Text("GeekGenius is a project by me (Aidan Leuenberger) for my friends, family, general public, and classmates. This app allows you to not only view and watch content made by me (and other users eventually) to your heart's content but also interact with me and other users in the comments section. I hope you’ll have as much fun as I did making it. Also, I will be actively updating this app so expect an update every 2-3 weeks. Content might be pushed every weekend or so I might forget sometimes. Finally, I want to dedicate this app to these people:")
            }
            
            Section(header: Text("Dedications")) {
                            ForEach(dedications, id: \.self) { dedication in
                                if dedication == "And others" && othersViewVM.isEnabled {
                                    Button(action: {
                                        // Trigger animation on button click
                                        triggerWaveAnimation(for: dedication)
                                    }) {
                                        Text(dedication)
                                            .modifier(WaveTextModifier(animate: $animate))
                                    }
                                    .onAppear {
                                        // Wait for half a second before triggering the animation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            triggerWaveAnimation(for: dedication)
                                        }
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
                    self.isEnabled = data["disabled"] as? Bool ?? true
                }
            }
        }
    }
}


struct WaveTextModifier: ViewModifier {
    @Binding var animate: [Bool]
    
    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            ForEach(Array("And others".enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .foregroundColor(animate[index] ? (index % 2 == 0 ? Color.blue : Color.purple) : Color.primary)
                    .fontWeight(animate[index] ? .bold : .regular)
                    .animation(nil)  // Disable default animation
            }
        }
        .animation(Animation.easeInOut(duration: 0.3), value: animate)  // Apply custom animation
    }
}


struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

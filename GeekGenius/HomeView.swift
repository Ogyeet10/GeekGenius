//
//  HomeView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct HomeView: View {
    @State private var videos: [Video] = []
    @State private var hasActiveSubscription: Bool = false
    @State private var showingSubscriptionInfo = false
    
    var body: some View {
        NavigationView {
            VStack {
                if hasActiveSubscription {
                    List(videos) { video in
                        NavigationLink(destination:
                            YouTubeVideoView(videoID: video.videoID)
                                .overlay(OverlayView())
                                .onAppear {
                                    UIDevice.setOrientation(.landscapeLeft)
                                }
                            .onDisappear {
                                    UIDevice.setOrientation(.portrait)
                                }
                        ) {
                            VideoRow(video: video)
                        }
                    }
                    .navigationTitle("Tech Videos")
                } else {
                    VStack {
                        Text("You need an active subscription to access the content.")
                            .font(.headline)
                        
                        Button(action: {
                            showingSubscriptionInfo = true
                        }) {
                            Text("Get a Subscription")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .sheet(isPresented: $showingSubscriptionInfo) {
                            SubscriptionInfoView()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadVideos()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear(perform: {
                loadVideos()
                checkSubscriptionStatus()
            })
        }
    }
    
    func loadVideos() {
        let db = Firestore.firestore()
        
        db.collection("videos").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting videos: \(error.localizedDescription)")
            } else {
                videos = querySnapshot?.documents.compactMap { document in
                    guard let title = document.get("title") as? String,
                          let thumbnailUrl = document.get("thumbnailUrl") as? String,
                          let videoID = document.get("videoID") as? String else { return nil }
                    return Video(title: title, thumbnailUrl: thumbnailUrl, videoID: videoID)
                } ?? []
            }
        }
    }
    func checkSubscriptionStatus() {
        guard let user = Auth.auth().currentUser, let userEmail = user.email else { return }
        let db = Firestore.firestore()
        
        db.collection("subscriptions").document(userEmail).getDocument { (document, error) in
            if let error = error {
                print("Error getting subscription status: \(error.localizedDescription)")
            } else {
                if let document = document, document.exists {
                    if let expiryDate = document.get("expiryDate") as? Timestamp {
                        let expiryDateValue = expiryDate.dateValue()
                        hasActiveSubscription = expiryDateValue > Date()
                    }
                } else {
                    hasActiveSubscription = false
                }
            }
        }
    }

    
    struct Video: Identifiable {
        let id = UUID()
        let title: String
        let thumbnailUrl: String
        let videoID: String
    }

    struct VideoRow: View {
        let video: Video
        
        var body: some View {
            HStack {
                RemoteImage(url: video.thumbnailUrl)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 56)
                    .clipped()
                Text(video.title)
                    .font(.headline)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

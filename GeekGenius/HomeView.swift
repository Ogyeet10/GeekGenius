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
    @State private var searchText = ""
    @State private var isSubscriptionInfoViewPresented = false
    @State private var showingSortOptions = false
    @State private var sortOption: String = "dateAdded"
    
    
    
    var body: some View {
        NavigationStack {
            VStack {
                if hasActiveSubscription {
                    SearchBar(text: $searchText)
                    List {
                        ForEach(videos.filter { video in
                            searchText.isEmpty || video.title.lowercased().contains(searchText.lowercased())
                        }) { video in
                            NavigationLink(destination: YouTubeVideoView(videoID: video.videoID)
                                .overlay(OverlayView())
                            ) {
                                VideoRow(video: video)
                            }
                        }
                    }
                    .navigationTitle("Tech Videos")
                } else {
                    VStack {
                        Text("You need an active subscription to access the content.")
                            .font(.headline)
                        
                        Button(action: {
                            isSubscriptionInfoViewPresented = true
                        }) {
                            Text("Get a Subscription")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .navigationDestination(isPresented: $isSubscriptionInfoViewPresented, destination: {
                            SubscriptionInfoView()
                        })
                    }
                }
            }
            .actionSheet(isPresented: $showingSortOptions) {
                ActionSheet(title: Text("Sort By"), buttons: sortButtons())
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSortOptions = true
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Sort")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadVideos()
                        checkSubscriptionStatus()
                    }) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reload")
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
                          let videoID = document.get("videoID") as? String,
                          let dateAdded = document.get("dateAdded") as? Timestamp else {
                        print("Failed to parse document: \(document.data())")
                        return nil
                    }
                    return Video(title: title, thumbnailUrl: thumbnailUrl, videoID: videoID, dateAdded: dateAdded.dateValue())
                } ?? []
                
                // Call sortVideos() directly here, after videos have been fetched and populated
                sortVideos()
            }
        }
    }
    
    
    func sortButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        let options = ["dateAdded", "title"]
        for option in options {
            buttons.append(.default(Text(displayName(for: option))) {
                sortOption = option
                sortVideos()
            })
        }
        buttons.append(.cancel())
        return buttons
    }
    
    
    func displayName(for option: String) -> String {
        switch option {
        case "dateAdded":
            return "Date Added" + (sortOption == "dateAdded" ? " ✔︎" : "")
        case "title":
            return "Title" + (sortOption == "title" ? " ✔︎" : "")
        default:
            return "Unknown option"
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
    
    func sortVideos() {
        switch sortOption {
        case "dateAdded":
            videos = videos.sorted { $0.dateAdded > $1.dateAdded }
        case "title":
            videos = videos.sorted { $0.title < $1.title }
        default:
            print("Unknown sort option.")
        }
    }
    
    struct Video: Identifiable {
        let id = UUID()
        let title: String
        let thumbnailUrl: String
        let videoID: String
        let dateAdded: Date
    }
    
    struct VideoRow: View {
        let video: Video
        var formatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }
        
        var body: some View {
            HStack {
                RemoteImage(url: video.thumbnailUrl)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 56)
                    .clipped()
                
                VStack(alignment: .leading) {
                    Text(video.title)
                        .font(.headline)
                    
                    Text("Posted on: \(formatter.string(from: video.dateAdded))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

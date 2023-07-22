//
//  HomeView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Reachability
import Combine
import Network
import FirebaseAnalytics

struct HomeView: View {
    @State private var videos: [Video] = []
    // @State private var hasActiveSubscription: Bool = false
    @State private var showingSubscriptionInfo = false
    @State private var searchText = ""
    @State private var isSubscriptionInfoViewPresented = false
    @State private var showingSortOptions = false
    @State private var sortOption: String = "dateAdded"
    @StateObject private var reachability = ReachabilityObserver()
    @State private var isLoading = true
    @State private var lastDocument: DocumentSnapshot?
    @State private var isFetching = false
    @State private var allDocumentsLoaded = false
    @State private var videosLoaded = false
    @State private var isLoggedIn: Bool = true
    @State private var shouldShowLoginButton: Bool = false
    @State private var userID: String?

    
    var body: some View {
        NavigationStack {
            VStack {
                // First check for internet connection
                if isLoading {
                    LoadingView() // You'll need to create this
                } else if reachability.reachability.connection == .unavailable {
                    NoWifiView()
                // } else if hasActiveSubscription {
                } else {
                    // User has an active subscription and internet connection
                    SearchBar(text: $searchText)
                    List {
                        ForEach(videos.filter { video in
                            searchText.isEmpty || video.title.lowercased().contains(searchText.lowercased())
                        }) { video in
                            NavigationLink(destination: isLoggedIn ? YouTubeVideoDetailView(videoID: video.videoID, videoTitle: video.title, videoDescription: video.description, dateAdded: video.dateAdded, userID: userID ?? "Hehe") : nil) {
                                VideoRow(isLoggedIn: isLoggedIn, video: video)
                            }
                        }
                        
                        if !allDocumentsLoaded {
                            Button(action: {
                                if !isFetching {
                                    Task {
                                        await loadVideos()
                                    }
                                }
                            }) {
                                Text(isFetching ? "Loading..." : "Load more")
                            }
                        }
                    }
                    
                    .refreshable {
                        await loadVideos(reset: true)
                        // await checkSubscriptionStatus()
                    }
                    .navigationTitle("Tech Videos")
                // } else {
                    // User doesn't have an active subscription but has internet connection
                    // VStack {
                    //     Image(systemName: "dollarsign.circle")
                    //         .resizable()
                    //         .frame(width: 50, height: 50)
                    //         .foregroundColor(.red)
                        
                        
                    //     Text("You need an active subscription to access the content.")
                    //         .font(.headline)
                        
                        
                    //     Button(action: {
                    //         isSubscriptionInfoViewPresented = true
                    //     }) {
                    //         Text("Get a Subscription")
                    //             .font(.headline)
                    //             .foregroundColor(.blue)
                    //     }
                    //     .navigationDestination(isPresented: $isSubscriptionInfoViewPresented, destination: {
                    //         SubscriptionInfoView()
                    //     })
                    // }
                }
            }
            .environmentObject(reachability)
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
                        Task {
                            await loadVideos(reset: true)
                            // await checkSubscriptionStatus()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reload")
                    }
                }
            }
            .onAppear {
                Task {
                    if !videosLoaded {
                        await loadVideos()
                        // await checkSubscriptionStatus()
                        userID = Auth.auth().currentUser?.uid
                        videosLoaded = true
                    }
                }
            }
        }
    }
    
    
    // Update the loadVideos() function
    @MainActor
    func loadVideos(reset: Bool = false) async {
        isFetching = true
        let db = Firestore.firestore()
        let videosRef = db.collection("videos")
        var query: Query = videosRef.order(by: "dateAdded", descending: true).limit(to: 2) // Change the limit to suit your needs
        
        if reset {
            lastDocument = nil
            videos = []
            allDocumentsLoaded = false
        } else if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        do {
            let querySnapshot = try await query.getDocuments()
            
            lastDocument = querySnapshot.documents.last
            
            let newVideos: [Video] = querySnapshot.documents.compactMap { document -> Video? in
                guard let title = document.get("title") as? String,
                      let thumbnailUrl = document.get("thumbnailUrl") as? String,
                      let videoID = document.get("videoID") as? String,
                      let description = document.get("description") as? String, // parsing description
                      let dateAdded = document.get("dateAdded") as? Timestamp else {
                    print("Failed to parse document: \(document.data())")
                    return nil
                }
                
                return Video(title: title, thumbnailUrl: thumbnailUrl, videoID: videoID, dateAdded: dateAdded.dateValue(), description: description) // passing description
            }
            
            videos.append(contentsOf: newVideos)
            sortVideos()
            isFetching = false
            // set allDocumentsLoaded to true if there are no more documents to fetch
            allDocumentsLoaded = querySnapshot.documents.isEmpty
        } catch let error {
            print("Error getting videos: \(error.localizedDescription)")
        }
        isLoading = false // Added
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
    
    // Commented checkSubscriptionStatus
    /*
    @MainActor
    func checkSubscriptionStatus() async {
        guard let user = Auth.auth().currentUser, let userEmail = user.email else { return }
        let db = Firestore.firestore()
        
        do {
            let document = try await db.collection("subscriptions").document(userEmail).getDocument()
            
            if document.exists {
                if let expiryDate = document.get("expiryDate") as? Timestamp {
                    let expiryDateValue = expiryDate.dateValue()
                    hasActiveSubscription = expiryDateValue > Date()
                }
            } else {
                hasActiveSubscription = false
            }
            
        } catch let error {
            print("Error getting subscription status: \(error.localizedDescription)")
        }
        isLoading = false // Added
    }
    */
    
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
        let description: String // new field
    }
    
    struct VideoRow: View {
        let isLoggedIn: Bool
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
                    if !isLoggedIn {
                        Button(action: {
                            // navigate to login view
                        }) {
                            Text("Log in to watch")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}

struct NoWifiView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .resizable()
                .frame(width: 110, height: 100)
                .foregroundColor(.blue)
            
            Text("No Internet Connection")
                .font(.title)
                .foregroundColor(.gray)
            
            Text("Please check your network settings and try again.")
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView() // Or your custom loading UI
                .padding([.bottom], 0.5)
            Text("Loading...")
        }
    }
}

class ReachabilityObserver: ObservableObject {
    @Published var reachability: Reachability
    
    init(reachability: Reachability = try! Reachability()) {
        self.reachability = reachability
        do {
            try self.reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        self.reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        self.reachability.whenUnreachable = { _ in
            print("Not reachable")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
}
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

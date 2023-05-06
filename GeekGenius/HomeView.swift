//
//  HomeView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @State private var videos: [Video] = []
    
    var body: some View {
        NavigationView {
            List(videos) { video in
                NavigationLink(destination: YouTubeVideoView(videoID: video.videoID)) {
                    VideoRow(video: video)
                }
            }
            .navigationTitle("Tech Videos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadVideos()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear(perform: loadVideos)
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

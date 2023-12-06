//
//  NewVideoWidget.swift
//  NewVideoWidget
//
//  Created by Aidan Leuenberger on 10/6/23.
//

import WidgetKit
import SwiftUI
import FirebaseFirestore

struct VideoProvider: TimelineProvider {
    func placeholder(in context: Context) -> VideoEntry {
        VideoEntry(date: Date(), video: VideoIdWidget.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (VideoEntry) -> ()) {
        let entry = VideoEntry(date: Date(), video: VideoIdWidget.placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VideoEntry>) -> ()) {
        let db = Firestore.firestore()
        let videosRef = db.collection("videos")
        let query = videosRef.order(by: "dateAdded", descending: true).limit(to: 1)
        
        query.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting videos: \(err.localizedDescription)")
            } else if let document = querySnapshot?.documents.first {
                let video = VideoIdWidget(document: document)
                let entry = VideoEntry(date: Date(), video: video)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
            }
        }
    }
}


struct VideoEntry: TimelineEntry {
    let date: Date
    let video: VideoIdWidget
}

struct VideoIdWidget: Identifiable {
    var id: String
    var title: String
    var thumbnailUrl: String
    var description: String
    var dateAdded: Date
    
    // Placeholder video for preview purposes
    static var placeholder: VideoIdWidget {
        return VideoIdWidget(id: "1", title: "Sample Video", thumbnailUrl: "https://example.com/thumbnail.jpg", description: "This is a description of a sample video.", dateAdded: Date())
    }
    
    // Default initializer
    init(id: String, title: String, thumbnailUrl: String, description: String, dateAdded: Date) {
        self.id = id
        self.title = title
        self.thumbnailUrl = thumbnailUrl
        self.description = description
        self.dateAdded = dateAdded
    }
    
    // Initializer to create a Video instance from a Firestore document
    init(document: DocumentSnapshot) {
        self.id = document.documentID
        self.title = document.get("title") as? String ?? "No title"
        self.thumbnailUrl = document.get("thumbnailUrl") as? String ?? "https://example.com/thumbnail.jpg"
        self.description = document.get("description") as? String ?? "No description"
        if let timestamp = document.get("dateAdded") as? Timestamp {
            self.dateAdded = timestamp.dateValue()
        } else {
            self.dateAdded = Date()
        }
    }
}


struct NewVideoWidgetEntryView : View {
    var entry: VideoProvider.Entry
    let lightBlue = Color(red: 100 / 255, green: 200 / 255, blue: 255 / 255)
    
    let MfBlue = Color(red: 55 / 255, green: 145 / 255, blue: 220 / 255)
    
    var body: some View {
        VStack {
            if let url = URL(string: entry.video.thumbnailUrl),
               let imageData = try? Data(contentsOf: url),
               let uiImage = UIImage(data: imageData) {
                
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8)) // Adjust the cornerRadius value to your preference

            } else {
                Image("placeholder-image") // Use a placeholder image if loading from URL fails
            }
            
            Text("Latest Video") // Add text indicating it's a new video
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(MfBlue) // Customize the text color
            
            Text(entry.video.title)
                // ... other UI elements for displaying video information
        }
        .overlay(
            Image("Logo") // Replace "Logo" with the name of your logo image
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 4)) // Adjust the cornerRadius value to your preference
                .frame(width: 15, height: 15), // Adjust the size of your logo here
            alignment: .bottomLeading
        )
        .containerBackground(for: .widget) {
            LinearGradient(
                    gradient: Gradient(colors: [.blue, lightBlue]), // Specify your gradient colors here
                    startPoint: .top,
                    endPoint: .bottom
                )
            
        }

    }
}

struct NewVideoWidget: Widget {
    let kind: String = "NewVideoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VideoProvider()) { entry in
            NewVideoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("New Video Widget")
        .description("Displays the most recent video.")
    }
}


#Preview(as: .systemSmall) {
    NewVideoWidget()
} timelineProvider: {
    VideoProvider()
}

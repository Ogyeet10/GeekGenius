//
//  ContentView.swift
//  Mac Genius
//
//  Created by Aidan Leuenberger on 6/20/23.
//

import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    @State private var videoName: String = ""
    @State private var youtubeURL: String = ""
    @State private var description: String = ""
    
    @State private var showAlert = false
    @State private var alertTitle = "Error"
    @State private var alertMessage = ""
    
    let db = Firestore.firestore()
    
    
    var thumbnailURL: String {
        guard let videoID = getVideoID(from: youtubeURL) else {
            return "placeholder" // Replace with your placeholder image name
        }
        let url = "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg"
        print("Computed URL: \(url)")
        return url
    }
    
    var body: some View {
        TabView {
            HStack(spacing: 1.0) {
                AsyncImage(url: URL(string: thumbnailURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure(_):
                        Image("placeholder") // Replace with your placeholder image name
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                            .background(Color.gray.opacity(0.2))
                    case .empty:
                        Image("placeholder") // Replace with your placeholder image name
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                            .background(Color.gray.opacity(0.2))
                    @unknown default:
                        Image("placeholder") // Replace with your placeholder image name
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                            .background(Color.gray.opacity(0.2))
                    }
                }
                
                VStack {
                    TextField("Video Name", text: $videoName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("YouTube URL", text: $youtubeURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                    
                    Button(action: {
                        postVideo()
                    }) {
                        Text("Post")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        
                    }
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .padding()
            .tabItem {
                VStack {
                    Image(systemName: "globe")
                }
                Text("Post")
            }
            
            // Add more tabs as needed
            Text("Content for Tab 2")
                .tabItem {
                    Image(systemName: "map")
                    Text("Videos")
                }
        }
    }
    
    func postVideo() {
        // Check if any field is empty
        guard !videoName.isEmpty, !youtubeURL.isEmpty, !description.isEmpty else {
            alertTitle = "Error"
            alertMessage = "All fields must be filled in."
            showAlert = true
            return
        }

        // Check if the URL is valid
        guard let url = URL(string: youtubeURL), url.scheme != nil, url.host != nil else {
            alertTitle = "Invalid URL"
            alertMessage = "Please enter a valid URL."
            showAlert = true
            return
        }

        guard let videoID = getVideoID(from: youtubeURL) else {
            alertTitle = "Invalid YouTube URL"
            alertMessage = "Please enter a valid YouTube URL."
            showAlert = true
            return
        }

        db.collection("videos").document().setData([
            "dateAdded": Timestamp(date: Date()),
            "description": description,
            "likes": 1,
            "thumbnailUrl": thumbnailURL,
            "title": videoName,
            "videoID": videoID
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
                alertTitle = "Error"
                alertMessage = "An error occurred while trying to post the video: \(error.localizedDescription)"
            } else {
                print("Document successfully added")
                alertTitle = "Success"
                alertMessage = "The video was successfully posted."
                self.resetFields()
            }
            showAlert = true
        }
    }


    
    func resetFields() {
        videoName = ""
        youtubeURL = ""
        description = ""
    }
}

func getVideoID(from url: String) -> String? {
    if let regex = try? NSRegularExpression(pattern: "(?<=watch\\?v=|/videos/|embed\\/|youtu.be\\/|\\/v\\/|\\/e\\/|watch\\?v%3D|watch\\?feature=player_embedded&v=|%2Fvideos%2F|embed%\u{200C}\u{200B}2F|youtu.be%2F|%2Fv%2F)[^#\\&\\?\\n]*", options: .caseInsensitive) {
        let nsString = url as NSString
        let range = NSMakeRange(0, nsString.length)
        let match = regex.firstMatch(in: url, options: [], range: range)
        if let match = match {
            return nsString.substring(with: match.range)
        }
    }
    return nil
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

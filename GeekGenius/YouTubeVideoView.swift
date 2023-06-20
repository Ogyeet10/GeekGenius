//
//  YouTubeVideoView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/18/23.
//

import SwiftUI
import WebKit
import FirebaseFirestore

struct YouTubeVideoDetailView: View {
    let videoID: String
    let videoTitle: String
    let videoDescription: String
    let dateAdded: Date   // Add this line
    @ObservedObject var likesViewModel: LikesViewModel
    let userID: String?  // assuming you have access to userID
    @EnvironmentObject var appState: AppState
    @State private var videoIsLoading: Bool = true  // Add this line
    @State private var showingLoginAlert: Bool = false
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    init(videoID: String, videoTitle: String, videoDescription: String, dateAdded: Date, userID: String) {
            self.videoID = videoID
            self.videoTitle = videoTitle
            self.videoDescription = videoDescription
            self.dateAdded = dateAdded
            self.userID = userID
            self.likesViewModel = LikesViewModel(userID: userID, videoID: videoID)
        }
    
    var body: some View {
        ScrollView {
            VStack {
                YouTubeVideoView(videoIsLoading: $videoIsLoading, videoID: videoID)  // Add the videoIsLoading binding here
                    .frame(height: UIScreen.main.bounds.width * 9 / 16)
                    .overlay(
                        ProgressView() // This will display a loading spinner
                            .scaleEffect(2)
                            .opacity(videoIsLoading ? 1 : 0)
                    )
                VStack(alignment: .leading) {
                    Text(videoTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    Button(action: {
                        if self.appState.isGuest {
                            self.showingLoginAlert = true
                        } else {
                            likesViewModel.handleLikeButtonPress(userID: userID!, videoID: videoID)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()

                        }
                    }) {
                        Image(systemName: likesViewModel.hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    }
                    .alert(isPresented: $showingLoginAlert) {
                        Alert(
                            title: Text("You need to log in to like a video."),
                            message: Text("Would you like to log in now?"),
                            primaryButton: .default(Text("Log In"), action: {
                                // Perform login actions here
                                self.appState.isGuest = false
                                self.showingLoginAlert = false
                                
                            }),
                            secondaryButton: .cancel(Text("Not Now"))
                        )
                    }

                    Text("\(likesViewModel.likesCount) likes")
                    Text(dateFormatter.string(from: dateAdded))  // Add this line
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(videoDescription)
                        .font(.body)
                        .padding(.top, 2)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading) // Add this line
            }
        }
    }
}

struct YouTubeVideoView: UIViewRepresentable {
    @Binding var videoIsLoading: Bool // Add this
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body { margin: 0; background-color: #000; }
                iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
            </style>
            <script>
                document.addEventListener('DOMContentLoaded', function () {
                    document.body.style.webkitTouchCallout='none';
                    document.body.style.webkitUserSelect='none';
                }, false);
            </script>
        </head>
        <body>
            <iframe src="https://www.youtube.com/embed/\(videoID)?playsinline=1&autoplay=1&rel=0&modestbranding=1" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
        </body>
        </html>
        """
        
        
        
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: YouTubeVideoView
        
        init(_ parent: YouTubeVideoView) {
            self.parent = parent
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {  // It's always safe to update @State or @Binding properties on the main thread
                self.parent.videoIsLoading = false // Set to false when the video finishes loading
            }
        }
    }
}
    struct Video: Identifiable {
        let id: UUID = UUID()
        let title: String
        let thumbnailUrl: String
        let videoID: String
        let dateAdded: Date
        let description: String // Adding new field here
    }
    
class LikesViewModel: ObservableObject {
    var db = Firestore.firestore()
    @Published var hasLiked: Bool = false
    @Published var likesCount: Int = 0

    init(userID: String, videoID: String) {
        self.fetchInitialState(userID: userID, videoID: videoID)
    }

    private func fetchInitialState(userID: String, videoID: String) {
        let userLikesDocRef = db.collection("user_likes").document("\(userID)_\(videoID)")

        userLikesDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                DispatchQueue.main.async {
                    self.hasLiked = true
                }
            }
        }

        getDocumentId(videoID: videoID) { documentID in
            guard let documentID = documentID else {
                print("Failed to get documentID for videoID: \(videoID)")
                return
            }
            
            let videoDocRef = self.db.collection("videos").document(documentID)

            videoDocRef.getDocument { (document, error) in
                if let document = document, let data = document.data() {
                    DispatchQueue.main.async {
                        self.likesCount = data["likes"] as? Int ?? 0
                    }
                }
            }
        }
    }

    func handleLikeButtonPress(userID: String, videoID: String) {
        let userLikesDocRef = db.collection("user_likes").document("\(userID)_\(videoID)")

        getDocumentId(videoID: videoID) { documentID in
            guard let documentID = documentID else {
                print("Failed to get documentID for videoID: \(videoID)")
                return
            }

            let videoDocRef = self.db.collection("videos").document(documentID)

            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let userDocument: DocumentSnapshot
                do {
                    try userDocument = transaction.getDocument(userLikesDocRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                if userDocument.exists {
                    // User has already liked this video. Unlike it.
                    transaction.deleteDocument(userLikesDocRef)
                    transaction.updateData(["likes": FieldValue.increment(Int64(-1))], forDocument: videoDocRef)
                    DispatchQueue.main.async {
                        self.hasLiked = false
                        self.likesCount -= 1
                    }
                } else {
                    // User has not liked this video. Like it.
                    transaction.setData(["userID": userID, "videoID": videoID], forDocument: userLikesDocRef)
                    transaction.updateData(["likes": FieldValue.increment(Int64(1))], forDocument: videoDocRef)
                    DispatchQueue.main.async {
                        self.hasLiked = true
                        self.likesCount += 1
                    }
                }

                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                } else {
                    print("Transaction successfully committed!")
                }
            }
        }
    }

    private func getDocumentId(videoID: String, completion: @escaping (String?) -> Void) {
        db.collection("videos").whereField("videoID", isEqualTo: videoID).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documentID: \(error)")
                completion(nil)
            } else if let document = snapshot?.documents.first {
                completion(document.documentID)
            } else {
                completion(nil)
            }
        }
    }
}



    
    struct YouTubeVideoDetailView_Previews: PreviewProvider {
        static var previews: some View {
            YouTubeVideoDetailView(videoID: "1jsEsnC8BCU", videoTitle: "Test", videoDescription: "In this video we test out the capabilatys of wsl and ", dateAdded: Date(), userID: "XWW9jDPMhOU6traf5uURHoMlpDl2") // Replace with a valid YouTube video ID
        }
    }
    
    
    
    

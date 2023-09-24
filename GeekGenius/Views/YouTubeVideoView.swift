//
//  YouTubeVideoView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/18/23.
//

import SwiftUI
import WebKit
import Combine
import Firebase
import FirebaseStorage

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
    @ObservedObject var commentsViewModel: CommentsViewModel
    @State private var newComment: String = ""
    @State private var showingLoginAlertForComment: Bool = false
    @State private var sortOrder: SortOrder = .oldestFirst
    @State private var hasFetchedComments = false

    
    
    
    
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
        self.commentsViewModel = CommentsViewModel(videoID: videoID)
    }
    
    enum SortOrder {
        case oldestFirst
        case newestFirst
        
        var description: String {
            switch self {
            case .oldestFirst:
                return "Oldest First"
            case .newestFirst:
                return "Newest First"
            }
        }
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
                    .overlay(    // Add this overlay to prevent interaction with the three dots
                        GeometryReader { geometry in
                            ZStack {
                                Color.clear
                                VStack {
                                    HStack {
                                        Spacer()
                                        Rectangle()
                                            .fill(Color.white.opacity(0.0001)) // change to near transparent
                                            .frame(width: 80, height: 80)
                                    }
                                    Spacer()
                                }
                            }
                        }
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
                        .padding(.trailing)
                    
                    ZStack {
                        TextField("Add a comment...", text: $newComment, axis: .vertical)
                        .padding(10) // Reduce the padding value
                        .lineLimit(5)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .overlay(
                            Button(action: postComment) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(newComment.isEmpty ? Color.gray : Color.blue) // Change color based on whether newComment is empty
                                    .padding()
                                    .animation(.easeInOut, value: newComment) // Animate changes to newComment
                            }
                            .padding(.trailing), // Adds padding to the trailing side of the button
                            alignment: .trailing // Aligns the button to the trailing side of the text field
                        )
                    }



                        .alert(isPresented: $showingLoginAlertForComment) {
                            Alert(
                                title: Text("You need to log in to comment."),
                                message: Text("Would you like to log in now?"),
                                primaryButton: .default(Text("Log In"), action: {
                                    // Perform login actions here
                                    self.appState.isGuest = false
                                    self.showingLoginAlertForComment = false
                                }),
                                secondaryButton: .cancel(Text("Not Now"))
                                
                            )
                        }
                    
                    
                    Divider()
                    
                    // Display comments
                    @State var userDetails: [String: UserDetails] = [:] // This should be populated with data
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Comments")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            
                            Spacer()  // It pushes the following views to the right
                            
                            Menu {
                                Button(action: {
                                    sortOrder = .oldestFirst
                                    commentsViewModel.fetchComments(videoID: videoID, sortDescending: false)
                                }) {
                                    HStack {
                                        Text("Oldest First")
                                        if sortOrder == .oldestFirst {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    sortOrder = .newestFirst
                                    commentsViewModel.fetchComments(videoID: videoID, sortDescending: true)
                                }) {
                                    HStack {
                                        Text("Newest First")
                                        if sortOrder == .newestFirst {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Sort By")
                                    Image(systemName: "arrow.up.arrow.down")
                                }
                                .padding(.trailing)
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)

                        
                        
                        CommentSectionView(commentsViewModel: commentsViewModel)

                        .onReceive(commentsViewModel.$comments) { newComments in
                            print("Comments updated: \(newComments)")
                        }
                    }
                    .onAppear {
                        if !hasFetchedComments {
                            commentsViewModel.fetchComments(videoID: videoID)
                            print("Fetched Comments")
                            hasFetchedComments = true
                        }
                    }
                }
                .padding(.leading)
            }
       Spacer()
            
        }
        
    }
    
        private func postComment() {
            guard let userID = userID, !newComment.isEmpty else { return }
            commentsViewModel.addComment(userID: userID, videoID: videoID, content: newComment)
            newComment = ""
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

struct Comment: Identifiable, Hashable {
    let id: String
    let userID: String
    let videoID: String
    let content: String
    let dateAdded: Date
    let isEdited: Bool
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

class CommentsViewModel: ObservableObject {
    var db = Firestore.firestore()
    @Published var comments: [Comment] = []
    @Published var users: [UserViewModel] = []
    var cancellables = Set<AnyCancellable>()
    
    init(videoID: String) {
        commentsSubject
            .sink(receiveCompletion: { completion in
                // Handle errors
            }, receiveValue: { comments in
                self.comments = comments
            })
            .store(in: &cancellables)
    }
    
    let commentsSubject = CurrentValueSubject<[Comment], Error>([])
    
    func fetchComments(videoID: String, sortDescending: Bool = false) {
        self.db.collection("videos").document(videoID).collection("comments")
            .order(by: "dateAdded", descending: sortDescending)
            .addSnapshotListener { (querySnapshot, error) in
                self.users = []
                if let error = error {
                    self.commentsSubject.send(completion: .failure(error))
                } else {
                    print("Received an update from Firestore.")
                    let comments = querySnapshot?.documents.compactMap { (queryDocumentSnapshot) -> Comment? in
                        let data = queryDocumentSnapshot.data()
                        
                        
                        let id = queryDocumentSnapshot.documentID
                        let userID = data["userID"] as? String ?? ""
                        let videoID = data["videoID"] as? String ?? ""
                        let content = data["content"] as? String ?? ""
                        let timestamp = data["dateAdded"] as? Timestamp
                        let isEdited = data["isEdited"] as? Bool ?? false
                        let dateAdded = timestamp?.dateValue() ?? Date()
                        
                        let userViewModel = UserViewModel(userID: userID)
                        self.users.append(userViewModel)
                        
                        return Comment(id: id, userID: userID, videoID: videoID, content: content, dateAdded: dateAdded, isEdited: isEdited)
                        
                    } ?? []
                    print("Updated comments: \(comments)")
                    self.commentsSubject.send(comments)  // Update the publisher
                }
            }
    }
    
    
    func deleteComment(videoID: String, commentID: String) {
        print("Deleting comment with videoID: \(videoID) and commentID: \(commentID)")
        db.collection("videos").document(videoID).collection("comments").document(commentID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    func updateComment(videoID: String, commentID: String, content: String) {
        let db = Firestore.firestore()
        db.collection("videos").document(videoID).collection("comments").document(commentID).updateData(["content": content, "isEdited": true]) { err in
            if let err = err {
                print("Error updating comment: \(err)")
            } else {
                print("Comment successfully updated!")
            }
        }
    }
    
    func addComment(userID: String, videoID: String, content: String) {
        let data: [String: Any] = [
            "userID": userID,
            "videoID": videoID,
            "content": content,
            "dateAdded": Date(),
            "isEdited": false

        ]
        db.collection("videos").document(videoID).collection("comments").addDocument(data: data) { error in
            if let error = error {
                print("Error adding comment: \(error)")
            } else {
                print("Comment successfully added!")
            }
        }
    }
}

struct UserDetails: Identifiable {
    let id: String
    let displayName: String
    let profileImageURL: String
    var profileImage: UIImage? // Add this line
}

struct CommentRowView: View {
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var commentsViewModel: CommentsViewModel
    let comment: Comment
    @State private var isEditing: Bool = false
    @State private var editedContent: String
    @State private var isEdited: Bool = false

    init(comment: Comment, commentsViewModel: CommentsViewModel) {
        self.comment = comment
        self._userViewModel = ObservedObject(wrappedValue: UserViewModel(userID: comment.userID))
        self._commentsViewModel = ObservedObject(wrappedValue: commentsViewModel)
        self._editedContent = State(initialValue: comment.content)
    }
    
    var body: some View {
        HStack {
            // Updated AsyncImage code
            if let user = userViewModel.user, let imageURL = URL(string: user.profileImageURL) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        // Display a loading spinner while the image is loading
                        ProgressView()
                            .frame(width: 40, height: 40)
                    case .success(let image):
                        // Display the loaded image
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    case .failure:
                        // Display a default image if loading fails or if the user doesn't have a profile picture
                        Image(systemName: "person.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    @unknown default:
                        // Fallback to a default image
                        Image(systemName: "person.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                }
                        } else {
                            // Display a default image if the user doesn't have a profile picture
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
            VStack(alignment: .leading) {
                if let user = userViewModel.user {
                    HStack {
                        Text(user.displayName)
                            .font(.headline)
                        Text("\(comment.dateAdded, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if comment.isEdited {
                                Text("(Edited)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                    }
                }
                
                if isEditing {
                    TextField("Edit comment", text: $editedContent)
                    .font(.subheadline)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(comment.content)
                        .font(.subheadline)
                }
                
                                
            }
            
            Spacer() // Push the Menu to the right

            if isEditing {
                Button(action: {
                    withAnimation(.default) {
                        commentsViewModel.updateComment(videoID: comment.videoID, commentID: comment.id, content: editedContent)
                        print("Commit changes")
                        isEditing = false
                    }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding(.trailing)
                .transition(.move(edge: .trailing))
            } else {
                Menu {
                    Button(action: {
                        withAnimation(.default) {
                            // Add your edit comment logic here
                            isEditing = true
                            print("Edit comment")
                        }
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        commentsViewModel.deleteComment(videoID: comment.videoID, commentID: comment.id)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(userViewModel.user?.id != Auth.auth().currentUser?.uid) // Enable menu only for the user who posted the comment
                .padding(.trailing)
                .transition(.move(edge: .trailing))
            }
        }
        .id(commentsViewModel.comments.hashValue)
        Divider() // This adds a line between each comment
    }


    
    func deleteComment(videoID: String, commentID: String) {
        let db = Firestore.firestore()
        db.collection("videos").document(videoID).collection("comments").document(commentID).delete() { err in
            if let err = err {
                print("Error deleting comment: \(err)")
            } else {
                print("Comment successfully deleted!")
            }
        }
    }
    
    func updateComment(videoID: String, commentID: String, content: String) {
        let db = Firestore.firestore()
        db.collection("videos").document(videoID).collection("comments").document(commentID).updateData(["content": content]) { err in
            if let err = err {
                print("Error updating comment: \(err)")
            } else {
                print("Comment successfully updated!")
            }
        }
    }
}



class UserViewModel: ObservableObject {
    var db = Firestore.firestore()
    @Published var user: UserDetails?
    @Published var profileImage: UIImage?

    init(userID: String) {
        fetchUser(userID: userID)
    }
    
    private func fetchUser(userID: String) {
        db.collection("users").document(userID).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                let displayName = data["displayName"] as? String ?? ""
                let profileImageURL = data["profileImageURL"] as? String ?? ""
                
                DispatchQueue.main.async {
                    self.user = UserDetails(id: userID, displayName: displayName, profileImageURL: profileImageURL)
                }
            } else {
                print("User does not exist")
            }
        }
    }
    private func downloadProfileImage(url: String, completion: @escaping (UIImage?) -> Void) {
            let storageRef = Storage.storage().reference(forURL: url)
            
            storageRef.getData(maxSize: Int64(5 * 1024 * 1024)) { data, error in
                if let error = error {
                    print("Error downloading profile image: \(error.localizedDescription)")
                    completion(nil)
                } else if let data = data {
                    let image = UIImage(data: data)
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }
}

var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

struct CommentSectionView: View {
    @ObservedObject var commentsViewModel: CommentsViewModel
    var body: some View {
        ForEach(commentsViewModel.comments.indices, id: \.self) { index in
            let comment = commentsViewModel.comments[index]
            CommentRowView(comment: comment, commentsViewModel: commentsViewModel)
        }
    }
}

struct YouTubeVideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        YouTubeVideoDetailView(videoID: "IXIHEwRy4qk", videoTitle: "Test", videoDescription: "In this video we test out the capabilatys of wsl and ", dateAdded: Date(), userID: "WRQDKUUd7fPcA1Ex5uCpymuQ8Xr1") // Replace with a valid YouTube video ID
    }
}





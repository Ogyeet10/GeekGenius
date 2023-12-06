//
//  ConversationViewModel.swift
//  ChatFirestoreExample
//
//  Created by Alisa Mylnikova on 13.06.2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import ExyteChat
import Combine


@MainActor
class ConversationViewModel: ObservableObject {
    @Published var userTypingStatus: Bool = false
    @Published var userOnlineStatus: Bool = false
    
    private var typingStatusListener: ListenerRegistration?
    private var onlineStatusListener: ListenerRegistration?
    
    var users: [User] // not including current user
    var allUsers: [User]
    
    var conversationId: String?
    var conversation: Conversation? {
        if let id = conversationId {
            return dataStorage.conversations.first(where: { $0.id == id })
        }
        return nil
    }
    
    private var conversationDocument: DocumentReference?
    private var messagesCollection: CollectionReference?
    
    @Published var messages: [Message] = []
    
    var lock = NSRecursiveLock()
    
    private var subscribtionToConversationCreation: ListenerRegistration?
    
    //private var cancellables = Set<AnyCancellable>()
    
    
    private var typingTimer: Timer?
    private let typingUpdateInterval: TimeInterval = 2.0 // seconds
    private var lastDraftText: String = ""
    
    //var chatViewModel: ChatViewModel?
    
    private func addObserverForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        // Keyboard is showing, user might be typing
        
        updateUserTypingStatus(isTyping: true)
        print("Keyboard is shown")
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // Keyboard is hiding, user stopped typing
        updateUserTypingStatus(isTyping: false)
        print("Keyboard is hidden")
    }
    
    private func updateUserTypingStatus(isTyping: Bool) {
        DispatchQueue.main.async {
            DataStorageManager.shared.updateUserStatus(userId: SessionManager.currentUserId, isTyping: isTyping)
        }
    }
    
    private func addObserverForAppStateNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        updateUserOnlineStatus(isOnline: true)
        print("App did become active")
    }

    @objc private func appDidEnterBackground() {
        updateUserOnlineStatus(isOnline: false)
        print("App did enter background")
    }

    private func updateUserOnlineStatus(isOnline: Bool) {
        DispatchQueue.main.async {
            DataStorageManager.shared.updateUserStatus(userId: SessionManager.currentUserId, isOnline: isOnline)
        }
    }

    
    func userIsTyping(_ newDraftText: String) {
        // Dispatch to the main thread to satisfy MainActor requirements
        DispatchQueue.main.async { [weak self] in
            // Check if the draft text has actually changed to prevent unnecessary updates
            guard self?.lastDraftText != newDraftText else { return }
            self?.lastDraftText = newDraftText
            
            // User has started typing, so set isTyping to true
            DataStorageManager.shared.updateUserStatus(userId: SessionManager.currentUserId, isTyping: true)
            
            // Invalidate the old timer and start a new one
            self?.typingTimer?.invalidate()
            self?.typingTimer = Timer.scheduledTimer(withTimeInterval: self?.typingUpdateInterval ?? 2.0, repeats: false) { [weak self] _ in
                // User has stopped typing, set isTyping to false
                DataStorageManager.shared.updateUserStatus(userId: SessionManager.currentUserId, isTyping: false)
                
                DispatchQueue.main.async { [weak self] in
                    self?.lastDraftText = "" // Reset last draft text
                }
            }
        }
    }
    
    /* func listenToChatViewModel() {
     chatViewModel?.textDidChangePublisher
     .sink { [weak self] newText in
     self?.userIsTyping(newText)
     }
     .store(in: &cancellables)
     }*/
    
    init(user: User) {
        self.users = [user]
        self.allUsers = [user]
        if let currentUser = SessionManager.currentUser {
            self.allUsers.append(currentUser)
        }
        // setup conversation and messagesCollection later, after it's created
        // either when another user creates it by sending the first message
        subscribeToConversationCreation(user: user)
        // or when this user sends first message
        addObserverForKeyboardNotifications()
        addObserverForAppStateNotifications()
        self.updateUserOnlineStatus(isOnline: true)
        print("is now online")
        // Subscribe to user status updates
        for user in allUsers {
            subscribeToUserStatus()
        }
    }
    
    init(conversation: Conversation) {
        self.users = conversation.users.filter { $0.id != SessionManager.currentUserId }
        self.allUsers = conversation.users
        // Subscribe to user status updates
        for user in allUsers {
            subscribeToUserStatus()
        }
        updateForConversation(conversation)
        addObserverForKeyboardNotifications()
        addObserverForAppStateNotifications()
        self.updateUserOnlineStatus(isOnline: true)
        print("is now online")
    }
    
    func updateForConversation(_ conversation: Conversation) {
        self.conversationId = conversation.id
        makeFirestoreReferences(conversation.id)
        subscribeToMessages()
    }
    
    func makeFirestoreReferences(_ conversationId: String) {
        self.conversationDocument = Firestore.firestore()
            .collection(Collection.conversations)
            .document(conversationId)
        
        self.messagesCollection = Firestore.firestore()
            .collection(Collection.conversations)
            .document(conversationId)
            .collection(Collection.messages)
    }
    
    func resetUnreadCounter() {
        if var usersUnreadCountInfo = conversation?.usersUnreadCountInfo {
            usersUnreadCountInfo[SessionManager.currentUserId] = 0
            conversationDocument?.updateData(["usersUnreadCountInfo" : usersUnreadCountInfo])
        }
    }
    
    func bumpUnreadCounters() {
        if var usersUnreadCountInfo = conversation?.usersUnreadCountInfo {
            usersUnreadCountInfo = usersUnreadCountInfo.mapValues { $0 + 1 }
            usersUnreadCountInfo[SessionManager.currentUserId] = 0
            conversationDocument?.updateData(["usersUnreadCountInfo" : usersUnreadCountInfo])
        }
    }
    
    func subscribeToUserStatus() {
        // Determine the user ID based on appState conditions
        let userId: String
        if AppState().isAidan {
            userId = "Delisha"
        } else if AppState().isDelisha {
            userId = "Aidan"
        } else {
            // Handle the unexpected case where neither is true, if necessary
            print("Unexpected state: neither Aidan nor Delisha is set.")
            return
        }

        // Now use this userId for subscribing to status updates
        DataStorageManager.shared.subscribeToUserTypingStatusUpdates(userId: userId)
        DataStorageManager.shared.subscribeToUserOnlineStatusUpdates(userId: userId)

        // Update the local properties based on changes in DataStorageManager
        DataStorageManager.shared.$userTypingStatus
            .map { $0[userId] ?? false }
            .assign(to: &$userTypingStatus)
        
        DataStorageManager.shared.$userOnlineStatus
            .map { $0[userId] ?? false }
            .assign(to: &$userOnlineStatus)
    }

    
    // MARK: - get/send messages
    
    func subscribeToMessages() {
        messagesCollection?
            .order(by: "createdAt", descending: false)
            .addSnapshotListener() { [weak self] (snapshot, _) in
                guard let self = self else { return }
                let messages = snapshot?.documents
                    .compactMap { try? $0.data(as: FirestoreMessage.self) }
                    .compactMap { firestoreMessage -> Message? in
                        guard
                            let id = firestoreMessage.id,
                            let user = self.allUsers.first(where: { $0.id == firestoreMessage.userId }),
                            let date = firestoreMessage.createdAt
                        else { return nil }
                        
                        let convertAttachments: ([FirestoreAttachment]) -> [Attachment] = { attachments in
                            attachments.compactMap {
                                if let thumbURL = $0.thumbURL.toURL(), let url = $0.url.toURL() {
                                    return Attachment(id: UUID().uuidString, thumbnail: thumbURL, full: url, type: $0.type)
                                }
                                return nil
                            }
                        }
                        
                        let convertRecording: (FirestoreRecording?) -> Recording? = { recording in
                            if let recording = recording {
                                return Recording(duration: recording.duration, waveformSamples: recording.waveformSamples, url: recording.url.toURL())
                            }
                            return nil
                        }
                        
                        var replyMessage: ReplyMessage?
                        if let reply = firestoreMessage.replyMessage,
                           let replyId = reply.id,
                           let replyUser = self.allUsers.first(where: { $0.id == reply.userId }) {
                            replyMessage = ReplyMessage(
                                id: replyId,
                                user: replyUser,
                                text: reply.text,
                                attachments: convertAttachments(reply.attachments),
                                recording: convertRecording(reply.recording))
                        }
                        
                        return Message(
                            id: id,
                            user: user,
                            status: .sent,
                            createdAt: date,
                            text: firestoreMessage.text,
                            attachments: convertAttachments(firestoreMessage.attachments),
                            recording: convertRecording(firestoreMessage.recording),
                            replyMessage: replyMessage)
                    } ?? []
                self.lock.withLock {
                    let localMessages = self.messages
                        .filter { $0.status != .sent }
                        .filter { localMessage in
                            messages.firstIndex { message in
                                message.id == localMessage.id
                            } == nil
                        }
                        .sorted { $0.createdAt < $1.createdAt }
                    self.messages = messages + localMessages
                }
            }
    }
    
    func sendMessage(_ draft: DraftMessage) {
        Task {
            /// create conversation in Firestore if needed
            // only create individual conversation when first message is sent
            // group conversation was created before (UsersViewModel)
            if conversation == nil,
               users.count == 1,
               let user = users.first,
               let conversation = await createIndividualConversation(user) {
                updateForConversation(conversation)
            }
            
            /// precreate message with fixed id and .sending status
            guard let user = SessionManager.currentUser else { return }
            let id = UUID().uuidString
            let message = await Message.makeMessage(id: id, user: user, status: .sending, draft: draft)
            lock.withLock {
                messages.append(message)
            }
            
            /// convert to Firestore dictionary: replace users with userIds, upload medias and get urls, replace urls with strings
            let dict = await makeDraftMessageDictionary(draft)
            
            /// upload dictionary with the same id we fixed earlier, so Chat knows it's still the same message
            do {
                try await messagesCollection?.document(id).setData(dict)
                // no need to set .sent status, every message coming from firestore has .sent status (it was set at line 133). so as soon as this message gets to firestore, subscription will update messages array with this message with .sent status
            } catch {
                print("Error adding document: \(error)")
                lock.withLock {
                    if let index = messages.lastIndex(where: { $0.id == id }) {
                        messages[index].status = .error(draft)
                        print("alisaM error ", messages)
                    }
                }
            }
            
            /// update latest message in current conversation to be this one
            if let id = conversation?.id {
                try await Firestore.firestore()
                    .collection(Collection.conversations)
                    .document(id)
                    .updateData(["latestMessage" : dict])
            }
            
            /// update unread message counters for other participants
            bumpUnreadCounters()
        }
    }
    
    private func makeDraftMessageDictionary(_ draft: DraftMessage) async -> [String: Any] {
        guard let user = SessionManager.currentUser else { return [:] }
        var attachments = [[String: Any]]()
        for media in draft.medias {
            let thumbURL, fullURL : URL?
            switch media.type {
            case .image:
                thumbURL = await UploadingManager.uploadImageMedia(media)
                fullURL = thumbURL
            case .video:
                (thumbURL, fullURL) = await UploadingManager.uploadVideoMedia(media)
            }
            
            if let thumbURL, let fullURL {
                attachments.append([
                    "thumbURL": thumbURL.absoluteString,
                    "url": fullURL.absoluteString,
                    "type": AttachmentType(mediaType: media.type).rawValue
                ])
            }
        }
        
        var recordingDict: [String: Any]? = nil
        if let recording = draft.recording, let url = await UploadingManager.uploadRecording(recording) {
            recordingDict = [
                "duration": recording.duration,
                "waveformSamples": recording.waveformSamples,
                "url": url.absoluteString
            ]
        }
        
        var replyDict: [String: Any]? = nil
        if let reply = draft.replyMessage {
            var replyRecordingDict: [String: Any]? = nil
            if let recording = reply.recording {
                replyRecordingDict = [
                    "duration": recording.duration,
                    "waveformSamples": recording.waveformSamples,
                    "url": recording.url?.absoluteString ?? ""
                ]
            }
            
            replyDict = [
                "id": reply.id,
                "userId": reply.user.id,
                "text": reply.text,
                "attachments": reply.attachments.map { [
                    "url": $0.full.absoluteString,
                    "type": $0.type.rawValue
                ] },
                "recording": replyRecordingDict as Any
            ]
        }
        
        return [
            "userId": user.id,
            "createdAt": Timestamp(date: draft.createdAt),
            "isRead": Timestamp(date: draft.createdAt),
            "text": draft.text,
            "attachments": attachments,
            "recording": recordingDict as Any,
            "replyMessage": replyDict as Any
        ]
    }
    
    // MARK: - conversation life management
    
    func subscribeToConversationCreation(user: User) {
        subscribtionToConversationCreation = Firestore.firestore()
            .collection(Collection.conversations)
            .whereField("users", arrayContains: SessionManager.shared.deviceId)
            .addSnapshotListener() { [weak self] (snapshot, _) in
                // check if this convesation was created by another user already
                if let conversation = self?.conversationForUser(user) {
                    self?.updateForConversation(conversation)
                    self?.subscribtionToConversationCreation = nil
                }
            }
    }
    
    private func conversationForUser(_ user: User) -> Conversation? {
        // check in case the other user sent a message while this user had the empty conversation open
        for conversation in dataStorage.conversations {
            if !conversation.isGroup, conversation.users.contains(user) {
                return conversation
            }
        }
        return nil
    }
    
    private func createIndividualConversation(_ user: User) async -> Conversation? {
        subscribtionToConversationCreation = nil
        let allUserIds = allUsers.map { $0.id }
        let dict: [String : Any] = [
            "users": allUserIds,
            "usersUnreadCountInfo": Dictionary(uniqueKeysWithValues: allUserIds.map { ($0, 0) } ),
            "isGroup": false,
            "title": user.name
        ]
        
        return await withCheckedContinuation { continuation in
            var ref: DocumentReference? = nil
            ref = Firestore.firestore()
                .collection(Collection.conversations)
                .addDocument(data: dict) { err in
                    if let _ = err {
                        continuation.resume(returning: nil)
                    } else if let id = ref?.documentID {
                        continuation.resume(returning: Conversation(id: id, users: self.allUsers, isGroup: false))
                    }
                }
        }
    }
}

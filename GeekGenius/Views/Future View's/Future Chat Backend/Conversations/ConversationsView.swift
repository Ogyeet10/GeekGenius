//
//  ConversationsView.swift
//  ChatFirestoreExample
//
//  Created by Alisa Mylnikova on 03.07.2023.
//

import SwiftUI
import ActivityIndicatorView

struct ConversationsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var dataStorage = DataStorageManager.shared
    @StateObject var viewModel = ConversationsViewModel()

    @State var showUsersList = false
    @State var navPath = NavigationPath()
    
    // Alert related states
    @State private var alertIndex = 0 // Current index in the alert sequence
    @State private var showAlert = false // State to control alert presentation

    // Define your alerts here, similar to ChatIntroductionView
    let alerts: [ConversationsAlertItem] = [
        ConversationsAlertItem(title: "Welcome.", message: "This is the final stage of GeekGenius verification. This is the future Ive been hyping up for some time now btw. GeekGenius chat. I didn't have enough time to make a dedicated UI for the chat intro so I improvised it out of my already existing chat view. It should have looked alot better then this.", dismissButton: "OK"),
        ConversationsAlertItem(title: "Info.", message: "When you enter the chat you will be chatting with the GeekGenius server. If you succeed in verification you will be able to chat with me and soon others with a future update.", dismissButton: "Yep."),
        ConversationsAlertItem(title: "Warning.", message: "Everything aside from the chat with the GeekGenius server is locked for now, Just in case.", dismissButton: "I understand."),
        ConversationsAlertItem(title: "Go ahead.", message: "Click on the chat with the GeekGenius server. From their the chat will walk you through everything you need to know.", dismissButton: "Doing that now.")
    ]
    
    var body: some View {
        ZStack {
            content
            
            if viewModel.showActivityIndicator {
                ActivityIndicator()
            }
        }
        .task {
            await viewModel.getData() // Fetch data when the view first appears
            viewModel.subscribeToUpdates()
            
            if appState.shouldShowConversationsViewAlerts {
                showAlertSequence() // Start the alert sequence only if the condition is true
            }
        }
        .alert(isPresented: $showAlert) {
            // Configure the alert based on the current alert index
            let currentAlert = alerts[alertIndex]
            return Alert(
                title: Text(currentAlert.title),
                message: Text(currentAlert.message),
                dismissButton: .default(Text(currentAlert.dismissButton)) {
                    handleAlertDismissal()
                }
            )
        }
    }

    var content: some View {
        NavigationStack(path: $navPath) {
            SearchField(text: $viewModel.searchText)
                .padding(.horizontal, 12)
            
            List(viewModel.filteredConversations) { conversation in
                HStack {
                    if let url = conversation.pictureURL {
                        AvatarView(url: url, size: 56)
                    } else {
                        HStack(spacing: -30) {
                            ForEach(conversation.notMeUsers) { user in
                                AvatarView(url: user.avatarURL, size: 56)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conversation.displayTitle)
                            .font(17, .black, .medium)
                        
                        if let latest = conversation.latestMessage {
                            HStack(spacing: 0) {
                                if conversation.isGroup {
                                    Text("\(latest.senderName): ")
                                        .font(15, .exampleTetriaryText)
                                } else if latest.isMyMessage {
                                    Text("You: ")
                                        .font(15, .exampleTetriaryText)
                                }
                                
                                HStack(spacing: 4) {
                                    if let subtext = latest.subtext {
                                        Text(subtext)
                                            .font(15, .exampleBlue)
                                    }
                                    if let text = latest.text {
                                        Text(text)
                                            .lineLimit(1)
                                            .font(15, .exampleSecondaryText)
                                    }
                                    if let date = latest.createdAt?.timeAgoFormat() {
                                        Text("·")
                                            .font(13, .exampleTetriaryText)
                                        Text(date)
                                            .font(13, .exampleTetriaryText)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if let unreadCounter = conversation.usersUnreadCountInfo[SessionManager.currentUserId], unreadCounter != 0 {
                        Text("\(unreadCounter)")
                            .font(15, .white, .semibold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background {
                                Color.exampleBlue.cornerRadius(.infinity)
                            }
                    }
                }
                .background(
                    NavigationLink("", value: conversation)
                        .opacity(0)
                )
                .listRowSeparator(.hidden)
            }
            .refreshable {
                await viewModel.getData()
            }
            
            .listStyle(.plain)
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Conversation.self) { conversation in
                ConversationView(viewModel: ConversationViewModel(conversation: conversation))
            }
            .navigationDestination(for: User.self) { user in
                ConversationView(viewModel: ConversationViewModel(user: user))
            }
            /*.toolbar {
                ToolbarItem {
                    Button {
                        showUsersList = true
                    } label: {
                        Image(.newChat)
                            .foregroundColor(appState.needsSecondaryIntroduction ? .gray : .primary)
                    }
                    .disabled(appState.needsSecondaryIntroduction) // Disable the button
                }
            } */
        }
        .sheet(isPresented: $showUsersList) {
            UsersView(viewModel: UsersViewModel(), isPresented: $showUsersList, navPath: $navPath)
        }
    }
    // Alert handling functions
        private func showAlertSequence() {
            if alertIndex < alerts.count {
                showAlert = true // Trigger the alert
            } else {
                appState.shouldShowConversationsViewAlerts = false
            }
        }

        private func handleAlertDismissal() {
            alertIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showAlertSequence() // Call the sequence function again
            }
        }
}

struct ConversationsAlertItem: Identifiable {
    let id = UUID()
    var title: String
    var message: String
    var dismissButton: String
}



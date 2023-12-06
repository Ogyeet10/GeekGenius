//
//  ConversationView.swift
//  ChatFirestoreExample
//
//  Created by Alisa Mylnikova on 13.06.2023.
//

import SwiftUI
import ExyteChat
import Combine

struct ConversationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    //private var cancellables = Set<AnyCancellable>()
    @StateObject var viewModel: ConversationViewModel
    
    // Add a state variable to control the display of the alert
    @State private var showVerificationAlert = false
    
    var statusText: (text: String, color: Color, isBold: Bool) {
        if !viewModel.userOnlineStatus {
            return ("Offline", Color.gray, false) // Show Offline first if user is not online
        } else if viewModel.userTypingStatus {
            return ("Typing...", .blue, true) // Then check for Typing status
        } else {
            return ("Online", .green, false) // Default to Online if none of the above
        }
    }


    var body: some View {
        ChatView(messages: viewModel.messages) { draft in
            viewModel.sendMessage(draft)
        }
        .orientationHandler { mode in
            switch mode {
            case .lock: AppDelegate.lockOrientationToPortrait()
            case .unlock: AppDelegate.unlockOrientation()
            }
        }
        .messageUseMarkdown(messageUseMarkdown: true) // This line enables Markdown in message cells
        .mediaPickerTheme(
            main: .init(
                text: .white,
                albumSelectionBackground: .examplePickerBg,
                fullscreenPhotoBackground: .examplePickerBg
            ),
            selection: .init(
                emptyTint: .white,
                emptyBackground: .black.opacity(0.25),
                selectedTint: .exampleBlue,
                fullscreenTint: .white
            )
        )
        .onDisappear {
            viewModel.resetUnreadCounter()
        }
        // Add onChange modifier to listen to changes in appState.needsSecondaryIntroduction
        .onChange(of: appState.needsSecondaryIntroduction) { _ in
            showVerificationAlert = true
        }
        // Add alert modifier
        .alert(isPresented: $showVerificationAlert) {
            Alert(title: Text("Verification successful!"), message: Text("All features are now unlocked. Hope you enjoyed the experience, ;)"), dismissButton: .default(Text("OK")))
        }

        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(.navigateBack)
                }
            }
            ToolbarItem(placement: .navigation) {
                HStack {
                    if let conversation = viewModel.conversation, conversation.isGroup {
                        AvatarView(url: conversation.pictureURL, size: 44)
                        Text(conversation.title)
                    } else if let user = viewModel.users.first {
                        AvatarView(url: user.avatarURL, size: 38)
                        VStack(alignment: .leading) {
                            Text(user.name)
                            Text(statusText.text)
                                .font(.caption)
                                .foregroundColor(statusText.color) // Apply color based on status
                                .bold(statusText.isBold)
                                .animation(.easeInOut(duration: 0.3)) // Animate changes to the status text
                        }
                    }
                }
            }
        }
    }
}

struct TypingAnimationView: View {
    // Animating each dot separately
    @State private var animateDot1 = false
    @State private var animateDot2 = false
    @State private var animateDot3 = false

    let animationDuration = 0.6
    let delay = 0.2

    var body: some View {
        HStack(spacing: 0) {
            Text("Typing")
            Circle().frame(width: 6, height: 6).scaleEffect(animateDot1 ? 1 : 0.4).opacity(animateDot1 ? 1 : 0.4)
            Circle().frame(width: 6, height: 6).scaleEffect(animateDot2 ? 1 : 0.4).opacity(animateDot2 ? 1 : 0.4).padding(.horizontal, 3)
            Circle().frame(width: 6, height: 6).scaleEffect(animateDot3 ? 1 : 0.4).opacity(animateDot3 ? 1 : 0.4)
        }
        .onAppear {
            // Starting the animation for each dot with a delay
            withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                animateDot1 = true
            }
            withAnimation(Animation.easeInOut(duration: animationDuration).delay(delay).repeatForever(autoreverses: true)) {
                animateDot2 = true
            }
            withAnimation(Animation.easeInOut(duration: animationDuration).delay(delay * 2).repeatForever(autoreverses: true)) {
                animateDot3 = true
            }
        }
    }
}

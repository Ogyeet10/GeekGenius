//
//  ProfileView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseFirestore
import Firebase
import FirebaseStorage
import OneSignal

struct ProfileView: View {
    @State private var profileImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var displayName = ""
    @State private var aboutMe = ""
    @State private var isLoading = true
    @State private var user: User? = Auth.auth().currentUser
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        if let _ = user {
        NavigationView {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .center, spacing: 20) {
                        Button(action: {
                            self.showingImagePicker = true
                        }) {
                            if profileImage != nil {
                                Image(uiImage: profileImage!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .foregroundColor(.gray)
                            }
                        }
                        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                            ImagePicker(image: self.$inputImage)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Display Name")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                
                                TextField("Display Name", text: $displayName)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                            }
                            
                            
                            Text("About Me")
                                .font(.headline)
                            
                            PlaceholderTextEditor(placeholder: "Tell us something about yourself...", text: $aboutMe)
                                .frame(height: 100)
                                .padding(5) // Padding inside TextEditor
                                .background(Color.clear) // Clear background
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 1) // Your custom border
                                )
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            saveProfileData()
                        }) {
                            ZStack {
                                Color.blue
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(10)
                                
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                                        .scaleEffect(1.5, anchor: .center)
                                } else {
                                    Text("Save Changes")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(height: 50)
                        .padding()
                        .cornerRadius(10)
                        .disabled(isSaving)
                    }
                    .padding(.top)
                }
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .onTapGesture {
                dismissKeyboard()
            }
            .onAppear(perform: fetchProfileData)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Profile Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        } else {
                   NoLoginView()
               }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = inputImage
    }
    
    
    func saveProfileData() {
        guard let user = Auth.auth().currentUser else {
            print("No user found")
            return
        }
        isSaving = true  // Start saving
        // Update Firebase Authentication profile
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        changeRequest.commitChanges { (error) in
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully")
                
                // Set external user ID in OneSignal
                OneSignal.setExternalUserId(self.displayName)
                
                // Now update Firestore
                let db = Firestore.firestore()
                let profileRef = db.collection("users").document(user.uid)
                
                if let image = profileImage {
                    uploadImage(image) { imageURL in
                        profileRef.setData([
                            "displayName": self.displayName,
                            "aboutMe": self.aboutMe,
                            "profileImageURL": imageURL
                        ]) { error in
                            isSaving = false  // Stop saving
                            if let error = error {
                                print("Error saving profile data: \(error.localizedDescription)")
                            } else {
                                alertMessage = "Profile data saved successfully"
                                print("Profile data saved successfully")
                            }
                            showAlert = true
                        }
                    }
                } else {
                    profileRef.setData([
                        "displayName": displayName,
                        "aboutMe": aboutMe,
                        // Add any additional fields here
                    ]) { error in
                        isSaving = false  // Stop saving
                        if let error = error {
                            print("Error saving profile data: \(error.localizedDescription)")
                        } else {
                            print("Profile data saved successfully")
                        }
                    }
                }
            }
        }
    }

    
    func uploadImage(_ image: UIImage, completion: @escaping (String) -> Void) {
        guard let user = Auth.auth().currentUser, let imageData = image.jpegData(compressionQuality: 0.75) else { return }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profileImages/\(user.uid).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        profileImageRef.putData(imageData, metadata: metadata) { (_, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
            } else {
                profileImageRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                    } else if let url = url {
                        completion(url.absoluteString)
                    }
                }
            }
        }
    }
    func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    func fetchProfileData() {
        guard let user = Auth.auth().currentUser else {
            print("No user found")
            return
        }
        
        let db = Firestore.firestore()
        let profileRef = db.collection("users").document(user.uid)
        
        profileRef.getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching profile data: \(error.localizedDescription)")
            } else if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
                let data = documentSnapshot.data()
                displayName = data?["displayName"] as? String ?? ""
                aboutMe = data?["aboutMe"] as? String ?? ""
                
                if let imageURL = data?["profileImageURL"] as? String {
                    if let cachedImage = URLImageCache.shared.cache.object(forKey: NSURL(string: imageURL)!) {
                        profileImage = cachedImage
                        isLoading = false
                    } else {
                        downloadProfileImage(url: imageURL) { image in
                            if let image = image {
                                profileImage = image
                                URLImageCache.shared.cache.setObject(image, forKey: NSURL(string: imageURL)!)
                            }
                            isLoading = false
                        }
                    }
                } else {
                    isLoading = false
                }
            } else {
                isLoading = false
            }
        }
    }

    func downloadProfileImage(url: String, completion: @escaping (UIImage?) -> Void) {
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

    struct NoLoginView: View {
        @EnvironmentObject var appState: AppState
        var body: some View {
        VStack {
            Text("Please Sign in to view/create your profile")
            Button(action: {
                self.appState.isGuest = false
            }) {
                Text("Sign In")
                    .foregroundColor(.blue)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
           
        }
        .navigationBarTitle("Profile", displayMode: .inline)
    }
}

struct PlaceholderTextEditor: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .opacity(text.isEmpty ? 1.0 : 1.0) // Hide if empty
            
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(UIColor.placeholderText))
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)  // Allow touches to pass through
            }
        }
    }
}



struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

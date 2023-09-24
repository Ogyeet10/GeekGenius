//
//  ChangePasswordView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/19/23.
//

import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmNewPassword)
                    
                    Button("Update Password") {
                        validateAndUpdatePassword()
                    }
                }
            }
            .navigationBarTitle("Change Password")
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func validateAndUpdatePassword() {
        // You can add more validation rules here
        guard newPassword == confirmNewPassword else {
            errorAlertMessage = "New password and confirm password don't match."
            showErrorAlert = true
            return
        }
        
        reauthenticateUser()
    }
    
    private func reauthenticateUser() {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                errorAlertMessage = "Failed to authenticate: \(error.localizedDescription)"
                showErrorAlert = true
            } else {
                updatePassword()
            }
        }
    }
    
    private func updatePassword() {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                errorAlertMessage = error.localizedDescription
                showErrorAlert = true
            } else {
                dismiss()
            }
        }
    }
}



struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePasswordView()
    }
}

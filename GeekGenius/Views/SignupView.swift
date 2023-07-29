//
//  SignupView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseAuth
import OneSignal

struct SignupView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) private var presentationMode
    @State private var isSignedIn = false
    @State private var isLoading = false
    var passwordIsValidLength: Bool { password.count >= 8 }
    var passwordHasLowercase: Bool { password.rangeOfCharacter(from: .lowercaseLetters) != nil }
    var passwordHasUppercase: Bool { password.rangeOfCharacter(from: .uppercaseLetters) != nil }
    var passwordHasNumber: Bool { password.rangeOfCharacter(from: .decimalDigits) != nil }

    var body: some View {
        VStack {
            Text("Create Account")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 50)

            VStack(alignment: .leading) {
                Text("Name")
                    .font(.headline)
                TextField("Name", text: $name)
                    .frame(height: 40)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                Text("Email")
                    .font(.headline)
                    .padding(.top)
                TextField("Email", text: $email)
                    .frame(height: 40)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                Text("Password")
                    .font(.headline)
                    .padding(.top)
                SecureField("Password", text: $password)
                    .frame(height: 40)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .textContentType(.oneTimeCode) // Add this line
                
                Text("Confirm Password")
                    .font(.headline)
                    .padding(.top)
                SecureField("Confirm Password", text: $confirmPassword)
                    .frame(height: 40)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .textContentType(.oneTimeCode) // Add this line
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
                
                VStack(alignment: .leading) {
                    Text("Password must:")
                        .font(.subheadline)
                    HStack {
                        Image(systemName: passwordIsValidLength ? "checkmark.square" : "square")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(passwordIsValidLength ? .green : .red)
                            .scaleEffect(passwordIsValidLength ? 1.0 : 0.7)
                            .opacity(passwordIsValidLength ? 1.0 : 0.4)
                            .animation(.easeInOut, value: passwordIsValidLength)
                        Text("Be at least 8 characters")
                            .font(.subheadline)
                    }
                    HStack {
                        Image(systemName: passwordHasLowercase ? "checkmark.square" : "square")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(passwordHasLowercase ? .green : .red)
                            .scaleEffect(passwordHasLowercase ? 1.0 : 0.7)
                            .opacity(passwordHasLowercase ? 1.0 : 0.4)
                            .animation(.easeInOut, value: passwordHasLowercase)
                        
                        
                        Text("Contain a lowercase letter")
                            .font(.subheadline)
                    }
                    HStack {
                        Image(systemName: passwordHasUppercase ? "checkmark.square" : "square")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(passwordHasUppercase ? .green : .red)
                            .scaleEffect(passwordHasUppercase ? 1.0 : 0.7)
                            .opacity(passwordHasUppercase ? 1.0 : 0.4)
                            .animation(.easeInOut, value: passwordHasUppercase)
                        
                        Text("Contain an uppercase letter")
                            .font(.subheadline)
                    }
                    HStack {
                        Image(systemName: passwordHasNumber ? "checkmark.square" : "square")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(passwordHasNumber ? .green : .red)
                            .scaleEffect(passwordHasNumber ? 1.0 : 0.7)
                            .opacity(passwordHasNumber ? 1.0 : 0.4)
                            .animation(.easeInOut, value: passwordHasNumber)
                        Text("Contain a number")
                            .font(.subheadline)
                    }
                }
                .padding(.top)
                Button(action: {
                    isLoading = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    
                    if let validationError = validateInput(name: name, email: email, password: password, confirmPassword: confirmPassword) {
                        withAnimation {
                            errorMessage = validationError
                        }
                        generator.notificationOccurred(.error)
                        isLoading = false
                    } else {
                        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                            isLoading = false
                            if let error = error {
                                withAnimation {
                                    errorMessage = error.localizedDescription
                                }
                                generator.notificationOccurred(.error)
                            } else {
                                // Adding a step here to update the user's profile with 'name'
                                if let changeRequest = authResult?.user.createProfileChangeRequest() {
                                    changeRequest.displayName = name
                                    changeRequest.commitChanges { (error) in
                                        if let error = error {
                                            // Handle error
                                            print("Error: \(error)")
                                        } else {
                                            print("Name successfully set in user's profile")
                                            OneSignal.setExternalUserId(name)
                                        }
                                    }
                                }
                                
                                print("Sign up successful")
                                isSignedIn = true
                                presentationMode.wrappedValue.dismiss()
                                generator.notificationOccurred(.success)
                            }
                        }
                    }
                })
                {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                        } else {
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                .padding(.top)
                
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }

    func validateInput(name: String, email: String, password: String, confirmPassword: String) -> String? {
        if name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            return "Please fill in all fields."
        }

        if !email.isValidEmailAddress() {
            return "Please enter a valid email address."
        }

        if !passwordIsValidLength || !passwordHasLowercase || !passwordHasUppercase || !passwordHasNumber {
            return "Password does not meet requirements."
        }

        if password != confirmPassword {
            return "Passwords do not match."
        }

        return nil
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}

extension String {
    func isValidEmailAddress() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

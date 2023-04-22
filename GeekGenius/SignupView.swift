//
//  SignupView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseAuth

struct SignupView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) private var presentationMode
    @State private var isSignedIn = false

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
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                Text("Email")
                    .font(.headline)
                    .padding(.top)
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                Text("Password")
                    .font(.headline)
                    .padding(.top)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                Text("Confirm Password")
                    .font(.headline)
                    .padding(.top)
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.bottom)
                }

                Button(action: {
                        if let validationError = validateInput(name: name, email: email, password: password, confirmPassword: confirmPassword) {
                            errorMessage = validationError
                        } else {
                            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                                if let error = error {
                                    errorMessage = error.localizedDescription
                                } else {
                                    print("Sign up successful")
                                    isSignedIn = true
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }

                        }
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
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
        
        if password.count < 6 {
            return "Password must be at least 6 characters long."
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

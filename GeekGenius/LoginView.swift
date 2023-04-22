//
//  LoginView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) private var presentationMode
    @Binding var isSignedIn: Bool

    
    var body: some View {
        NavigationView {
            VStack {
                Text("GeekGenius")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 50)
                
                VStack(alignment: .leading) {
                    Text("Email")
                        .font(.headline)
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
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.bottom, 10)
                    }

                    Button(action: {
                        if let error = validateInput(email: email, password: password) {
                            errorMessage = error
                        } else {
                            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                                if let error = error {
                                    print("Error signing in: \(error.localizedDescription)")
                                } else {
                                    print("Sign in successful")
                                    // Navigate to the home screen or another appropriate view
                                }
                            }
                        }
                    }) {
                        Text("Login")
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
                
                HStack {
                    Spacer()
                    NavigationLink(destination: SignupView()) {
                        Text("Don't have an account? Sign up")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
    }
    
    func validateInput(email: String, password: String) -> String? {
        if email.isEmpty || password.isEmpty {
            return "Please enter both email and password."
        }
        
        if !email.isValidEmail() {
            return "Please enter a valid email address."
        }
        
        if password.count < 6 {
            return "Password must be at least 6 characters long."
        }
        
        return nil
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isSignedIn: .constant(false))
    }
}

extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

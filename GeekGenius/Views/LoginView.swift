//
//  LoginView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import CommonCrypto

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var appState: AppState
    @Binding var isSignedIn: Bool
    @State private var currentNonce: String?
    @State private var showingWhyWeNeedYourInfo = false
    @State private var isLoading = false
    @State private var showingGuestSignInAlert = false

    var body: some View {
        NavigationView {
            VStack {
                // Logo and Title
                HStack {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Squircle(cornerRadius: 15)) // Adjust this value to match your preference
                    
                    Text("GeekGenius")
                        .font(.largeTitle)
                        .bold()
                }
                .padding(.bottom, 50)
                /*AppleSignInButton(currentNonce: $currentNonce)
                    .frame(width: 280, height: 60)
                    .onTapGesture {
                    self.startSignInWithAppleFlow()
                    }*/
                VStack(alignment: .leading) {
                    Text("Email")
                        .font(.headline)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress) // Use email keyboard
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                    
                    Text("Password")
                        .font(.headline)
                        .padding(.top)
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    Button(action: {
                        sendPasswordResetEmail()
                    }) {
                        Text("Forgot Password?")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.bottom, 10)
                    }
                    
                    Button(action: {
                        isLoading = true
                        
                        if let error = validateInput(email: email, password: password) {
                            errorMessage = error
                            isLoading = false
                        } else {
                            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                                isLoading = false
                                if let error = error {
                                    print("Error signing in: \(error.localizedDescription)")
                                    self.errorMessage = "Error signing in: \(error.localizedDescription)"
                                } else {
                                    print("Sign in successful")
                                    isSignedIn = true // Update the binding
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()  // show loading indicator if it's loading
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                                    .imageScale(.small)
                                Text("Login")
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
                    
                    if let appleSignInError = appState.appleSignInError {
                        Text("Error signing in with Apple: \(appleSignInError.localizedDescription)")
                            .foregroundColor(.red)
                            .padding(.bottom, 10)
                    }
                    
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
                /*VStack {
                    Button(action: {
                        showingWhyWeNeedYourInfo = true
                    }) {
                        Text("Why We Need Your Info")
                    }
                    .sheet(isPresented: $showingWhyWeNeedYourInfo) {
                        InfoExplanationView()
                    }
                }
                .padding(.top)*/
                
                
                Button(action: {
                    showingGuestSignInAlert = true // Trigger the alert
                }) {
                    ZStack(alignment: .center) {
                        HStack {
                            Image(systemName: "person.slash.fill")
                                .font(.system(size: 14))

                            Text("Continue as Guest")
                                .font(.footnote)
                                .fontWeight(.light)
                            }
                        }
                    .frame(maxWidth: .infinity)
                    
                }
                .alert(isPresented: $showingGuestSignInAlert) {
                    Alert(
                        title: Text("Sign in as Guest"),
                        message: Text("If you continue as a guest, you won't be able to comment or like. Are you sure you want to proceed?"),
                        primaryButton: .default(Text("Continue as Guest")) {
                            appState.signInAsGuest()
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
        
    }
    
    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        let coordinator = AppleSignInButton(currentNonce: $currentNonce).makeCoordinator()
        coordinator.currentNonce = nonce
        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        authorizationController.performRequests()
        
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
    
    func sendPasswordResetEmail() {
            if email.isEmpty {
                errorMessage = "Please enter your email"
                return
            }

            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    errorMessage = "Error sending reset email: \(error.localizedDescription)"
                } else {
                    errorMessage = "You should receive an email shorty to reset your password."
            }
        }
    }
}

struct Squircle: Shape {
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: cornerRadius, height: rect.size.height / 2))
        return Path(path.cgPath)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isSignedIn: .constant(false))
            .environmentObject(AppState())
    }
}

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
        fatalError(
            "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
    }
    
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    
    let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
    }
    
    return String(nonce)
}

    

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    inputData.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(inputData.count), &hash)
    }
    let hashString = hash.map { String(format: "%02x", $0) }.joined()
    return hashString
}

struct AppleSignInButton: UIViewRepresentable {
    @Binding var currentNonce: String?

    // add a Coordinator
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        var currentNonce: String?

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return UIApplication.shared.windows.first { $0.isKeyWindow }!
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            // Handle error.
            print(error.localizedDescription)
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            print("Attempting Authorization")
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                // Initialize a Firebase credential.
                let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                               rawNonce: nonce,
                                                               fullName: appleIDCredential.fullName)
                // Sign in with Firebase.
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    // User is signed in to Firebase with Apple.
                    // ...
                    print("Singed on")
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        return ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
}

extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

struct InfoExplanationView: View {
    var body: some View {
        VStack {
            Text("Why We Need Your Info")
                .font(.headline)
                .padding(.bottom)

            Text("""
                        Our app requires user registration for providing its services. The information you provide is essential for the functionality and the personalized experience we offer in our app. The backend of our app relies on this information to function properly.

                        We assure you that your data is kept secure and is used strictly for the purpose of improving your experience and providing you with personalized content.
                        """)
                            .padding()

            Spacer()
        }
    }
}

    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print(error.localizedDescription)
    }

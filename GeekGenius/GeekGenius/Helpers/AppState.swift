import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import CommonCrypto

class AppState: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    @Published var isLoggedIn: Bool
    @Published var currentNonce: String?
    @Published var appleSignInError: Error?
    @Published var isGuest: Bool  // add this variable
    @Published var showTips: Bool = false
    @Published var showThanks: Bool = false
    

    override init() {
        isLoggedIn = Auth.auth().currentUser != nil
        isGuest = false  // initialize it to false
    }

    func signIn() {
        isLoggedIn = true
    }
    
    func signInAsGuest() {  // add this function
            isGuest = true
        }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let idToken = String(data: identityTokenData, encoding: .utf8),
              let rawNonce = currentNonce
        else {
            // Handle error.
            appleSignInError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid credentials"])
            return
        }
        
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idToken, rawNonce: rawNonce)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                // Handle error.
                print(error.localizedDescription)
                self.appleSignInError = error
                return
            }
            // User is signed in to Firebase with Apple.
            // ...
            self.signIn()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print(error.localizedDescription)
        self.appleSignInError = error
    }
}


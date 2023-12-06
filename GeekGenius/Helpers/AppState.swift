import SwiftUI
import Firebase
import AuthenticationServices
import CryptoKit
import CommonCrypto
import KeychainSwift

class AppState: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    @Published var isLoggedIn: Bool
    @Published var currentNonce: String?
    @Published var appleSignInError: Error?
    @Published var isGuest: Bool  // add this variable
    @Published var showTips: Bool = false
    @Published var showThanks: Bool = false
    @Published var navigateToFutureChatView: Bool = false
    @Published var appInstallUUID: String?
    @Published var isChatEnabled: Bool = false  // Default value
    @Published var isDelisha: Bool {
        didSet {
            // Save to UserDefaults whenever isDelisha changes
            UserDefaults.standard.set(isDelisha, forKey: "isDelisha")
        }
    }
    @Published var isAidan: Bool {
            didSet {
                // Save to UserDefaults whenever isAidan changes
                UserDefaults.standard.set(isAidan, forKey: "isAidan")
            }
        }
    @Published var videoLimit: Int {
        didSet {
            // Save to UserDefaults whenever videoLimit changes
            UserDefaults.standard.set(videoLimit, forKey: "videoLimit")
        }
    }
    @Published var needsIntroduction: Bool {
        didSet {
            // Save to UserDefaults
            UserDefaults.standard.set(needsIntroduction, forKey: "needsIntroduction")
            
            // Update Firestore
            updateFirestoreField(forUser: "Delisha", field: "needsIntroduction", value: needsIntroduction)
        }
    }
    
    @Published var needsSecondaryIntroduction: Bool {
        didSet {
            // Save to UserDefaults
            UserDefaults.standard.set(needsSecondaryIntroduction, forKey: "needsSecondaryIntroduction")
            
            // Update Firestore
            updateFirestoreField(forUser: "Delisha", field: "needsSecondaryIntroduction", value: needsSecondaryIntroduction)
        }
    }
    @Published var shouldShowConversationsViewAlerts: Bool {
        didSet {
            // Save to UserDefaults whenever shouldShowConversationsViewAlerts changes
            UserDefaults.standard.set(shouldShowConversationsViewAlerts, forKey: "shouldShowConversationsViewAlerts")
        }
    }
    @Published var apnDeviceToken: String? {
        didSet {
            // Save to UserDefaults whenever shouldShowConversationsViewAlerts changes
            UserDefaults.standard.set(shouldShowConversationsViewAlerts, forKey: "apnDeviceToken")
        }
    }
    @Published var hasChatIntroductionViewOpened: Bool {
        didSet {
            // Save to Keychain
            keychain.set(hasChatIntroductionViewOpened, forKey: "hasChatIntroductionViewOpened")
            
            // Save to iCloud
            NSUbiquitousKeyValueStore.default.set(hasChatIntroductionViewOpened, forKey: "hasChatIntroductionViewOpened")
        }
    }



    private let keychain = KeychainSwift()

    // Add Firebase Firestore reference
    private let firestore = Firestore.firestore()
    private var needsIntroductionListener: ListenerRegistration?
    private var needsSecondaryIntroductionListener: ListenerRegistration?
    private var uuidListener: ListenerRegistration?
    private var chatEnabledListener: ListenerRegistration?

    
    override init() {
        isLoggedIn = Auth.auth().currentUser != nil
        isGuest = false  // initialize it to false

        // Retrieve videoLimit from UserDefaults
        if let savedVideoLimit = UserDefaults.standard.value(forKey: "videoLimit") as? Int {
            videoLimit = savedVideoLimit
        } else {
            videoLimit = 5  // Default value
        }

        // Retrieve isDelisha from UserDefaults
        if let savedIsDelisha = UserDefaults.standard.value(forKey: "isDelisha") as? Bool {
            isDelisha = savedIsDelisha
            print("Restoring savedIsDelisha", savedIsDelisha)
        } else {
            isDelisha = false  // Default value
            print("Restoring savedIsDelisha false")
        }

        // Retrieve isAidan from UserDefaults
        if let savedIsAidan = UserDefaults.standard.value(forKey: "isAidan") as? Bool {
            isAidan = savedIsAidan
        } else {
            isAidan = false  // Default value
        }
        
        // Retrieve isAidan from UserDefaults
        if let savedApnDeviceToken = UserDefaults.standard.value(forKey: "apnDeviceToken") as? String {
            apnDeviceToken = savedApnDeviceToken
        } else {
            apnDeviceToken = "N/A"  // Default value
        }
        
        if let keychainValue = keychain.getBool("hasChatIntroductionViewOpened") {
            hasChatIntroductionViewOpened = keychainValue
            print("keychainValue", keychainValue)
        } else if let icloudValue = NSUbiquitousKeyValueStore.default.object(forKey: "hasChatIntroductionViewOpened") as? Bool {
            hasChatIntroductionViewOpened = icloudValue
            print("iCloud Value", icloudValue)
        } else {
            hasChatIntroductionViewOpened = false  // Default value
            print("Device has no save value for 'hasChatIntroductionViewOpened' defaulting to false.")
        }

        
        if let savedShouldShowConversationsViewAlerts = UserDefaults.standard.value(forKey: "shouldShowConversationsViewAlerts") as? Bool {
            shouldShowConversationsViewAlerts = savedShouldShowConversationsViewAlerts
        } else {
            shouldShowConversationsViewAlerts = true  // Default value
        }
        
        // Retrieve needsSecondaryIntroduction from UserDefaults
        if let savedNeedsSecondaryIntroduction = UserDefaults.standard.value(forKey: "needsSecondaryIntroduction") as? Bool {
            needsSecondaryIntroduction = savedNeedsSecondaryIntroduction
        } else {
            needsSecondaryIntroduction = false  // Default value
        }

        
        if let savedNeedsIntroduction = UserDefaults.standard.value(forKey: "needsIntroduction") as? Bool {
            needsIntroduction = savedNeedsIntroduction
        } else {
            needsIntroduction = false  // Default value
        }
        
        if let storedUUID = keychain.get("appInstallUUID") {
            appInstallUUID = storedUUID
            print(storedUUID, "Keychain UUID")
        } else if let icloudUUID = NSUbiquitousKeyValueStore.default.string(forKey: "appInstallUUID") {
            appInstallUUID = icloudUUID
            print(icloudUUID,"iCloud UUID")
            keychain.set(icloudUUID, forKey: "appInstallUUID")
        } else {
            let newUUID = UUID().uuidString
            keychain.set(newUUID, forKey: "appInstallUUID")
            NSUbiquitousKeyValueStore.default.set(newUUID, forKey: "appInstallUUID")
            appInstallUUID = newUUID
            print("Generated a new UUID")
        }
        
        super.init()
        setupFirestoreListeners()  // Sets up listeners for introduction fields
        setupUUIDListeners()      // Sets up listeners for UUID changes
        setupChatEnabledListener() // Sets up listener for chat enabled status
        determineNavigateToFutureChatView() // Determines if its appropriate to navigate To FutureChatView
    }

    // Helper function to update a field in Firestore
    private func updateFirestoreField(forUser user: String, field: String, value: Any) {
        firestore.collection("users").document(user).updateData([field: value]) { error in
            if let error = error {
                print("Error updating \(field) for \(user): \(error)")
            } else {
                print("Successfully updated \(field) for \(user)")
            }
        }
    }

    // Firestore Listener Functions
    private func setupUUIDListeners() {
        uuidListener = firestore.collection("users").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }

            var matched = false  // Flag to indicate if a match is found

            for document in documents {
                let userUUID = document.get("appInstallUUID") as? String
                let userID = document.documentID

                if let userUUID = userUUID, userUUID == self.appInstallUUID {
                    DispatchQueue.main.async {
                        self.isDelisha = (userID == "Delisha")
                        self.isAidan = (userID == "Aidan")
                    }
                    matched = true
                    break  // Break the loop once a match is found
                }
            }

            if !matched {
                DispatchQueue.main.async {
                    // Reset isDelisha and isAidan if no match is found
                    self.isDelisha = false
                    self.isAidan = false
                }
            }
        }
    }

    private func setupChatEnabledListener() {
        chatEnabledListener = firestore.collection("variables").document("chat").addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                self.isChatEnabled = true // Set a default or handle the error appropriately
                return
            }
            
            let chatEnabled = document.get("enabled") as? Bool ?? true
            self.isChatEnabled = chatEnabled
            
            if !self.isChatEnabled {
                self.isAidan = false
                self.isDelisha = false
            }
        }
    }
    
    func signIn() {
        isLoggedIn = true
    }
    
    func signInAsGuest() {  // add this function
        isGuest = true
    }
    
    private func determineNavigateToFutureChatView() {
        checkFutureChatViewSetting { [weak self] isEnabled in
            guard let self = self else { return }
            
            if !isEnabled {
                self.navigateToFutureChatView = false
                print("FutureChatView is disabled. Setting navigateToFutureChatView to false.")
                return
            }
            print("Determining navigateToFutureChatView status...")
            if hasChatIntroductionViewOpened {
                navigateToFutureChatView = false
                print("navigateToFutureChatView is true. Setting navigateToFutureChatView to false.")
            } else {
                // First, check if the user is either Delisha or Aidan
                if isDelisha || isAidan {
                    print("User is either Delisha or Aidan. Setting navigateToFutureChatView to false.")
                    navigateToFutureChatView = false
                } else {
                    // Then check for the device model
                    navigateToFutureChatView = isDeviceXROrNewer()
                    print("Device is \(navigateToFutureChatView ? "" : "not ")an iPhone XR or newer. navigateToFutureChatView set to \(navigateToFutureChatView).")
                }
            }
        }
    }
    
    private func checkFutureChatViewSetting(completion: @escaping (Bool) -> Void) {
        firestore.collection("variables").document("disableFutureChatView").getDocument { document, error in
            if let document = document, document.exists, let isEnabled = document.get("isEnabled") as? Bool {
                completion(isEnabled)
            } else {
                print("Error fetching document or document does not exist: \(error?.localizedDescription ?? "Unknown error")")
                completion(true) // Default to true if there's an error or the document does not exist
            }
        }
    }
    
    private func isDeviceXROrNewer() -> Bool {
        let modelName = UIDevice.current.modelName
        print("Device model name: \(modelName)")
        
        let deviceComponents = modelName.split(separator: ",")
        
        guard let deviceModel = deviceComponents.first,
              let modelNumberString = deviceModel.split(separator: "e").last,
              let modelNumber = Int(modelNumberString) else {
            print("Failed to parse device model number. Setting navigateToFutureChatView to false.")
            return false
        }
        
        print("Extracted device model number: \(modelNumber)")
        return modelNumber >= 11
    }

    
    private func setupFirestoreListeners() {
        // Listener for needsIntroduction
        needsIntroductionListener = firestore.collection("users").document("Delisha").addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }

            if let needsIntro = document.get("needsIntroduction") as? Bool {
                self.needsIntroduction = needsIntro
            }
        }

        // Listener for needsSecondaryIntroduction
        needsSecondaryIntroductionListener = firestore.collection("users").document("Delisha").addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }

            if let needsSecIntro = document.get("needsSecondaryIntroduction") as? Bool {
                self.needsSecondaryIntroduction = needsSecIntro
            }
        }
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


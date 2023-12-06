//
//  AppDelegate.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import UIKit
import Firebase
import BackgroundTasks
import FirebaseFirestore
import UserNotifications
import SwiftUI
import FirebaseMessaging
import OneSignal
import FirebaseAnalytics

let userSettings = UserSettings()
let gcmMessageIDKey = "gcm.message_id" // Define gcmMessageIDKey here

class AppDelegate: UIResponder, UIApplicationDelegate {
    var appState: AppState!
    
    static var orientationLock = UIInterfaceOrientationMask.all

        static func lockOrientationToPortrait() {
            orientationLock = .portrait
            if #available(iOS 16, *) {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                }
                UIViewController.attemptRotationToDeviceOrientation()
            } else {
                UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
            }
        }

        static func unlockOrientation() {
            orientationLock = .all
            UIViewController.attemptRotationToDeviceOrientation()
        }

        func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            return AppDelegate.orientationLock
        }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            Messaging.messaging().delegate = self

            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Error requesting notification authorization: \(error.localizedDescription)")
                }
            }
        
        OneSignal.initWithLaunchOptions(launchOptions)
        OneSignal.setAppId("39260954-ba17-4a8d-9ec4-9e781b96d232")
        
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notification: \(accepted)")
        })
            application.registerForRemoteNotifications()
        if let user = Auth.auth().currentUser {
            Analytics.setUserID(user.displayName)  // using displayName as an example, but remember the privacy implications
        }
        if let user = Auth.auth().currentUser {
            if let email = user.email {
                print("Setting email in onesignal")
                OneSignal.setEmail(email)
            } else {
                print("User is not loged on")
            }
            if let username = user.displayName {
                    OneSignal.setExternalUserId(username)
                }
        }
        FirebaseConfiguration.shared.setLoggerLevel(.min)
            return true
        }
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.oggroup.GeekGenius.fetchNewVideos", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    // Handle incoming Universal Links
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let _ = userActivity.webpageURL else {
            return
        }
        appState.navigateToFutureChatView = true
        print("Handled by NSUserActivity")
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let userActivity = connectionOptions.userActivities.first,
              userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let _ = userActivity.webpageURL else {
            return
        }
        appState.navigateToFutureChatView = true
        print("Handled by UISceneSession")
    }

    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.oggroup.GeekGenius.fetchNewVideos")
        
        // Use the user-selected frequency for the app refresh rate
        let selectedTimeInterval = TimeInterval(userSettings.selectedFrequency.rawValue)
        request.earliestBeginDate = Date(timeIntervalSinceNow: selectedTimeInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }


    func rescheduleAppRefresh() {
        scheduleAppRefresh()
    }

    

    
    func handleAppRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        fetchNewVideos { newVideos in
            if newVideos {
                self.scheduleNotification()
            }
            task.setTaskCompleted(success: true)
        }
        
        scheduleAppRefresh()
    }
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        fetchNewVideos { newVideos in
            if newVideos {
                self.scheduleNotification()
                completionHandler(.newData)
            } else {
                completionHandler(.noData)
            }
        }
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
      -> UIBackgroundFetchResult {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      // Print message ID.
      if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
      }

      // Print full message.
      print(userInfo)

          print("hehe")

          
      return UIBackgroundFetchResult.newData
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Set the APNs token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken

        // Convert the APNs token to a string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        // Print the APNs device token
        print("APNs Device Token: \(token)")
        // Upload the token to Firestore
        uploadDeviceTokenToFirestore(token: token)
    }
    
    func uploadDeviceTokenToFirestore(token: String) {
        let db = Firestore.firestore()

        // Determine the user document based on appState
        let userDocument: String?
        if appState.isDelisha {
            userDocument = "Delisha"
        } else if appState.isAidan {
            userDocument = "Aidan"
        } else {
            userDocument = nil
            print("No user is currently active, token not uploaded")
        }

        // Update the appState's apnDeviceToken regardless of userDocument's state
        appState.apnDeviceToken = token
        
        // Only proceed if a user document is set
        if let userDocument = userDocument {
            let deviceTokensDocumentRef = db.collection("users").document(userDocument).collection("deviceTokens")

            // Add token to the dictionary
            deviceTokensDocumentRef.document("apnDeviceToken").setData(["tokens": FieldValue.arrayUnion([token])], merge: true) { error in
                if let error = error {
                    print("Error updating token: \(error.localizedDescription)")
                } else {
                    print("Token successfully updated for user \(userDocument)")
                }
            }
        }
    }

     
    
    func fetchNewVideos(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        // You can store the last fetch timestamp in UserDefaults to track when the last video was fetched
        let lastFetchTimestamp = UserDefaults.standard.double(forKey: "lastFetchTimestamp")
        
        db.collection("videos").whereField("timestamp", isGreaterThan: lastFetchTimestamp).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching new videos: \(error.localizedDescription)")
                completion(false)
            } else {
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    completion(false)
                    return
                }
                
                // Update the last fetch timestamp
                let latestTimestamp = documents.compactMap { document in
                    document.get("timestamp") as? TimeInterval
                }.max() ?? lastFetchTimestamp
                
                UserDefaults.standard.set(latestTimestamp, forKey: "lastFetchTimestamp")
                completion(true)
            }
        }
    }
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "New Video Available"
        content.body = "A new tech video has been added. Check it out!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

func rescheduleAppRefresh() {
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
        appDelegate.rescheduleAppRefresh()
    } else {
        print("Failed to reschedule app refresh")
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
  // Receive displayed notifications for iOS 10 devices.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
    let userInfo = notification.request.content.userInfo

    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // Messaging.messaging().appDidReceiveMessage(userInfo)

    // ...

    // Print full message.
    print(userInfo)
        print("hehe")

    // Change this to your preferred presentation option
    return [[.alert, .sound]]
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse) async {
    let userInfo = response.notification.request.content.userInfo

    // ...

    // With swizzling disabled you must let Messaging know about the message, for Analytics
     Messaging.messaging().appDidReceiveMessage(userInfo)

    // Print full message.
    print(userInfo)
      print("hehe")
  }
}

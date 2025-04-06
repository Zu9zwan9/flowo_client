import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase using our helper method
    if initializeFirebase() {
      // Set up Firebase Messaging
      Messaging.messaging().delegate = self

      // Set up notification center delegate
      UNUserNotificationCenter.current().delegate = self

      // Request permission for notifications
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )

      // Register for remote notifications
      application.registerForRemoteNotifications()
    } else {
      // Firebase initialization failed, but we can still set up the notification center delegate
      // so that local notifications will work
      UNUserNotificationCenter.current().delegate = self
      print("Firebase initialization failed, continuing without Firebase features")
    }

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Flag to track if Firebase is initialized
  private var isFirebaseInitialized: Bool = false

  // Initialize Firebase safely and return whether initialization was successful
  private func initializeFirebase() -> Bool {
    // If we've already checked, return the cached result
    if isFirebaseInitialized {
      return true
    }

    // Check if the GoogleService-Info.plist file exists
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      do {
        // If Firebase is already configured, this is a no-op
        if FirebaseApp.app() == nil {
          FirebaseApp.configure()
        }
        isFirebaseInitialized = true
        return true
      } catch {
        print("Error initializing Firebase: \(error.localizedDescription)")
        isFirebaseInitialized = false
        return false
      }
    } else {
      print("GoogleService-Info.plist not found, Firebase not initialized")
      isFirebaseInitialized = false
      return false
    }
  }

  // Handle receiving a device token for APNs
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    if initializeFirebase() {
      Messaging.messaging().apnsToken = deviceToken
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle Firebase Messaging token refresh
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    if initializeFirebase() && fcmToken != nil {
      let token = fcmToken!
      print("Firebase registration token: \(token)")

      // Send the token to your server for sending push notifications
      let dataDict: [String: String] = ["token": token]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
    }
  }

  // Handle receiving a notification when the app is in the foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show the notification even when the app is in the foreground
    // This method doesn't directly depend on Firebase, so we can proceed regardless
    completionHandler([[.banner, .sound, .badge]])
  }

  // Handle notification taps
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // This method doesn't directly depend on Firebase initialization,
    // but we should be careful with Firebase-specific data in userInfo
    let userInfo = response.notification.request.content.userInfo

    // Handle the notification tap based on the notification data
    if let taskId = userInfo["taskId"] as? String {
      print("Notification tapped for task: \(taskId)")

      // You can add custom handling here, such as navigating to a specific screen
      // This would typically involve sending a message to the Flutter side
    }

    completionHandler()
  }
}

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
    // Initialize Firebase
    FirebaseApp.configure()

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

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle receiving a device token for APNs
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle Firebase Messaging token refresh
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    if let token = fcmToken {
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
    completionHandler([[.banner, .sound, .badge]])
  }

  // Handle notification taps
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
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

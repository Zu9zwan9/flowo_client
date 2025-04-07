import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import Darwin
import MachO
import ObjectiveC

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

    // Set up security method channel
    let controller = window?.rootViewController as! FlutterViewController
    securityChannel = FlutterMethodChannel(name: "com.flowo.security", binaryMessenger: controller.binaryMessenger)

    securityChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let strongSelf = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "App delegate deallocated", details: nil))
        return
      }

      switch call.method {
      case "isDebuggerAttached":
        result(strongSelf.isDebuggerAttached())
      case "hasSignatureIssues":
        result(strongSelf.hasSignatureIssues())
      case "isRuntimeManipulated":
        result(strongSelf.isRuntimeManipulated())
      case "isJailbroken":
        result(strongSelf.isJailbroken())
      case "hasPasscodeChanged":
        result(strongSelf.hasPasscodeChanged())
      case "hasPasscode":
        result(strongSelf.hasPasscode())
      case "isSimulator":
        result(strongSelf.isSimulator())
      case "hasMissingSecureEnclave":
        result(strongSelf.hasMissingSecureEnclave())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Flag to track if Firebase is initialized
  private var isFirebaseInitialized: Bool = false

  // Security channel for handling security checks
  private var securityChannel: FlutterMethodChannel?

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

  // MARK: - Security Check Methods

  // Check if a debugger is attached
  private func isDebuggerAttached() -> Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    assert(junk == 0, "sysctl failed")
    return (info.kp_proc.p_flag & P_TRACED) != 0
  }

  // Check for signature issues
  private func hasSignatureIssues() -> Bool {
    // In a real implementation, you would verify the app's signature
    // For this example, we'll just check if the app is properly signed
    let bundlePath = Bundle.main.bundlePath
    let fileManager = FileManager.default

    // Check for suspicious files that might indicate signature tampering
    let suspiciousFiles = [
      "\(bundlePath)/Frameworks/RevealServer.framework",
      "\(bundlePath)/Frameworks/FridaGadget.dylib"
    ]

    for file in suspiciousFiles {
      if fileManager.fileExists(atPath: file) {
        return true
      }
    }

    return false
  }

  // Check for runtime manipulation
  private func isRuntimeManipulated() -> Bool {
    // Check for common runtime manipulation tools
    let suspiciousLibraries = [
      "FridaGadget",
      "cynject",
      "libcycript",
      "substrate"
    ]


   // Get list of loaded libraries
       var count: UInt32 = 0
       let images = objc_copyImageNames(&count)

       if images != nil && count > 0 {
         for i in 0..<Int(count) {
           if let imageName = String(cString: images[i], encoding: .utf8) {
             for library in suspiciousLibraries {
               if imageName.contains(library) {
                 return true
               }
             }
           }
         }
       }
    return false
  }

  // Check if the device is jailbroken
  private func isJailbroken() -> Bool {
    // Check for common jailbreak files
    let jailbreakPaths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/usr/bin/ssh",
      "/private/var/lib/apt"
    ]

    for path in jailbreakPaths {
      if FileManager.default.fileExists(atPath: path) {
        return true
      }
    }

    // Check if we can write to a restricted directory
    let restrictedPath = "/private/jailbreak.txt"
    do {
      try "test".write(toFile: restrictedPath, atomically: true, encoding: .utf8)
      try FileManager.default.removeItem(atPath: restrictedPath)
      return true
    } catch {
      // Expected to fail on non-jailbroken devices
    }

    return false
  }

  // Check if the passcode has changed
  private func hasPasscodeChanged() -> Bool {
    // In a real implementation, you would use the keychain to store and check
    // a token that would become invalid if the passcode changes
    // For this example, we'll just return false
    return false
  }

  // Check if a passcode is set
  private func hasPasscode() -> Bool {
    // In a real implementation, you would use LocalAuthentication to check
    // if a passcode is set. For this example, we'll assume a passcode is set
    return true
  }

  // Check if the app is running on a simulator
  private func isSimulator() -> Bool {
    #if targetEnvironment(simulator)
      return true
    #else
      return false
    #endif
  }

  // Check if the secure enclave is missing
  private func hasMissingSecureEnclave() -> Bool {
    // Devices before iPhone 5s don't have Secure Enclave
    // For this example, we'll check the device model
    let modelName = UIDevice.current.model

    // This is a simplified check. In a real implementation,
    // you would use more reliable methods to detect the presence of Secure Enclave
    if modelName.contains("Simulator") {
      return true
    }

    // Assuming all modern devices have Secure Enclave
    return false
  }
}

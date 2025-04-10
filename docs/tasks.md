# Push Notification Implementation Tasks for Flutter

Develop a full push notification feature for an existing Flutter/Dart application using Firebase Cloud Messaging (FCM), targeting both Android and iOS platforms, with all UI following Cupertino design. Assume I have a paid Apple Developer account for iOS setup. Provide all code in Dart and detailed instructions where applicable. Complete each of the following tasks:

- [x] **Dynamic Colors**: Implement system-based dynamic colors that adapt to light and dark modes on both Android and iOS, using Flutter's `ThemeData` with `CupertinoColors` or custom `ColorScheme` compatible with Apple's Human Interface Guidelines. Apply these colors consistently across all Cupertino-styled UI elements.
- [ ] **Cupertino Design**: Build the entire UI using Cupertino widgets (e.g., `CupertinoApp`, `CupertinoPageScaffold`, `CupertinoButton`) for both Android and iOS, adhering to Apple's Human Interface Guidelines for layout, spacing, typography, and navigation patterns (e.g., navigation bars, modals), ensuring a consistent iOS-like experience across platforms.
- [ ] **SOLID Principles**: Structure the codebase using SOLID principles:
    [ ] Single Responsibility: Each class should have one purpose (e.g., separate notification handling from UI).
    [ ] Open/Closed: Design classes to be extensible without modification.
    [ ] Liskov Substitution: Ensure subclasses can replace their base classes.
    [ ] Interface Segregation: Use specific interfaces rather than large, general ones.
    [ ] Dependency Inversion: Depend on abstractions (abstract classes/interfaces) rather than concrete implementations.
- [ ] **OOP Best Practices**: Apply object-oriented programming principles in Dart:
    [ ] Encapsulation: Hide implementation details and expose only necessary interfaces.
    [ ] Inheritance: Use base classes or interfaces where beneficial.
    [ ] Polymorphism: Allow flexible behavior through interface implementation or subclassing.
- [x] **Firebase Integration**: Fully integrate Firebase Cloud Messaging for both Android and iOS with the following sub-tasks:
     [x] Set up Firebase Cloud Messaging by configuring the project with Firebase (e.g., adding `google-services.json` for Android and `GoogleService-Info.plist` for iOS), enabling push notifications in Xcode for iOS, and linking with an APNs key from the Apple Developer account.
     [x] Handle notification permissions by requesting user authorization on both platforms, using platform-specific APIs via Flutter (e.g., `firebase_messaging` package).
     [x] Manage FCM tokens and implement logic to retrieve and store them securely for both platforms.
     [x] Handle incoming notifications in both foreground and background states, displaying them appropriately based on app state with Cupertino-styled alerts on both platforms.
     [x] Implement notification actions for different notification types (tasks, events, habits).
     [x] Add support for deep links in notifications.
     [x] Add support for notification categories.
- [x] **User-Adjustable Notifications**: Enable users to customize notifications for tasks, events, and habits:
     [x] Implement notification settings when creating tasks, events, and habits, allowing users to select the notification type (e.g., alert, badge, sound where applicable) and how much time before the task/event/habit to send the notification (e.g., 5 minutes, 1 hour, 1 day), presented in a Cupertino-style interface.
     [x] Add the same notification customization options in the edit screens for tasks, events, and habits, ensuring users can modify the type and timing after creation, using Cupertino widgets like `CupertinoPicker` or `CupertinoSegmentedControl`.
     [x] Store these settings persistently using Hive and schedule notifications accordingly via FCM local scheduling with `flutter_local_notifications`.
- [ ] **Best Practices**: Incorporate the following development best practices:
     [ ] Use Dart's asynchronous programming (async/await) for all asynchronous operations, such as requesting permissions or fetching tokens.
     [ ] Implement comprehensive error handling with custom exception classes and meaningful user feedback, displayed in Cupertino-style dialogs.
     [ ] Use dependency injection (e.g., with `provider` or `get_it`) to provide the notification service to other components, enhancing testability.

Provide the following deliverables in Dart:
 [x] An abstract class/interface defining the notification service and a concrete class implementing it for Firebase integration.
 [x] Configuration of Firebase Messaging in the app's entry point `main.dart` and handling of notification delegates for both platforms.
 [ ] A sample Cupertino-based UI for both Android and iOS (e.g., a screen with a `CupertinoButton` to request permissions and display notification status, plus creation/edit screens for tasks, events, and habits with notification settings using Cupertino widgets).
 [ ] Step-by-step instructions for Firebase setup, including adding `google-services.json` for Android, `GoogleService-Info.plist` for iOS, configuring APNs in the Apple Developer account, and enabling push notifications in both platforms' configurations.

[x] Ensure the final implementation is production-ready, modular, maintainable, and follows modern Flutter development standards, with a consistent Cupertino design across Android and iOS.

import 'package:flutter/cupertino.dart';
import 'dart:async';

/// Shows a Cupertino-style notification at the bottom of the screen.
/// This is a replacement for Material's ScaffoldMessenger.showSnackBar.
void showCupertinoNotification({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 2),
  Color? backgroundColor,
  Color? textColor,
  VoidCallback? onTap,
  String? actionText,
  VoidCallback? onActionTap,
}) {
  // Create an overlay entry for the notification
  final overlayState = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) {
      final isDarkMode =
          CupertinoTheme.of(context).brightness == Brightness.dark;

      return Positioned(
        bottom: 16.0,
        left: 16.0,
        right: 16.0,
        child: SafeArea(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color:
                    backgroundColor ??
                    (isDarkMode
                        ? CupertinoColors.systemGrey6.darkColor.withOpacity(0.9)
                        : CupertinoColors.systemGrey6.withOpacity(0.9)),
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.1),
                    blurRadius: 10.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color:
                            textColor ??
                            (isDarkMode
                                ? CupertinoColors.white
                                : CupertinoColors.black),
                      ),
                    ),
                  ),
                  if (actionText != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (onActionTap != null) {
                          onActionTap();
                        }
                      }, minimumSize: Size(0, 0),
                      child: Text(
                        actionText,
                        style: TextStyle(
                          color: CupertinoTheme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  // Insert the overlay entry
  overlayState.insert(overlayEntry);

  // Remove the overlay entry after the specified duration
  Timer(duration, () {
    overlayEntry.remove();
  });
}

/// Shows an error notification with a red background.
void showErrorNotification({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 3),
  VoidCallback? onTap,
  String? actionText,
  VoidCallback? onActionTap,
}) {
  showCupertinoNotification(
    context: context,
    message: message,
    duration: duration,
    backgroundColor: CupertinoColors.systemRed.withOpacity(0.9),
    textColor: CupertinoColors.white,
    onTap: onTap,
    actionText: actionText,
    onActionTap: onActionTap,
  );
}

/// Shows a success notification with a green background.
void showSuccessNotification({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 2),
  VoidCallback? onTap,
  String? actionText,
  VoidCallback? onActionTap,
}) {
  showCupertinoNotification(
    context: context,
    message: message,
    duration: duration,
    backgroundColor: CupertinoColors.systemGreen.withOpacity(0.9),
    textColor: CupertinoColors.white,
    onTap: onTap,
    actionText: actionText,
    onActionTap: onActionTap,
  );
}

/// Shows an info notification with a blue background.
void showInfoNotification({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 2),
  VoidCallback? onTap,
  String? actionText,
  VoidCallback? onActionTap,
}) {
  showCupertinoNotification(
    context: context,
    message: message,
    duration: duration,
    backgroundColor: CupertinoColors.systemBlue.withOpacity(0.9),
    textColor: CupertinoColors.white,
    onTap: onTap,
    actionText: actionText,
    onActionTap: onActionTap,
  );
}

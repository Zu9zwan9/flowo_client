import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling camera permissions in a secure and user-friendly way
///
/// This service follows SOLID principles by having a single responsibility:
/// managing camera permissions. It provides methods to check, request, and handle
/// camera permissions with proper error handling and user feedback.
class CameraPermissionService {
  /// Check if the app has camera permission
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      logError('Error checking camera permission: $e');
      return false;
    }
  }

  /// Request camera permission from the user
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      logError('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Check and request camera permission if needed
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> checkAndRequestCameraPermission() async {
    try {
      // First check if we already have permission
      if (await hasCameraPermission()) {
        return true;
      }

      // If not, request permission
      return await requestCameraPermission();
    } catch (e) {
      logError('Error in checkAndRequestCameraPermission: $e');
      return false;
    }
  }

  /// Show a dialog explaining why the app needs camera permission
  ///
  /// This follows Apple HIG by explaining the benefit to the user
  Future<void> showCameraPermissionDialog(BuildContext context) async {
    HapticFeedback.mediumImpact();

    return showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Camera Access Required'),
            content: const Text(
              'Flowo needs access to your camera to take profile pictures. '
              'This helps personalize your account and makes it easier for you to identify your profile.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Settings'),
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  await openAppSettings();
                },
              ),
            ],
          ),
    );
  }

  /// Show a dialog when camera permission is permanently denied
  ///
  /// This follows Apple HIG by providing a clear path to resolve the issue
  Future<void> showPermanentlyDeniedDialog(BuildContext context) async {
    HapticFeedback.mediumImpact();

    return showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Camera Access Denied'),
            content: const Text(
              'Camera access is required to take profile pictures. '
              'Please enable camera access in your device settings.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Open Settings'),
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  await openAppSettings();
                },
              ),
            ],
          ),
    );
  }
}

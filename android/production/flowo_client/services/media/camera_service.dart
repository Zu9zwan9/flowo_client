import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Result of a camera operation
class CameraResult {
  /// Whether the operation was successful
  final bool success;

  /// The file path of the image if successful
  final String? filePath;

  /// Error message if the operation failed
  final String? errorMessage;

  /// Error code if the operation failed
  final String? errorCode;

  const CameraResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    this.errorCode,
  });

  /// Create a successful result
  factory CameraResult.success(String filePath) {
    return CameraResult(success: true, filePath: filePath);
  }

  /// Create a failed result
  factory CameraResult.failure(String errorMessage, {String? errorCode}) {
    return CameraResult(
      success: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }

  /// Create a cancelled result
  factory CameraResult.cancelled() {
    return CameraResult(
      success: false,
      errorMessage: 'Operation cancelled by user',
      errorCode: 'user_cancelled',
    );
  }
}

/// Service for handling camera operations in a secure and user-friendly way
///
/// This service follows SOLID principles by having a single responsibility:
/// managing camera operations. It provides methods to take photos and handle
/// camera permissions with proper error handling and user feedback.
class CameraService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Take a photo using the device camera
  ///
  /// Returns a [CameraResult] with the result of the operation
  Future<CameraResult> takePhoto({
    CameraDevice preferredCamera = CameraDevice.front,
    int imageQuality = 90,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCamera,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        // User cancelled the operation
        return CameraResult.cancelled();
      }

      // Save the image to the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${appDir.path}/$fileName');

      // Copy the picked image to the app's documents directory
      await File(pickedFile.path).copy(savedImage.path);

      logInfo('Photo saved to: ${savedImage.path}');
      return CameraResult.success(savedImage.path);
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        logError('Camera permission denied: ${e.message}');
        return CameraResult.failure(
          'Camera permission denied. Please enable camera access in your device settings.',
          errorCode: 'permission_denied',
        );
      } else {
        logError('Error taking photo: ${e.message}');
        return CameraResult.failure(
          'Failed to take photo: ${e.message}',
          errorCode: e.code,
        );
      }
    } catch (e) {
      logError('Error taking photo: $e');
      return CameraResult.failure('Failed to take photo: $e');
    }
  }

  /// Select an image from the gallery
  ///
  /// Returns a [CameraResult] with the result of the operation
  Future<CameraResult> pickImageFromGallery({int imageQuality = 90}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        // User cancelled the operation
        return CameraResult.cancelled();
      }

      // Save the image to the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${appDir.path}/$fileName');

      // Copy the picked image to the app's documents directory
      await File(pickedFile.path).copy(savedImage.path);

      logInfo('Image saved to: ${savedImage.path}');
      return CameraResult.success(savedImage.path);
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        logError('Gallery permission denied: ${e.message}');
        return CameraResult.failure(
          'Gallery permission denied. Please enable photo access in your device settings.',
          errorCode: 'permission_denied',
        );
      } else {
        logError('Error picking image: ${e.message}');
        return CameraResult.failure(
          'Failed to pick image: ${e.message}',
          errorCode: e.code,
        );
      }
    } catch (e) {
      logError('Error picking image: $e');
      return CameraResult.failure('Failed to pick image: $e');
    }
  }

  /// Show a dialog when camera permission is denied
  ///
  /// This follows Apple HIG by providing a clear path to resolve the issue
  Future<void> showCameraPermissionDeniedDialog(BuildContext context) async {
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
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
            ],
          ),
    );
  }

  /// Show instructions for opening app settings
  ///
  /// Since we don't have url_launcher, we'll just show instructions
  /// for the user to manually open settings
  void openAppSettings() {
    logInfo('Instructing user to open app settings manually');
    // This is a no-op method since we can't directly open settings
    // The dialog already provides instructions for the user
  }
}

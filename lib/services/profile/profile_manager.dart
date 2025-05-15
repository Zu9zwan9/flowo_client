import 'dart:io';

import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/services/media/camera_service.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

/// A service class that manages user profile data and operations
class ProfileManager {
  late Box<UserProfile> _userProfilesBox;
  UserProfile? _currentProfile;

  /// Camera service for handling camera operations
  final CameraService _cameraService = CameraService();

  /// Initialize the profile manager
  Future<void> initialize() async {
    try {
      _userProfilesBox = await Hive.openBox<UserProfile>('user_profiles');
      _currentProfile = _userProfilesBox.get('current');
      logInfo('ProfileManager initialized');
    } catch (e) {
      logError('Error initializing ProfileManager: $e');
      rethrow;
    }
  }

  /// Get the current user profile
  UserProfile? get currentProfile => _currentProfile;

  /// Check if a profile exists
  bool get hasProfile => _currentProfile != null;

  /// Update the user profile with new information
  Future<void> updateProfile({
    required String name,
    required String email,
    String? avatarPath,
  }) async {
    try {
      if (_currentProfile == null) {
        // Create a new profile if none exists
        _currentProfile = UserProfile(
          name: name,
          email: email,
          avatarPath: avatarPath,
        );
      } else {
        // Update existing profile
        _currentProfile!.name = name;
        _currentProfile!.email = email;
        if (avatarPath != null) {
          _currentProfile!.avatarPath = avatarPath;
        }
      }

      // Save to Hive
      await _userProfilesBox.put('current', _currentProfile!);
      logInfo('Profile updated successfully');
    } catch (e) {
      logError('Error updating profile: $e');
      rethrow;
    }
  }

  /// Change the avatar by selecting an image from the gallery
  ///
  /// Returns the path to the saved image, or null if the operation was cancelled or failed
  Future<String?> changeAvatarFromGallery() async {
    try {
      // Use the camera service to pick an image from the gallery
      final result = await _cameraService.pickImageFromGallery();

      if (result.success && result.filePath != null) {
        // Update the avatar path in the user profile
        if (_currentProfile != null) {
          _currentProfile!.avatarPath = result.filePath;
          await _userProfilesBox.put('current', _currentProfile!);
        }

        logInfo('Avatar saved to: ${result.filePath}');
        return result.filePath;
      } else if (result.errorCode == 'permission_denied') {
        logWarning('Gallery permission denied: ${result.errorMessage}');
      } else if (result.errorCode != 'user_cancelled') {
        logError('Error picking image: ${result.errorMessage}');
      }

      return null;
    } catch (e) {
      logError('Error changing avatar: $e');
      return null;
    }
  }

  /// Change the avatar by taking a photo with the camera
  ///
  /// Returns the path to the saved image, or null if the operation was cancelled or failed
  Future<String?> changeAvatarFromCamera() async {
    try {
      // Use the camera service to take a photo
      final result = await _cameraService.takePhoto();

      if (result.success && result.filePath != null) {
        // Update the avatar path in the user profile
        if (_currentProfile != null) {
          _currentProfile!.avatarPath = result.filePath;
          await _userProfilesBox.put('current', _currentProfile!);
        }

        logInfo('Avatar saved to: ${result.filePath}');
        return result.filePath;
      } else if (result.errorCode == 'permission_denied') {
        logWarning('Camera permission denied: ${result.errorMessage}');
      } else if (result.errorCode != 'user_cancelled') {
        logError('Error taking photo: ${result.errorMessage}');
      }

      return null;
    } catch (e) {
      logError('Error taking photo: $e');
      return null;
    }
  }

  /// Show camera permission denied dialog
  ///
  /// This is a convenience method that delegates to the camera service
  Future<void> showCameraPermissionDeniedDialog(BuildContext context) async {
    await _cameraService.showCameraPermissionDeniedDialog(context);
  }

  /// Remove the avatar and use initials instead
  Future<void> removeAvatar() async {
    try {
      if (_currentProfile != null) {
        _currentProfile!.avatarPath = null;
        await _userProfilesBox.put('current', _currentProfile!);
      }

      logInfo('Avatar removed');
    } catch (e) {
      logError('Error removing avatar: $e');
      rethrow;
    }
  }

  /// Delete the user account and all associated data
  Future<void> deleteAccount() async {
    try {
      // Delete the avatar file if it exists
      if (_currentProfile?.avatarPath != null) {
        final avatarFile = File(_currentProfile!.avatarPath!);
        if (avatarFile.existsSync()) {
          await avatarFile.delete();
          logInfo('Deleted avatar file: ${_currentProfile!.avatarPath}');
        }
      }

      // Delete the user profile from the Hive box
      await _userProfilesBox.delete('current');
      _currentProfile = null;

      logWarning('Account deleted');
    } catch (e) {
      logError('Error deleting account: $e');
      rethrow;
    }
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
}

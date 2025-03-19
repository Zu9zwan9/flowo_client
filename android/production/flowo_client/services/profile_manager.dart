import 'dart:io';

import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// A service class that manages user profile data and operations
/// Following SOLID principles by separating business logic from UI
class ProfileManager {
  late Box<UserProfile> _userProfilesBox;
  UserProfile? _currentProfile;

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
  Future<String?> changeAvatarFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        // Get the app's documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$fileName');

        // Copy the picked image to the app's documents directory
        await File(pickedFile.path).copy(savedImage.path);

        // Update the avatar path in the user profile
        if (_currentProfile != null) {
          _currentProfile!.avatarPath = savedImage.path;
          await _userProfilesBox.put('current', _currentProfile!);
        }

        logInfo('Avatar saved to: ${savedImage.path}');
        return savedImage.path;
      }
      return null;
    } catch (e) {
      logError('Error changing avatar: $e');
      rethrow;
    }
  }

  /// Change the avatar by taking a photo with the camera
  Future<String?> changeAvatarFromCamera() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (pickedFile != null) {
        // Get the app's documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$fileName');

        // Copy the picked image to the app's documents directory
        await File(pickedFile.path).copy(savedImage.path);

        // Update the avatar path in the user profile
        if (_currentProfile != null) {
          _currentProfile!.avatarPath = savedImage.path;
          await _userProfilesBox.put('current', _currentProfile!);
        }

        logInfo('Avatar saved to: ${savedImage.path}');
        return savedImage.path;
      }
      return null;
    } catch (e) {
      logError('Error taking photo: $e');
      rethrow;
    }
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

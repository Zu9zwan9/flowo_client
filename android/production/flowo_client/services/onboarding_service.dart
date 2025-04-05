import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:hive/hive.dart';

/// Service to manage the onboarding process
class OnboardingService {
  final Box<UserProfile> _userProfileBox;

  OnboardingService(this._userProfileBox);

  /// Check if the user has completed onboarding
  bool isOnboardingCompleted() {
    try {
      appLogger.info(
        'Checking if onboarding is completed',
        'OnboardingService',
      );

      // Ensure the box is open and readable
      if (!_userProfileBox.isOpen) {
        appLogger.error('UserProfile box is not open', 'OnboardingService');
        return false;
      }

      // Get the current user profile
      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        appLogger.warning(
          'User profile not found when checking onboarding status, creating a new one',
          'OnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: false,
        );

        // Save the new profile
        _userProfileBox.put('current', userProfile);

        appLogger.info(
          'Created new user profile with onboardingCompleted: false',
          'OnboardingService',
        );
        return false;
      }

      appLogger.info(
        'Onboarding status: ${userProfile.onboardingCompleted}',
        'OnboardingService',
      );
      return userProfile.onboardingCompleted;
    } catch (e) {
      appLogger.error(
        'Error checking onboarding status: $e',
        'OnboardingService',
      );
      return false;
    }
  }

  /// Save user name during onboarding
  Future<void> saveUserName(String name) async {
    try {
      appLogger.info('Attempting to save name: "$name"', 'OnboardingService');

      // Ensure the box is open and writable
      if (!_userProfileBox.isOpen) {
        appLogger.error('UserProfile box is not open', 'OnboardingService');
        throw Exception('UserProfile box is not open');
      }

      // Get the current user profile or create a new one if it doesn't exist
      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        // Create a new user profile if it doesn't exist
        appLogger.warning(
          'User profile not found, creating a new one',
          'OnboardingService',
        );
        userProfile = UserProfile(
          name: name,
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: false,
        );

        // Save the new profile
        await _userProfileBox.put('current', userProfile);

        // Verify the profile was saved
        var savedProfile = _userProfileBox.get('current');
        if (savedProfile == null) {
          appLogger.error(
            'Failed to save new user profile with name: "$name"',
            'OnboardingService',
          );
          throw Exception('Failed to save user profile');
        }

        appLogger.info(
          'Created new user profile with name: "$name"',
          'OnboardingService',
        );
      } else {
        // Update the existing user profile
        userProfile.name = name;

        // Save the updated profile using save() method
        await userProfile.save();

        // Verify the profile was updated
        var updatedProfile = _userProfileBox.get('current');
        if (updatedProfile == null || updatedProfile.name != name) {
          appLogger.error(
            'Failed to update user profile with name: "$name"',
            'OnboardingService',
          );
          throw Exception('Failed to update user profile');
        }

        appLogger.info(
          'User name saved successfully: "$name"',
          'OnboardingService',
        );
      }
    } catch (e) {
      appLogger.error('Error saving user name: $e', 'OnboardingService');
      rethrow;
    }
  }

  /// Save user goal during onboarding
  Future<void> saveUserGoal(String goal) async {
    try {
      appLogger.info('Attempting to save goal: "$goal"', 'OnboardingService');

      // Ensure the box is open and writable
      if (!_userProfileBox.isOpen) {
        appLogger.error('UserProfile box is not open', 'OnboardingService');
        throw Exception('UserProfile box is not open');
      }

      // Get the current user profile or create a new one if it doesn't exist
      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        appLogger.warning(
          'User profile not found when saving goal, creating a new one',
          'OnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: goal,
          onboardingCompleted: false,
        );

        // Save the new profile
        await _userProfileBox.put('current', userProfile);

        // Verify the profile was saved
        var savedProfile = _userProfileBox.get('current');
        if (savedProfile == null) {
          appLogger.error(
            'Failed to save new user profile with goal: "$goal"',
            'OnboardingService',
          );
          throw Exception('Failed to save user profile');
        }

        appLogger.info(
          'Created new user profile with goal: "$goal"',
          'OnboardingService',
        );
      } else {
        // Update the existing user profile
        appLogger.info(
          'Updating existing user profile with goal: "$goal", current state: name=${userProfile.name}, goal=${userProfile.goal}, onboardingCompleted=${userProfile.onboardingCompleted}',
          'OnboardingService',
        );

        userProfile.goal = goal;

        // Save the updated profile using save() method
        try {
          await userProfile.save();
          appLogger.info(
            'Successfully called save() on user profile with goal: "$goal"',
            'OnboardingService',
          );
        } catch (e) {
          appLogger.error(
            'Error calling save() on user profile: $e',
            'OnboardingService',
          );
          // Fallback to put() method if save() fails
          await _userProfileBox.put('current', userProfile);
          appLogger.info(
            'Fallback: Used put() method to save user profile with goal: "$goal"',
            'OnboardingService',
          );
        }

        // Verify the profile was updated
        var updatedProfile = _userProfileBox.get('current');
        if (updatedProfile == null) {
          appLogger.error(
            'Failed to update user profile: profile is null after save',
            'OnboardingService',
          );
          throw Exception(
            'Failed to update user profile: profile is null after save',
          );
        } else if (updatedProfile.goal != goal) {
          appLogger.error(
            'Failed to update user profile with goal: "$goal", actual goal: "${updatedProfile.goal}"',
            'OnboardingService',
          );
          throw Exception(
            'Failed to update user profile: goal was not saved correctly',
          );
        } else {
          appLogger.info(
            'Successfully verified user profile update: name=${updatedProfile.name}, goal=${updatedProfile.goal}, onboardingCompleted=${updatedProfile.onboardingCompleted}',
            'OnboardingService',
          );
        }

        appLogger.info(
          'User goal saved successfully: "$goal"',
          'OnboardingService',
        );
      }
    } catch (e) {
      appLogger.error('Error saving user goal: $e', 'OnboardingService');
      rethrow;
    }
  }

  /// Complete the onboarding process
  Future<void> completeOnboarding() async {
    try {
      appLogger.info('Attempting to complete onboarding', 'OnboardingService');

      // Ensure the box is open and writable
      if (!_userProfileBox.isOpen) {
        appLogger.error('UserProfile box is not open', 'OnboardingService');
        throw Exception('UserProfile box is not open');
      }

      // Get the current user profile or create a new one if it doesn't exist
      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        // Create a new user profile if it doesn't exist
        appLogger.warning(
          'User profile not found, creating a new one',
          'OnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: true,
        );

        // Save the new profile
        await _userProfileBox.put('current', userProfile);

        // Verify the profile was saved
        var savedProfile = _userProfileBox.get('current');
        if (savedProfile == null) {
          appLogger.error(
            'Failed to save new user profile with onboardingCompleted: true',
            'OnboardingService',
          );
          throw Exception('Failed to save user profile');
        }

        appLogger.info(
          'Created new user profile with onboardingCompleted: true',
          'OnboardingService',
        );
      } else {
        // Update the existing user profile
        appLogger.info(
          'Updating existing user profile with onboardingCompleted: true, current state: name=${userProfile.name}, goal=${userProfile.goal}, onboardingCompleted=${userProfile.onboardingCompleted}',
          'OnboardingService',
        );

        userProfile.onboardingCompleted = true;

        // Save the updated profile using save() method
        try {
          await userProfile.save();
          appLogger.info(
            'Successfully called save() on user profile with onboardingCompleted: true',
            'OnboardingService',
          );
        } catch (e) {
          appLogger.error(
            'Error calling save() on user profile: $e',
            'OnboardingService',
          );
          // Fallback to put() method if save() fails
          await _userProfileBox.put('current', userProfile);
          appLogger.info(
            'Fallback: Used put() method to save user profile with onboardingCompleted: true',
            'OnboardingService',
          );
        }

        // Verify the profile was updated
        var updatedProfile = _userProfileBox.get('current');
        if (updatedProfile == null) {
          appLogger.error(
            'Failed to update user profile: profile is null after save',
            'OnboardingService',
          );
          throw Exception(
            'Failed to update user profile: profile is null after save',
          );
        } else if (!updatedProfile.onboardingCompleted) {
          appLogger.error(
            'Failed to update user profile with onboardingCompleted: true, actual onboardingCompleted: ${updatedProfile.onboardingCompleted}',
            'OnboardingService',
          );
          throw Exception(
            'Failed to update user profile: onboardingCompleted was not saved correctly',
          );
        } else {
          appLogger.info(
            'Successfully verified user profile update: name=${updatedProfile.name}, goal=${updatedProfile.goal}, onboardingCompleted=${updatedProfile.onboardingCompleted}',
            'OnboardingService',
          );
        }

        appLogger.info(
          'Onboarding completed successfully',
          'OnboardingService',
        );
      }
    } catch (e) {
      appLogger.error('Error completing onboarding: $e', 'OnboardingService');
      rethrow;
    }
  }

  /// Get the current user profile
  UserProfile getCurrentUserProfile() {
    try {
      appLogger.info('Getting current user profile', 'OnboardingService');

      // Ensure the box is open and readable
      if (!_userProfileBox.isOpen) {
        appLogger.error('UserProfile box is not open', 'OnboardingService');
        throw Exception('UserProfile box is not open');
      }

      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        // Create a new user profile if it doesn't exist
        appLogger.warning(
          'User profile not found, creating a new one',
          'OnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: false,
        );

        // Save the new profile
        _userProfileBox.put('current', userProfile);

        // Verify the profile was saved
        var savedProfile = _userProfileBox.get('current');
        if (savedProfile == null) {
          appLogger.error(
            'Failed to save new user profile',
            'OnboardingService',
          );
          throw Exception('Failed to save user profile');
        }

        appLogger.info('Created new user profile', 'OnboardingService');
      }

      appLogger.info(
        'Retrieved user profile: name=${userProfile.name}, goal=${userProfile.goal}, onboardingCompleted=${userProfile.onboardingCompleted}',
        'OnboardingService',
      );
      return userProfile;
    } catch (e) {
      appLogger.error('Error getting user profile: $e', 'OnboardingService');
      // Create a default profile in case of error
      return UserProfile(
        name: 'User',
        email: 'user@example.com',
        goal: null,
        onboardingCompleted: false,
      );
    }
  }
}

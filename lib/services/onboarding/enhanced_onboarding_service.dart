import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:hive/hive.dart';

/// Enhanced service to manage the onboarding process with additional functionality
class EnhancedOnboardingService {
  final Box<UserProfile> _userProfileBox;

  // Track which onboarding steps have been completed
  static const String _onboardingProgressKey = 'onboarding_progress';
  static const String _onboardingLastScreenKey = 'onboarding_last_screen';
  static const String _tutorialCompletedKey = 'tutorial_completed';

  // Define onboarding steps
  static const List<String> onboardingSteps = [
    'welcome', // Welcome screen
    'name', // Name input
    'goal', // Goal input
    'tasks', // Task management introduction
    'calendar', // Calendar introduction
    'analytics', // Analytics introduction
    'settings', // Settings introduction
    'complete', // Completion screen
  ];

  EnhancedOnboardingService(this._userProfileBox);

  /// Check if the user has completed onboarding
  bool isOnboardingCompleted() {
    try {
      appLogger.info(
        'Checking if onboarding is completed',
        'EnhancedOnboardingService',
      );

      // Ensure the box is open and readable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        return false;
      }

      // Get the current user profile
      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        appLogger.warning(
          'User profile not found when checking onboarding status, creating a new one',
          'EnhancedOnboardingService',
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
          'EnhancedOnboardingService',
        );
        return false;
      }

      appLogger.info(
        'Onboarding status: ${userProfile.onboardingCompleted}',
        'EnhancedOnboardingService',
      );
      return userProfile.onboardingCompleted;
    } catch (e) {
      appLogger.error(
        'Error checking onboarding status: $e',
        'EnhancedOnboardingService',
      );
      return false;
    }
  }

  /// Get the current onboarding progress (which steps have been completed)
  List<String> getOnboardingProgress() {
    try {
      // Ensure the box is open and readable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        return [];
      }

      // Get the current user profile
      var userProfile = _userProfileBox.get('current');
      if (userProfile == null) {
        return [];
      }

      // Get the progress from the user profile's metadata
      final progressData = userProfile.metadata?[_onboardingProgressKey];
      if (progressData == null || progressData is! List) {
        return [];
      }

      return List<String>.from(progressData);
    } catch (e) {
      appLogger.error(
        'Error getting onboarding progress: $e',
        'EnhancedOnboardingService',
      );
      return [];
    }
  }

  /// Mark a step as completed in the onboarding progress
  Future<void> markStepCompleted(String step) async {
    try {
      appLogger.info(
        'Marking onboarding step as completed: $step',
        'EnhancedOnboardingService',
      );

      // Ensure the box is open and writable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        throw Exception('UserProfile box is not open');
      }

      // Get the current user profile
      var userProfile = _userProfileBox.get('current');
      if (userProfile == null) {
        appLogger.warning(
          'User profile not found, creating a new one',
          'EnhancedOnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: false,
          metadata: {},
        );
      }

      // Initialize metadata if it doesn't exist
      userProfile.metadata ??= {};

      // Get the current progress
      List<String> progress = [];
      if (userProfile.metadata!.containsKey(_onboardingProgressKey)) {
        final progressData = userProfile.metadata![_onboardingProgressKey];
        if (progressData is List) {
          progress = List<String>.from(progressData);
        }
      }

      // Add the step if it's not already in the list
      if (!progress.contains(step)) {
        progress.add(step);
      }

      // Update the progress in metadata
      userProfile.metadata![_onboardingProgressKey] = progress;

      // Save the last screen visited
      userProfile.metadata![_onboardingLastScreenKey] = step;

      // Save the updated profile
      await _userProfileBox.put('current', userProfile);

      appLogger.info(
        'Onboarding step marked as completed: $step',
        'EnhancedOnboardingService',
      );
    } catch (e) {
      appLogger.error(
        'Error marking onboarding step as completed: $e',
        'EnhancedOnboardingService',
      );
      rethrow;
    }
  }

  /// Get the last onboarding screen the user visited
  String? getLastScreen() {
    try {
      // Ensure the box is open and readable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        return null;
      }

      // Get the current user profile
      var userProfile = _userProfileBox.get('current');
      if (userProfile == null || userProfile.metadata == null) {
        return null;
      }

      // Get the last screen from the user profile's metadata
      return userProfile.metadata![_onboardingLastScreenKey] as String?;
    } catch (e) {
      appLogger.error(
        'Error getting last onboarding screen: $e',
        'EnhancedOnboardingService',
      );
      return null;
    }
  }

  /// Check if the tutorial has been completed
  bool isTutorialCompleted() {
    try {
      // Ensure the box is open and readable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        return false;
      }

      // Get the current user profile
      var userProfile = _userProfileBox.get('current');
      if (userProfile == null || userProfile.metadata == null) {
        return false;
      }

      // Get the tutorial completed status from the user profile's metadata
      final tutorialCompleted = userProfile.metadata![_tutorialCompletedKey];
      return tutorialCompleted == true;
    } catch (e) {
      appLogger.error(
        'Error checking if tutorial is completed: $e',
        'EnhancedOnboardingService',
      );
      return false;
    }
  }

  /// Mark the tutorial as completed
  Future<void> markTutorialCompleted() async {
    try {
      appLogger.info(
        'Marking tutorial as completed',
        'EnhancedOnboardingService',
      );

      // Ensure the box is open and writable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        throw Exception('UserProfile box is not open');
      }

      // Get the current user profile
      var userProfile = _userProfileBox.get('current');
      if (userProfile == null) {
        appLogger.warning(
          'User profile not found, creating a new one',
          'EnhancedOnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: false,
          metadata: {},
        );
      }

      // Initialize metadata if it doesn't exist
      userProfile.metadata ??= {};

      // Mark tutorial as completed
      userProfile.metadata![_tutorialCompletedKey] = true;

      // Save the updated profile
      await _userProfileBox.put('current', userProfile);

      appLogger.info(
        'Tutorial marked as completed',
        'EnhancedOnboardingService',
      );
    } catch (e) {
      appLogger.error(
        'Error marking tutorial as completed: $e',
        'EnhancedOnboardingService',
      );
      rethrow;
    }
  }

  /// Save user name during onboarding
  Future<void> saveUserName(String name) async {
    try {
      appLogger.info(
        'Attempting to save name: "$name"',
        'EnhancedOnboardingService',
      );

      // Ensure the box is open and writable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        throw Exception('UserProfile box is not open');
      }

      // Get the current user profile or create a new one if it doesn't exist
      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        // Create a new user profile if it doesn't exist
        appLogger.warning(
          'User profile not found, creating a new one',
          'EnhancedOnboardingService',
        );
        userProfile = UserProfile(
          name: name,
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: false,
          metadata: {},
        );

        // Save the new profile
        await _userProfileBox.put('current', userProfile);

        // Verify the profile was saved
        var savedProfile = _userProfileBox.get('current');
        if (savedProfile == null) {
          appLogger.error(
            'Failed to save new user profile with name: "$name"',
            'EnhancedOnboardingService',
          );
          throw Exception('Failed to save user profile');
        }

        appLogger.info(
          'Created new user profile with name: "$name"',
          'EnhancedOnboardingService',
        );
      } else {
        // Update the existing user profile
        userProfile.name = name;

        // Initialize metadata if it doesn't exist
        userProfile.metadata ??= {};

        // Save the updated profile
        await _userProfileBox.put('current', userProfile);

        // Verify the profile was updated
        var updatedProfile = _userProfileBox.get('current');
        if (updatedProfile == null || updatedProfile.name != name) {
          appLogger.error(
            'Failed to update user profile with name: "$name"',
            'EnhancedOnboardingService',
          );
          throw Exception('Failed to update user profile');
        }

        appLogger.info(
          'User name saved successfully: "$name"',
          'EnhancedOnboardingService',
        );
      }

      // Mark the name step as completed
      await markStepCompleted('name');
    } catch (e) {
      appLogger.error(
        'Error saving user name: $e',
        'EnhancedOnboardingService',
      );
      rethrow;
    }
  }

  /// Save user goal during onboarding
  Future<void> saveUserGoal(String goal) async {
    try {
      appLogger.info(
        'Attempting to save goal: "$goal"',
        'EnhancedOnboardingService',
      );

      // Ensure the box is open and writable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        throw Exception('UserProfile box is not open');
      }

      // Get the current user profile or create a new one if it doesn't exist
      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        appLogger.warning(
          'User profile not found when saving goal, creating a new one',
          'EnhancedOnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: goal,
          onboardingCompleted: false,
          metadata: {},
        );

        // Save the new profile
        await _userProfileBox.put('current', userProfile);

        // Verify the profile was saved
        var savedProfile = _userProfileBox.get('current');
        if (savedProfile == null) {
          appLogger.error(
            'Failed to save new user profile with goal: "$goal"',
            'EnhancedOnboardingService',
          );
          throw Exception('Failed to save user profile');
        }

        appLogger.info(
          'Created new user profile with goal: "$goal"',
          'EnhancedOnboardingService',
        );
      } else {
        // Update the existing user profile
        userProfile.goal = goal;

        // Initialize metadata if it doesn't exist
        userProfile.metadata ??= {};

        // Save the updated profile
        await _userProfileBox.put('current', userProfile);

        // Verify the profile was updated
        var updatedProfile = _userProfileBox.get('current');
        if (updatedProfile == null || updatedProfile.goal != goal) {
          appLogger.error(
            'Failed to update user profile with goal: "$goal"',
            'EnhancedOnboardingService',
          );
          throw Exception('Failed to update user profile');
        }

        appLogger.info(
          'User goal saved successfully: "$goal"',
          'EnhancedOnboardingService',
        );
      }

      // Mark the goal step as completed
      await markStepCompleted('goal');
    } catch (e) {
      appLogger.error(
        'Error saving user goal: $e',
        'EnhancedOnboardingService',
      );
      rethrow;
    }
  }

  /// Complete the onboarding process
  Future<void> completeOnboarding() async {
    try {
      appLogger.info(
        'Attempting to complete onboarding',
        'EnhancedOnboardingService',
      );

      // Ensure the box is open and writable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        throw Exception('UserProfile box is not open');
      }

      // Get the current user profile or create a new one if it doesn't exist
      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        // Create a new user profile if it doesn't exist
        appLogger.warning(
          'User profile not found, creating a new one',
          'EnhancedOnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: true,
          metadata: {
            _onboardingProgressKey: onboardingSteps,
            _onboardingLastScreenKey: 'complete',
          },
        );

        // Save the new profile
        await _userProfileBox.put('current', userProfile);

        // Verify the profile was saved
        var savedProfile = _userProfileBox.get('current');
        if (savedProfile == null) {
          appLogger.error(
            'Failed to save new user profile with onboardingCompleted: true',
            'EnhancedOnboardingService',
          );
          throw Exception('Failed to save user profile');
        }

        appLogger.info(
          'Created new user profile with onboardingCompleted: true',
          'EnhancedOnboardingService',
        );
      } else {
        // Update the existing user profile
        userProfile.onboardingCompleted = true;

        // Initialize metadata if it doesn't exist
        userProfile.metadata ??= {};

        // Mark all steps as completed
        userProfile.metadata![_onboardingProgressKey] = onboardingSteps;
        userProfile.metadata![_onboardingLastScreenKey] = 'complete';

        // Save the updated profile
        await _userProfileBox.put('current', userProfile);

        // Verify the profile was updated
        var updatedProfile = _userProfileBox.get('current');
        if (updatedProfile == null || !updatedProfile.onboardingCompleted) {
          appLogger.error(
            'Failed to update user profile with onboardingCompleted: true',
            'EnhancedOnboardingService',
          );
          throw Exception('Failed to update user profile');
        }

        appLogger.info(
          'Onboarding completed successfully',
          'EnhancedOnboardingService',
        );
      }

      // Mark the complete step as completed
      await markStepCompleted('complete');
    } catch (e) {
      appLogger.error(
        'Error completing onboarding: $e',
        'EnhancedOnboardingService',
      );
      rethrow;
    }
  }

  /// Skip the onboarding process
  Future<void> skipOnboarding() async {
    try {
      appLogger.info('Skipping onboarding', 'EnhancedOnboardingService');

      // Ensure the box is open and writable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        throw Exception('UserProfile box is not open');
      }

      // Get the current user profile or create a new one if it doesn't exist
      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        // Create a new user profile if it doesn't exist
        appLogger.warning(
          'User profile not found, creating a new one',
          'EnhancedOnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: true,
          metadata: {
            _onboardingProgressKey: onboardingSteps,
            _onboardingLastScreenKey: 'complete',
            _tutorialCompletedKey: true,
          },
        );

        // Save the new profile
        await _userProfileBox.put('current', userProfile);
      } else {
        // Update the existing user profile
        userProfile.onboardingCompleted = true;

        // Initialize metadata if it doesn't exist
        userProfile.metadata ??= {};

        // Mark all steps as completed
        userProfile.metadata![_onboardingProgressKey] = onboardingSteps;
        userProfile.metadata![_onboardingLastScreenKey] = 'complete';
        userProfile.metadata![_tutorialCompletedKey] = true;

        // Save the updated profile
        await _userProfileBox.put('current', userProfile);
      }

      appLogger.info(
        'Onboarding skipped successfully',
        'EnhancedOnboardingService',
      );
    } catch (e) {
      appLogger.error(
        'Error skipping onboarding: $e',
        'EnhancedOnboardingService',
      );
      rethrow;
    }
  }

  /// Get the current user profile
  UserProfile getCurrentUserProfile() {
    try {
      appLogger.info(
        'Getting current user profile',
        'EnhancedOnboardingService',
      );

      // Ensure the box is open and readable
      if (!_userProfileBox.isOpen) {
        appLogger.error(
          'UserProfile box is not open',
          'EnhancedOnboardingService',
        );
        throw Exception('UserProfile box is not open');
      }

      var userProfile = _userProfileBox.get('current');

      if (userProfile == null) {
        // Create a new user profile if it doesn't exist
        appLogger.warning(
          'User profile not found, creating a new one',
          'EnhancedOnboardingService',
        );
        userProfile = UserProfile(
          name: 'User',
          email: 'user@example.com',
          goal: null,
          onboardingCompleted: false,
          metadata: {},
        );

        // Save the new profile
        _userProfileBox.put('current', userProfile);

        // Verify the profile was saved
        var savedProfile = _userProfileBox.get('current');
        if (savedProfile == null) {
          appLogger.error(
            'Failed to save new user profile',
            'EnhancedOnboardingService',
          );
          throw Exception('Failed to save user profile');
        }

        appLogger.info('Created new user profile', 'EnhancedOnboardingService');
      }

      appLogger.info(
        'Retrieved user profile: name=${userProfile.name}, goal=${userProfile.goal}, onboardingCompleted=${userProfile.onboardingCompleted}',
        'EnhancedOnboardingService',
      );
      return userProfile;
    } catch (e) {
      appLogger.error(
        'Error getting user profile: $e',
        'EnhancedOnboardingService',
      );
      // Create a default profile in case of error
      return UserProfile(
        name: 'User',
        email: 'user@example.com',
        goal: null,
        onboardingCompleted: false,
        metadata: {},
      );
    }
  }
}

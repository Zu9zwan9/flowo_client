import 'package:flutter/services.dart';

/// Haptic feedback service that provides reusable haptic feedback methods
/// following Clean Architecture principles.
class HapticService {
  // Private constructor for singleton pattern
  HapticService._();

  // Singleton instance
  static final HapticService _instance = HapticService._();

  // Factory constructor to return the singleton instance
  factory HapticService() => _instance;

  /// Provides light impact haptic feedback
  /// Use for subtle interactions like:
  /// - Selecting an item in a list
  /// - Toggling a switch
  /// - Completing a minor action
  Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Provides medium impact haptic feedback
  /// Use for standard interactions like:
  /// - Pressing a button
  /// - Completing a form
  /// - Confirming an action
  Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Provides heavy impact haptic feedback
  /// Use for significant interactions like:
  /// - Completing a major action
  /// - Error states
  /// - Important notifications
  Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Provides selection click haptic feedback
  /// Use for selection interactions like:
  /// - Selecting an item in a picker
  /// - Selecting a date
  /// - Selecting an option in a menu
  Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Provides vibration haptic feedback
  /// Use for custom patterns or when other feedback types don't fit
  Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Provides haptic feedback for button press
  /// Standardized feedback for button interactions
  Future<void> buttonPress() async {
    await mediumImpact();
  }

  /// Provides haptic feedback for success actions
  /// Use when an action completes successfully
  Future<void> success() async {
    await lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await mediumImpact();
  }

  /// Provides haptic feedback for error actions
  /// Use when an action fails or an error occurs
  Future<void> error() async {
    await heavyImpact();
  }

  /// Provides haptic feedback for warning actions
  /// Use for warning states or confirmations of destructive actions
  Future<void> warning() async {
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await mediumImpact();
  }
}

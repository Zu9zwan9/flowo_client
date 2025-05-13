import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

class HapticService {
  // Private constructor for singleton pattern
  HapticService._();

  // Singleton instance
  static final HapticService _instance = HapticService._();

  // Factory constructor to return the singleton instance
  factory HapticService() => _instance;

  // Flag to enable/disable haptic feedback globally
  bool _hapticsEnabled = true;

  /// Gets the current haptics enabled state
  bool get isEnabled => _hapticsEnabled;

  /// Enables or disables haptic feedback globally
  void setEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  /// Provides light impact haptic feedback
  /// Use for subtle interactions like:
  /// - Selecting an item in a list
  /// - Toggling a switch
  /// - Completing a minor action
  Future<void> lightImpact() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Provides medium impact haptic feedback
  /// Use for standard interactions like:
  /// - Pressing a button
  /// - Completing a form
  /// - Confirming an action
  Future<void> mediumImpact() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Provides heavy impact haptic feedback
  /// Use for significant interactions like:
  /// - Completing a major action
  /// - Error states
  /// - Important notifications
  Future<void> heavyImpact() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Provides selection click haptic feedback
  /// Use for selection interactions like:
  /// - Selecting an item in a picker
  /// - Selecting a date
  /// - Selecting an option in a menu
  Future<void> selectionClick() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Provides vibration haptic feedback
  /// Use for custom patterns or when other feedback types don't fit
  Future<void> vibrate() async {
    if (!_hapticsEnabled) return;
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
    if (!_hapticsEnabled) return;
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
    if (!_hapticsEnabled) return;
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await mediumImpact();
  }

  /// Plays a custom pattern of haptic feedback
  /// @param pattern A list of tuples with feedback type and delay in milliseconds
  /// Example: [('light', 100), ('medium', 200), ('heavy', 0)]
  Future<void> playPattern(
    List<({String type, int delayAfter})> pattern,
  ) async {
    if (!_hapticsEnabled) return;

    for (final step in pattern) {
      switch (step.type) {
        case 'light':
          await lightImpact();
        case 'medium':
          await mediumImpact();
        case 'heavy':
          await heavyImpact();
        case 'selection':
          await selectionClick();
        case 'vibrate':
          await vibrate();
      }

      if (step.delayAfter > 0) {
        await Future.delayed(Duration(milliseconds: step.delayAfter));
      }
    }
  }

  /// Provides synchronized haptic feedback with animation
  /// Use to create a cohesive experience between animations and haptics
  Future<void Function()> synchronizedWithAnimation({
    required AnimationController controller,
    required List<({double animationValue, String hapticType})> hapticPoints,
  }) async {
    if (!_hapticsEnabled) return () {};

    // We need to listen to animation value changes
    void listener() {
      for (final point in hapticPoints) {
        if ((controller.value - point.animationValue).abs() < 0.01) {
          switch (point.hapticType) {
            case 'light':
              lightImpact();
            case 'medium':
              mediumImpact();
            case 'heavy':
              heavyImpact();
            case 'selection':
              selectionClick();
          }
          break;
        }
      }
    }

    controller.addListener(listener);

    // Return a function to clean up the listener when done
    return () => controller.removeListener(listener);
  }
}

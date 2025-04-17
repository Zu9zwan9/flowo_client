import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A platform-aware slider that uses [CupertinoSlider] on iOS and [Slider] on Android.
/// This ensures sliders work correctly on both platforms.
class PlatformAwareSlider extends StatelessWidget {
  /// The current value of the slider.
  final double value;

  /// The minimum value the user can select.
  final double min;

  /// The maximum value the user can select.
  final double max;

  /// Called when the user selects a new value for the slider.
  final ValueChanged<double>? onChanged;

  /// The number of discrete divisions.
  final int? divisions;

  /// The color to use for the active portion of the slider.
  final Color? activeColor;

  /// The color to use for the thumb.
  final Color? thumbColor;

  /// The color to use for the inactive portion of the slider.
  final Color? inactiveColor;

  /// Creates a platform-aware slider.
  const PlatformAwareSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.activeColor,
    this.thumbColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    // Use CupertinoSlider on iOS and Slider on Android
    if (Platform.isIOS) {
      return CupertinoSlider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
        divisions: divisions,
        activeColor: activeColor,
      );
    } else {
      // For Android and other platforms, use Material's Slider
      return Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
        divisions: divisions,
        activeColor: activeColor,
        thumbColor: thumbColor,
        inactiveColor: inactiveColor,
      );
    }
  }
}

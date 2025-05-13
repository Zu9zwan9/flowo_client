import 'package:flutter/cupertino.dart';

import '../haptics/haptic_service.dart';
import 'base_animated_widget.dart';

class CupertinoAnimatedButton extends BaseAnimatedWidget {
  /// The child widget to display inside the button.
  final Widget child;

  /// The callback to execute when the button is pressed.
  final VoidCallback onPressed;

  /// The background color of the button.
  final Color? backgroundColor;

  /// The border radius of the button.
  final double borderRadius;

  /// The padding inside the button.
  final EdgeInsetsGeometry padding;

  /// Whether the button is disabled.
  final bool isDisabled;

  /// The type of haptic feedback to provide when the button is pressed.
  final HapticFeedbackType hapticFeedbackType;

  /// Creates a Cupertino-style animated button.
  const CupertinoAnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.borderRadius = 10.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.isDisabled = false,
    this.hapticFeedbackType = HapticFeedbackType.medium,
  });

  @override
  State<CupertinoAnimatedButton> createState() =>
      _CupertinoAnimatedButtonState();
}

/// The state for the CupertinoAnimatedButton widget.
class _CupertinoAnimatedButtonState
    extends BaseAnimatedWidgetState<CupertinoAnimatedButton> {
  final HapticService _hapticService = HapticService();

  @override
  Widget build(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    final effectiveBackgroundColor = widget.backgroundColor ?? primaryColor;

    final color =
        widget.isDisabled
            ? effectiveBackgroundColor.withOpacity(0.5)
            : effectiveBackgroundColor;

    return GestureDetector(
      onTap: widget.isDisabled ? null : _handleTap,
      child: applyScaleAnimation(
        Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        ),
      ),
    );
  }

  /// Handles the tap gesture with appropriate haptic feedback.
  void _handleTap() {
    // Provide haptic feedback based on the specified type
    switch (widget.hapticFeedbackType) {
      case HapticFeedbackType.light:
        _hapticService.lightImpact();
        break;
      case HapticFeedbackType.medium:
        _hapticService.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        _hapticService.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        _hapticService.selectionClick();
        break;
      case HapticFeedbackType.success:
        _hapticService.success();
        break;
      case HapticFeedbackType.error:
        _hapticService.error();
        break;
      case HapticFeedbackType.warning:
        _hapticService.warning();
        break;
    }

    // Play the animation
    playTapAnimation();

    // Execute the callback
    widget.onPressed();
  }
}

/// Enum for different types of haptic feedback.
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  success,
  error,
  warning,
}

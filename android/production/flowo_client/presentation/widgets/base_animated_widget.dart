import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../animations/animation_service.dart';
import '../haptics/haptic_service.dart';

abstract class BaseAnimatedWidget extends StatefulWidget {
  const BaseAnimatedWidget({super.key});
}

/// Base state for animated widgets with common animation and haptic functionality.
abstract class BaseAnimatedWidgetState<T extends BaseAnimatedWidget>
    extends State<T>
    with SingleTickerProviderStateMixin {
  // Services
  final AnimationService _animationService = AnimationService();
  final HapticService _hapticService = HapticService();

  // Animation controller
  late AnimationController _animationController;

  // Animations
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = _animationService.createSpringScaleController(this);

    // Initialize scale animation
    _scaleAnimation = _animationService.createSpringScaleAnimation(
      _animationController,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Plays a tap animation with haptic feedback
  void playTapAnimation() {
    _hapticService.buttonPress();
    _animationController.forward().then((_) => _animationController.reverse());
  }

  /// Plays a success animation with haptic feedback
  void playSuccessAnimation() {
    _hapticService.success();
    _animationController.forward().then((_) => _animationController.reverse());
  }

  /// Plays an error animation with haptic feedback
  void playErrorAnimation() {
    _hapticService.error();
    _animationController.forward().then((_) => _animationController.reverse());
  }

  /// Applies scale animation to a child widget
  Widget applyScaleAnimation(Widget child) {
    return _animationService.applyScaleAnimation(
      child: child,
      animation: _scaleAnimation,
    );
  }

  /// Creates a glassmorphism effect container
  Widget createGlassmorphismContainer({
    required Widget child,
    Color color = const Color(0xFFFFFFFF),
    double opacity = 0.1,
    double blurRadius = 10.0,
    double borderRadius = 16.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
  }) {
    return Container(
      padding: padding,
      decoration: _animationService.createGlassmorphismEffect(
        color: color,
        opacity: opacity,
        blurRadius: blurRadius,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  /// Creates an animated button with haptic feedback
  Widget createAnimatedButton({
    required Widget child,
    required VoidCallback onPressed,
    Color backgroundColor = const Color(0xFF0A84FF),
    double borderRadius = 10.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 16,
    ),
  }) {
    return GestureDetector(
      onTap: () {
        playTapAnimation();
        onPressed();
      },
      child: applyScaleAnimation(
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}

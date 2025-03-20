import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Animation service that provides reusable animations for the app
/// following Clean Architecture principles.
class AnimationService {
  // Private constructor for singleton pattern
  AnimationService._();

  // Singleton instance
  static final AnimationService _instance = AnimationService._();

  // Factory constructor to return the singleton instance
  factory AnimationService() => _instance;

  /// Creates a scale animation controller with spring physics
  AnimationController createSpringScaleController(
    TickerProvider vsync, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimationController(vsync: vsync, duration: duration);
  }

  /// Creates a scale animation with spring curve
  Animation<double> createSpringScaleAnimation(
    AnimationController controller, {
    double begin = 1.0,
    double end = 0.95,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOutBack, // Spring-like curve
        reverseCurve: Curves.easeInOutBack,
      ),
    );
  }

  /// Creates a fade animation with smooth curve
  Animation<double> createFadeAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// Creates a slide animation with smooth curve
  Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0.0, 0.2),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }

  /// Creates a glassmorphism effect decoration
  BoxDecoration createGlassmorphismEffect({
    Color color = const Color(0xFFFFFFFF),
    double opacity = 0.1,
    double blurRadius = 10.0,
    double borderRadius = 16.0,
    Color borderColor = const Color(0x20FFFFFF),
  }) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.05),
          blurRadius: blurRadius,
          spreadRadius: 1.0,
        ),
      ],
    );
  }

  /// Applies a scale animation to a widget
  Widget applyScaleAnimation({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(scale: animation, child: child);
  }

  /// Applies a fade animation to a widget
  Widget applyFadeAnimation({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(opacity: animation, child: child);
  }

  /// Applies a slide animation to a widget
  Widget applySlideAnimation({
    required Widget child,
    required Animation<Offset> animation,
  }) {
    return SlideTransition(position: animation, child: child);
  }

  /// Applies a combined fade and slide animation to a widget
  Widget applyFadeSlideAnimation({
    required Widget child,
    required Animation<double> fadeAnimation,
    required Animation<Offset> slideAnimation,
  }) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}

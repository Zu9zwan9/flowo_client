import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'base_animated_widget.dart';

/// A container with glassmorphism effect following Apple's design guidelines.
/// This widget provides a frosted glass effect with smooth animations.
class GlassmorphicContainer extends BaseAnimatedWidget {
  /// The child widget to display inside the container.
  final Widget child;

  /// The background color of the container.
  final Color? backgroundColor;

  /// The border radius of the container.
  final double borderRadius;

  /// The blur intensity of the glassmorphism effect.
  final double blurIntensity;

  /// The opacity of the background color.
  final double opacity;

  /// The padding inside the container.
  final EdgeInsetsGeometry padding;

  /// Whether to animate the container on appearance.
  final bool animateOnAppear;

  /// Creates a container with glassmorphism effect.
  const GlassmorphicContainer({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.borderRadius = 16.0,
    this.blurIntensity = 10.0,
    this.opacity = 0.1,
    this.padding = const EdgeInsets.all(16.0),
    this.animateOnAppear = true,
  }) : super(key: key);

  @override
  State<GlassmorphicContainer> createState() => _GlassmorphicContainerState();
}

/// The state for the GlassmorphicContainer widget.
class _GlassmorphicContainerState
    extends BaseAnimatedWidgetState<GlassmorphicContainer> {
  // Animation controller for appearance
  late AnimationController _animationController;

  // Animation for appearance
  late Animation<double> _appearAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize appearance animation
    _appearAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Play appearance animation if requested
    if (widget.animateOnAppear) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the background color from the Cupertino theme or use the provided one
    final effectiveBackgroundColor =
        widget.backgroundColor ??
        CupertinoTheme.of(context).scaffoldBackgroundColor;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animateOnAppear ? _appearAnimation.value : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurIntensity,
                sigmaY: widget.blurIntensity,
              ),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: effectiveBackgroundColor.withOpacity(widget.opacity),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: effectiveBackgroundColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveBackgroundColor.withOpacity(0.05),
                      blurRadius: widget.blurIntensity,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

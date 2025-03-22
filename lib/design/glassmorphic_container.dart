import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../theme_notifier.dart';

/// A container with enhanced glassmorphic effect following Apple's Human Interface Guidelines.
///
/// This widget creates a frosted glass effect with customizable properties like
/// blur intensity, opacity, border radius, and border width.
/// It adapts to the current theme (light/dark) automatically, supports animations,
/// and includes vibrant color accents and gradient options.
class GlassmorphicContainer extends StatefulWidget {
  /// The child widget to be displayed inside the container.
  final Widget child;

  /// The width of the container.
  final double? width;

  /// The height of the container.
  final double? height;

  /// The border radius of the container.
  final BorderRadius? borderRadius;

  /// The blur intensity of the glassmorphic effect.
  final double? blur;

  /// The opacity of the background color.
  final double? opacity;

  /// The border width of the container.
  final double? borderWidth;

  /// The border color of the container.
  final Color? borderColor;

  /// The background color of the container.
  /// If null, it will use the system background color with opacity.
  final Color? backgroundColor;

  /// Whether to use a gradient background instead of a solid color.
  final bool useGradient;

  /// Custom gradient colors to use if useGradient is true.
  final List<Color>? gradientColors;

  /// The accent color for highlights and special elements.
  final Color? accentColor;

  /// The padding inside the container.
  final EdgeInsetsGeometry? padding;

  /// Whether to animate the container on appearance.
  final bool animateOnAppear;

  /// The duration of the appearance animation.
  final Duration animationDuration;

  /// Whether to show a subtle shimmer effect.
  final bool showShimmer;

  /// Creates a glassmorphic container.
  const GlassmorphicContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.blur,
    this.opacity,
    this.borderWidth,
    this.borderColor,
    this.backgroundColor,
    this.useGradient = false,
    this.gradientColors,
    this.accentColor,
    this.padding,
    this.animateOnAppear = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showShimmer = false,
  }) : super(key: key);

  @override
  State<GlassmorphicContainer> createState() => _GlassmorphicContainerState();
}

class _GlassmorphicContainerState extends State<GlassmorphicContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _appearAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Initialize appearance animation
    _appearAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Initialize shimmer animation
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Play appearance animation if requested
    if (widget.animateOnAppear) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }

    // If shimmer effect is enabled, repeat the animation
    if (widget.showShimmer) {
      _animationController.repeat(period: const Duration(seconds: 2));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Get theme values or use defaults
    final effectiveBorderRadius =
        widget.borderRadius ?? glassmorphicTheme.defaultBorderRadius;
    final effectiveBlur = widget.blur ?? glassmorphicTheme.defaultBlur;
    final effectiveOpacity = widget.opacity ?? glassmorphicTheme.defaultOpacity;
    final effectiveBorderWidth =
        widget.borderWidth ?? glassmorphicTheme.defaultBorderWidth;

    // Determine colors based on theme
    final effectiveBorderColor =
        widget.borderColor ?? glassmorphicTheme.borderColor;
    final effectiveBackgroundColor =
        widget.backgroundColor ?? glassmorphicTheme.backgroundColor;
    final effectiveAccentColor =
        widget.accentColor ?? glassmorphicTheme.accentColor;
    final effectiveGradientColors =
        widget.gradientColors ?? glassmorphicTheme.gradientColors;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animateOnAppear ? _appearAnimation.value : 1.0,
          child: ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: effectiveBlur,
                sigmaY: effectiveBlur,
              ),
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: widget.padding,
                decoration: BoxDecoration(
                  gradient:
                      widget.useGradient
                          ? LinearGradient(
                            colors:
                                effectiveGradientColors
                                    .map(
                                      (color) =>
                                          color.withOpacity(effectiveOpacity),
                                    )
                                    .toList(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  color: widget.useGradient ? null : effectiveBackgroundColor,
                  borderRadius: effectiveBorderRadius,
                  border: Border.all(
                    color: effectiveBorderColor,
                    width: effectiveBorderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glassmorphicTheme.shadowColor.withOpacity(
                        glassmorphicTheme.shadowOpacity,
                      ),
                      blurRadius: glassmorphicTheme.shadowBlurRadius,
                      spreadRadius: glassmorphicTheme.shadowSpreadRadius,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    widget.child,
                    if (widget.showShimmer)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    effectiveAccentColor.withOpacity(0.0),
                                    effectiveAccentColor.withOpacity(0.1),
                                    effectiveAccentColor.withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  begin: Alignment(
                                    -1.0 + _shimmerAnimation.value * 2,
                                    0.0,
                                  ),
                                  end: Alignment(
                                    1.0 + _shimmerAnimation.value * 2,
                                    0.0,
                                  ),
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: Container(color: CupertinoColors.white),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A glassmorphic card widget that extends GlassmorphicContainer with predefined
/// padding and styling suitable for cards.
class GlassmorphicCard extends StatelessWidget {
  /// The child widget to be displayed inside the card.
  final Widget child;

  /// The width of the card.
  final double? width;

  /// The height of the card.
  final double? height;

  /// The border radius of the card.
  final BorderRadius? borderRadius;

  /// The blur intensity of the glassmorphic effect.
  final double? blur;

  /// The opacity of the background color.
  final double? opacity;

  /// The border width of the card.
  final double? borderWidth;

  /// The border color of the card.
  final Color? borderColor;

  /// The background color of the card.
  final Color? backgroundColor;

  /// Whether to use a gradient background instead of a solid color.
  final bool useGradient;

  /// Custom gradient colors to use if useGradient is true.
  final List<Color>? gradientColors;

  /// The accent color for highlights and special elements.
  final Color? accentColor;

  /// The padding inside the card.
  final EdgeInsetsGeometry padding;

  /// Whether to animate the card on appearance.
  final bool animateOnAppear;

  /// Whether to show a subtle shimmer effect.
  final bool showShimmer;

  /// Creates a glassmorphic card.
  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.blur,
    this.opacity,
    this.borderWidth,
    this.borderColor,
    this.backgroundColor,
    this.useGradient = false,
    this.gradientColors,
    this.accentColor,
    this.padding = const EdgeInsets.all(16),
    this.animateOnAppear = true,
    this.showShimmer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: width,
      height: height,
      borderRadius: borderRadius,
      blur: blur,
      opacity: opacity,
      borderWidth: borderWidth,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      useGradient: useGradient,
      gradientColors: gradientColors,
      accentColor: accentColor,
      padding: padding,
      animateOnAppear: animateOnAppear,
      showShimmer: showShimmer,
      child: child,
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowo_client/theme/theme_notifier.dart';

/// A launch screen widget that displays an animated logo during app initialization.
/// This follows Apple's Human Interface Guidelines for iOS and Material Design for Android.
class LaunchScreen extends StatefulWidget {
  /// The widget to display after the launch animation completes.
  final Widget child;

  /// Duration of the entire launch animation.
  final Duration animationDuration;

  /// Duration to wait before starting the fade out animation.
  final Duration minimumDisplayDuration;

  const LaunchScreen({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.minimumDisplayDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _showLaunchScreen = true;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Create animations
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.5, // Half rotation (180 degrees)
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOutBack),
      ),
    );

    // Start animation after a short delay to allow the app to initialize
    Timer(widget.minimumDisplayDuration, () {
      _controller.forward().then((_) {
        setState(() {
          _showLaunchScreen = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme notifier to access dynamic colors
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.brightness == Brightness.dark;

    // Use dynamic colors from the theme
    final primaryColor = themeNotifier.primaryColor;
    final backgroundColor = themeNotifier.backgroundColor;

    // Create a gradient for the background
    final gradient = LinearGradient(
      colors: [
        backgroundColor,
        themeNotifier.useDynamicColors &&
                themeNotifier.dynamicColorPalette != null
            ? themeNotifier.getDynamicColor('secondary')
            : primaryColor.withOpacity(0.3),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return _showLaunchScreen
        ? AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(gradient: gradient),
              child: Center(
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Transform(
                      transform: Matrix4.diagonal3Values(
                        -1,
                        -1,
                        1,
                      ), // Mirror horizontally
                      alignment: Alignment.center,
                      child: RotationTransition(
                        turns: _rotationAnimation,
                        child: _buildLogo(primaryColor, isDarkMode),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        )
        : widget.child;
  }

  Widget _buildLogo(Color primaryColor, bool isDarkMode) {
    // Create a stylized "F" logo for Flowo with a more sophisticated design
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                primaryColor.withOpacity(0.5),
                primaryColor.withOpacity(0.0),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),

        // Main circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                HSLColor.fromColor(primaryColor)
                    .withLightness(
                      (HSLColor.fromColor(primaryColor).lightness + 0.2).clamp(
                        0.0,
                        1.0,
                      ),
                    )
                    .toColor(),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),

        // Inner highlight
        Positioned(
          top: 25,
          left: 25,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // App logo
        SizedBox(
          width: 80,
          height: 80,
          child: Image.asset(
            '/Users/mbard/Documents/01Projects/flowo_client/ios/Runner/Assets.xcassets/LaunchImage.imageset/app_icon.png',
            fit: BoxFit.contain,
          ),
        ),

        // Animated particles around the logo (small dots)
        ..._buildParticles(primaryColor),
      ],
    );
  }

  // Generate animated particles around the logo
  List<Widget> _buildParticles(Color color) {
    final random = math.Random();
    final particles = <Widget>[];

    // Create 12 particles with different positions and animations
    for (int i = 0; i < 12; i++) {
      final size = random.nextDouble() * 6 + 2; // Random size between 2 and 8
      final angle = i * (math.pi * 2 / 12); // Evenly distribute around circle
      final radius = 80.0 + random.nextDouble() * 40; // Random radius
      final delay = random.nextDouble() * 0.5; // Random delay for animation

      // Calculate position based on angle and radius
      final dx = math.cos(angle) * radius;
      final dy = math.sin(angle) * radius;

      // Create animated particle
      particles.add(
        Positioned(
          left:
              60 + dx - (size / 2), // Center relative to the 120x120 container
          top: 60 + dy - (size / 2),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000 + (delay * 1000).round()),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              // Fade in and pulse
              return Opacity(
                opacity: math.sin(value * math.pi * 2) * 0.5 + 0.5,
                child: Container(
                  width: size * (0.8 + math.sin(value * math.pi * 3) * 0.2),
                  height: size * (0.8 + math.sin(value * math.pi * 3) * 0.2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.7),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 3,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return particles;
  }
}

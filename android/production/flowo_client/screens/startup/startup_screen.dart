import 'dart:async';

import 'package:flowo_client/services/onboarding_service.dart';
import 'package:flowo_client/services/startup_service.dart';
import 'package:flowo_client/theme_notifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// A beautiful startup screen that follows Apple's Human Interface Guidelines
/// and uses dynamic colors based on the system color.
class StartupScreen extends StatefulWidget {
  const StartupScreen({Key? key}) : super(key: key);

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Configure animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Navigate to the appropriate screen after a delay
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for animation to complete and add a small delay
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Get the onboarding service
    final onboardingService = Provider.of<OnboardingService>(
      context,
      listen: false,
    );

    // Create a startup service
    final startupService = StartupService(onboardingService);

    // Use the startup service to navigate to the appropriate screen
    await startupService.navigateToAppropriateScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme from the provider
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.brightness == Brightness.dark;

    // Get colors from the theme
    final primaryColor = themeNotifier.primaryColor;
    final backgroundColor = themeNotifier.backgroundColor;
    final textColor = themeNotifier.textColor;

    // Create a startup service to calculate gradient colors
    final onboardingService = Provider.of<OnboardingService>(
      context,
      listen: false,
    );
    final startupService = StartupService(onboardingService);

    // Get gradient colors from the startup service
    final gradientColors = startupService.calculateGradientColors(primaryColor);
    final gradientStartColor = gradientColors[0];
    final gradientEndColor = gradientColors[1];

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App logo with dynamic colors
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [gradientStartColor, gradientEndColor],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.calendar_today,
                              color: CupertinoColors.white,
                              size: 60,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // App name
                        Text(
                          'Flowo',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // App tagline
                        Text(
                          'Your personal productivity assistant',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 18,
                            color:
                                isDarkMode
                                    ? CupertinoColors.systemGrey.darkColor
                                    : CupertinoColors.systemGrey,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Loading indicator
                        CupertinoActivityIndicator(
                          radius: 14,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

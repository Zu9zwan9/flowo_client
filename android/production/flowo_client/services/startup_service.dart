import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/screens/onboarding/onboarding_wrapper.dart';
import 'package:flowo_client/services/onboarding_service.dart';

/// Service class responsible for handling startup logic
/// Follows Single Responsibility Principle by separating UI from business logic
class StartupService {
  final OnboardingService _onboardingService;

  /// Constructor that takes an OnboardingService dependency
  /// Following Dependency Inversion Principle by depending on abstractions
  StartupService(this._onboardingService);

  /// Checks if onboarding is completed
  bool isOnboardingCompleted() {
    return _onboardingService.isOnboardingCompleted();
  }

  /// Navigates to the appropriate screen based on onboarding status
  /// Returns a Future that completes when navigation is done
  Future<void> navigateToAppropriateScreen(BuildContext context) async {
    // Provide haptic feedback when transitioning
    HapticFeedback.lightImpact();
    
    // Check if onboarding is completed
    final isOnboardingCompleted = _onboardingService.isOnboardingCompleted();
    
    // Navigate to the appropriate screen
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => isOnboardingCompleted 
            ? const HomeScreen() 
            : const OnboardingWrapper(),
      ),
    );
  }
  
  /// Calculates gradient colors based on a primary color
  /// This is a pure function with no side effects
  List<Color> calculateGradientColors(Color primaryColor) {
    final gradientStartColor = HSLColor.fromColor(primaryColor)
        .withLightness((HSLColor.fromColor(primaryColor).lightness * 1.2).clamp(0.0, 1.0))
        .toColor();
    final gradientEndColor = primaryColor;
    
    return [gradientStartColor, gradientEndColor];
  }
}

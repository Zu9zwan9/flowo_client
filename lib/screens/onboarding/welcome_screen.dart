import 'package:flowo_client/design/glassmorphic_container.dart';
import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/services/onboarding_service.dart';
import 'package:flowo_client/theme_notifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Final screen of the onboarding process that shows a personalized welcome message
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final onboardingService = Provider.of<OnboardingService>(
      context,
      listen: false,
    );
    final userProfile = onboardingService.getCurrentUserProfile();

    if (mounted) {
      setState(() {
        _userProfile = userProfile;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Mark onboarding as completed
      final onboardingService = Provider.of<OnboardingService>(
        context,
        listen: false,
      );
      await onboardingService.completeOnboarding();

      if (mounted) {
        // Navigate to the home screen and remove all previous screens from the stack
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to complete onboarding. Please try again.');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final primaryColor = theme.primaryColor;
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    final userName = _userProfile?.name ?? 'there';
    final userGoal = _userProfile?.goal ?? 'your goals';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Back',
        middle: const Text('Welcome'),
        backgroundColor: theme.barBackgroundColor.withOpacity(0.8),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Celebration icon with glassmorphic effect
              Center(
                child: GlassmorphicContainer(
                  width: 100,
                  height: 100,
                  borderRadius: BorderRadius.circular(25),
                  blur: glassmorphicTheme.defaultBlur,
                  opacity: 0.3, // Slightly more opaque for the icon
                  borderWidth: glassmorphicTheme.defaultBorderWidth,
                  borderColor: primaryColor.withOpacity(0.3),
                  backgroundColor: primaryColor.withOpacity(0.2),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.star_fill,
                      color: CupertinoColors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Welcome message in a glassmorphic card
              GlassmorphicCard(
                borderRadius: BorderRadius.circular(16),
                blur: glassmorphicTheme.defaultBlur,
                opacity: glassmorphicTheme.defaultOpacity,
                borderWidth: glassmorphicTheme.defaultBorderWidth,
                child: Column(
                  children: [
                    // Welcome message
                    Text(
                      'Hello, $userName!',
                      style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Personalized message
                    Text(
                      'With your efforts and this app, your dream to "$userGoal" will come true.',
                      style: theme.textTheme.textStyle.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Motivational message
                    Text(
                      'We\'re excited to help you on your journey!',
                      style: theme.textTheme.textStyle.copyWith(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Get started button with glassmorphic effect
              GestureDetector(
                onTap: _isLoading ? null : _completeOnboarding,
                child: GlassmorphicContainer(
                  height: 56,
                  borderRadius: BorderRadius.circular(12),
                  blur: glassmorphicTheme.defaultBlur,
                  opacity: 0.3, // More opaque for button
                  borderWidth: glassmorphicTheme.defaultBorderWidth,
                  borderColor: primaryColor.withOpacity(0.5),
                  backgroundColor: primaryColor.withOpacity(0.3),
                  child: Center(
                    child:
                        _isLoading
                            ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                            : const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Footer in a subtle glassmorphic container
              GlassmorphicContainer(
                height: 40,
                borderRadius: BorderRadius.circular(8),
                blur: glassmorphicTheme.defaultBlur,
                opacity: 0.1, // Very subtle for footer
                borderWidth: 0.5, // Thinner border for footer
                child: Center(
                  child: Text(
                    'FLOWO 1.0.0',
                    style: theme.textTheme.tabLabelTextStyle.copyWith(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

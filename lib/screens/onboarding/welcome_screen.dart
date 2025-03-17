import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/services/onboarding_service.dart';
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
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;

    final userName = _userProfile?.name ?? 'there';
    final userGoal = _userProfile?.goal ?? 'your goals';

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Back',
        middle: Text('Welcome'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Celebration icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemIndigo,
                    borderRadius: BorderRadius.circular(25),
                  ),
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
              // Welcome message
              Center(
                child: Text(
                  'Hello, $userName!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Personalized message
              Center(
                child: Text(
                  'With your efforts and this app, your dream to "$userGoal" will come true.',
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        isDarkMode
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Motivational message
              Center(
                child: Text(
                  'We\'re excited to help you on your journey!',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDarkMode
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Get started button
              CupertinoButton(
                onPressed: _completeOnboarding,
                color: CupertinoColors.systemIndigo,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child:
                    _isLoading
                        ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                        : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
              ),
              const SizedBox(height: 16),
              // Footer
              Center(
                child: Text(
                  'FLOWO 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDarkMode
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey,
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

import 'package:flowo_client/screens/onboarding/enhanced/name_input_screen.dart';
import 'package:flowo_client/screens/onboarding/enhanced/task_intro_screen.dart';
import 'package:flowo_client/services/onboarding/enhanced_onboarding_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Enhanced welcome screen for the onboarding process
class EnhancedWelcomeScreen extends StatefulWidget {
  final bool skipNameGoal;
  const EnhancedWelcomeScreen({super.key, this.skipNameGoal = false});

  @override
  State<EnhancedWelcomeScreen> createState() => _EnhancedWelcomeScreenState();
}

class _EnhancedWelcomeScreenState extends State<EnhancedWelcomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _markStepCompleted();
  }

  Future<void> _markStepCompleted() async {
    final onboardingService = Provider.of<EnhancedOnboardingService>(
      context,
      listen: false,
    );
    await onboardingService.markStepCompleted('welcome');
  }

  Future<void> _continueOnboarding() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      if (mounted) {
        // Navigate to next screen: skip name and goal if flag is set
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => widget.skipNameGoal
                ? const TaskIntroScreen()
                : const EnhancedNameInputScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _skipOnboarding() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Skip onboarding
      final onboardingService = Provider.of<EnhancedOnboardingService>(
        context,
        listen: false,
      );
      await onboardingService.skipOnboarding();

      if (mounted) {
        // Navigate to the home screen and remove all previous screens from the stack
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to skip onboarding. Please try again.');
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

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // App logo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.calendar_today,
                      color: CupertinoColors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App name
              Center(
                child: Text(
                  'Flowo',
                  style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                    fontSize: 36,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // App tagline
              Center(
                child: Text(
                  'Your personal productivity assistant',
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 18,
                    color: CupertinoColors.systemGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 60),
              // Welcome message
              Text(
                'Welcome to Flowo!',
                style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                'Flowo helps you manage tasks, track habits, and boost your productivity with powerful features designed to help you achieve your goals.',
                style: theme.textTheme.textStyle.copyWith(
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s set up your personalized experience in just a few steps.',
                style: theme.textTheme.textStyle.copyWith(
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  EnhancedOnboardingService.onboardingSteps.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          index == 0
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Continue button
              CupertinoButton(
                onPressed: _continueOnboarding,
                color: CupertinoColors.activeBlue,
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
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
              ),
              const SizedBox(height: 16),
              // Skip button
              CupertinoButton(
                onPressed: _skipOnboarding,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Skip Onboarding',
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
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

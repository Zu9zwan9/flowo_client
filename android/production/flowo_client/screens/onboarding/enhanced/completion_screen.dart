import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/services/onboarding/enhanced_onboarding_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Completion screen for the enhanced onboarding process
class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  bool _isLoading = false;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _markStepCompleted();
    _loadUserProfile();
  }

  Future<void> _markStepCompleted() async {
    final onboardingService = Provider.of<EnhancedOnboardingService>(
      context,
      listen: false,
    );
    await onboardingService.markStepCompleted('complete');
  }

  Future<void> _loadUserProfile() async {
    final onboardingService = Provider.of<EnhancedOnboardingService>(
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
      final onboardingService = Provider.of<EnhancedOnboardingService>(
        context,
        listen: false,
      );
      await onboardingService.completeOnboarding();

      if (mounted) {
        // Navigate to the home screen and remove all previous screens from the stack
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(
            builder: (context) => const HomeScreen(initialExpanded: false),
          ),
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
    final userName = _userProfile?.name ?? 'there';
    final userGoal = _userProfile?.goal ?? 'your goals';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Analytics',
        middle: const Text('All Set!'),
        backgroundColor: theme.barBackgroundColor.withOpacity(0.8),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
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
                        CupertinoIcons.star_fill,
                        color: CupertinoColors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Congratulations message
                Text(
                  'You\'re Ready to Go!',
                  style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Personalized message
                Text(
                  'Hello, $userName!',
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'re all set to start using Flowo to achieve "$userGoal".',
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Features summary
                _buildFeatureSummary(
                  context,
                  title: 'What You\'ve Learned',
                  items: [
                    'Task Management - Create and organize your tasks',
                    'Calendar & Events - Plan your schedule efficiently',
                    'Analytics & Insights - Track your productivity',
                  ],
                ),
                const SizedBox(height: 24),
                // Tips for getting started
                _buildFeatureSummary(
                  context,
                  title: 'Tips for Getting Started',
                  items: [
                    'Create your first task on the Tasks screen',
                    'Schedule your day using the Calendar',
                    'Check your progress in the Analytics section',
                    'Customize your experience in Settings',
                  ],
                ),
                const SizedBox(height: 40),
                // Progress indicator (all filled)
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
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                ),
                const SizedBox(height: 16),
                // Motivational message
                Center(
                  child: Text(
                    'We\'re excited to help you on your journey!',
                    style: theme.textTheme.textStyle.copyWith(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSummary(
    BuildContext context, {
    required String title,
    required List<String> items,
  }) {
    final theme = CupertinoTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.textStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: CupertinoColors.activeGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.textStyle.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

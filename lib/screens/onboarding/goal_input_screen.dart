import 'package:flowo_client/design/glassmorphic_container.dart';
import 'package:flowo_client/screens/onboarding/welcome_screen.dart';
import 'package:flowo_client/services/onboarding_service.dart';
import 'package:flowo_client/theme_notifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Second screen of the onboarding process that asks for the user's goal
class GoalInputScreen extends StatefulWidget {
  const GoalInputScreen({super.key});

  @override
  State<GoalInputScreen> createState() => _GoalInputScreenState();
}

class _GoalInputScreenState extends State<GoalInputScreen> {
  final TextEditingController _goalController = TextEditingController();
  bool _isGoalValid = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _goalController.addListener(_validateGoal);
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _validateGoal() {
    setState(() {
      _isGoalValid = _goalController.text.trim().isNotEmpty;
    });
  }

  Future<void> _submitGoal() async {
    if (!_isGoalValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Save the goal
      final onboardingService = Provider.of<OnboardingService>(
        context,
        listen: false,
      );
      await onboardingService.saveUserGoal(_goalController.text.trim());

      if (mounted) {
        // Navigate to the welcome screen
        Navigator.of(
          context,
        ).push(CupertinoPageRoute(builder: (context) => const WelcomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        // Show a more user-friendly error message with a hint
        _showErrorDialog(
          'Failed to save your goal. Please try again.\n\n'
          'If this issue persists, try restarting the app or check your internet connection.',
        );

        // Log the error for debugging
        if (kDebugMode) {
          print('[DEBUG_LOG] Error saving goal: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
    final primaryColor =
        CupertinoColors.activeGreen; // Use green for this screen
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Back',
        middle: const Text('Your Goal'),
        backgroundColor: theme.barBackgroundColor.withOpacity(0.8),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Goal icon with glassmorphic effect
              Center(
                child: GlassmorphicContainer(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(20),
                  blur: glassmorphicTheme.defaultBlur,
                  opacity: 0.3, // Slightly more opaque for the icon
                  borderWidth: glassmorphicTheme.defaultBorderWidth,
                  borderColor: primaryColor.withOpacity(0.3),
                  backgroundColor: primaryColor.withOpacity(0.2),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.flag_fill,
                      color: CupertinoColors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Goal question and description in a glassmorphic card
              GlassmorphicCard(
                borderRadius: BorderRadius.circular(16),
                blur: glassmorphicTheme.defaultBlur,
                opacity: glassmorphicTheme.defaultOpacity,
                borderWidth: glassmorphicTheme.defaultBorderWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal question
                    Text(
                      'What\'s your main goal?',
                      style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Goal description
                    Text(
                      'This will help us personalize your experience.',
                      style: theme.textTheme.textStyle.copyWith(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Goal input field with glassmorphic effect
                    GlassmorphicContainer(
                      borderRadius: BorderRadius.circular(12),
                      blur: glassmorphicTheme.defaultBlur,
                      opacity: 0.1, // More transparent for input field
                      borderWidth: 1.0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: CupertinoTextField(
                        controller: _goalController,
                        placeholder:
                            'e.g., Improve productivity, Learn a new skill',
                        padding: const EdgeInsets.all(16),
                        clearButtonMode: OverlayVisibilityMode.editing,
                        maxLines: 3,
                        decoration: null, // Remove default decoration
                        style: theme.textTheme.textStyle,
                        placeholderStyle: theme.textTheme.textStyle.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Continue button with glassmorphic effect
              GestureDetector(
                onTap: _isGoalValid && !_isSubmitting ? _submitGoal : null,
                child: GlassmorphicContainer(
                  height: 56,
                  borderRadius: BorderRadius.circular(12),
                  blur: glassmorphicTheme.defaultBlur,
                  opacity: _isGoalValid ? 0.3 : 0.1, // More opaque when enabled
                  borderWidth: glassmorphicTheme.defaultBorderWidth,
                  borderColor:
                      _isGoalValid
                          ? primaryColor.withOpacity(0.5)
                          : CupertinoColors.systemGrey4.withOpacity(0.3),
                  backgroundColor:
                      _isGoalValid
                          ? primaryColor.withOpacity(0.3)
                          : CupertinoColors.systemGrey4.withOpacity(0.1),
                  child: Center(
                    child:
                        _isSubmitting
                            ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                            : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                  ),
                ),
              ),
              const Spacer(),
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

import 'package:flowo_client/screens/onboarding/welcome_screen.dart';
import 'package:flowo_client/services/onboarding/onboarding_service.dart';
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
    _goalController.addListener(_hideKeyboardOnDone);
  }

  @override
  void dispose() {
    _goalController.removeListener(_validateGoal);
    _goalController.removeListener(_hideKeyboardOnDone);
    _goalController.dispose();
    super.dispose();
  }

  void _validateGoal() {
    setState(() {
      _isGoalValid = _goalController.text.trim().isNotEmpty;
    });
  }

  void _hideKeyboardOnDone() {
    if (_goalController.text.endsWith('\n')) {
      FocusScope.of(context).unfocus();
    }
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

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Back',
        middle: const Text('Your Goal'),
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
                // Goal icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen,
                      borderRadius: BorderRadius.circular(20),
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
                        CupertinoIcons.flag_fill,
                        color: CupertinoColors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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
                // Goal input field
                CupertinoTextField(
                  controller: _goalController,
                  placeholder: 'e.g., Improve productivity, Learn a new skill',
                  padding: const EdgeInsets.all(16),
                  clearButtonMode: OverlayVisibilityMode.editing,
                  maxLines: 3,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      width: 1.0,
                    ),
                  ),
                  style: theme.textTheme.textStyle,
                  placeholderStyle: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 24),
                // Continue button
                CupertinoButton(
                  onPressed: _isGoalValid ? _submitGoal : null,
                  color: CupertinoColors.activeGreen,
                  disabledColor: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                const SizedBox(height: 40),
                // Footer
                Center(
                  child: Text(
                    'FLOWO 1.0.0',
                    style: theme.textTheme.tabLabelTextStyle.copyWith(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
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
}

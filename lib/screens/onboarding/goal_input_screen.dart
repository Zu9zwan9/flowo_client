import 'package:flowo_client/screens/onboarding/welcome_screen.dart';
import 'package:flowo_client/services/onboarding_service.dart';
import 'package:flutter/cupertino.dart';
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
        print('[DEBUG_LOG] Error saving goal: $e');
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

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Back',
        middle: Text('Your Goal'),
      ),
      child: SafeArea(
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
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.flag,
                      color: CupertinoColors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Goal question
              const Text(
                'What\'s your main goal?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Goal description
              Text(
                'This will help us personalize your experience.',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey,
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
                  color:
                      isDarkMode
                          ? CupertinoColors.systemGrey6
                          : CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                style: TextStyle(
                  color:
                      isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black,
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
              ),
              const Spacer(),
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

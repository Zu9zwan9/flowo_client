import 'package:flowo_client/screens/onboarding/enhanced/task_intro_screen.dart';
import 'package:flowo_client/services/onboarding/enhanced_onboarding_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Enhanced goal input screen for the onboarding process
class EnhancedGoalInputScreen extends StatefulWidget {
  const EnhancedGoalInputScreen({super.key});

  @override
  State<EnhancedGoalInputScreen> createState() =>
      _EnhancedGoalInputScreenState();
}

class _EnhancedGoalInputScreenState extends State<EnhancedGoalInputScreen> {
  final TextEditingController _goalController = TextEditingController();
  bool _isGoalValid = false;
  bool _isSubmitting = false;

  // Example goals for suggestions
  final List<String> _goalSuggestions = [
    'Improve productivity',
    'Manage my time better',
    'Complete my projects on time',
    'Develop better habits',
    'Reduce stress and stay organized',
    'Balance work and personal life',
  ];

  @override
  void initState() {
    super.initState();
    _goalController.addListener(_validateGoal);
  }

  @override
  void dispose() {
    _goalController.removeListener(_validateGoal);
    _goalController.dispose();
    super.dispose();
  }

  void _validateGoal() {
    setState(() {
      _isGoalValid = _goalController.text.trim().isNotEmpty;
    });
  }

  void _selectSuggestion(String suggestion) {
    _goalController.text = suggestion;
    // Move cursor to the end of the text
    _goalController.selection = TextSelection.fromPosition(
      TextPosition(offset: _goalController.text.length),
    );
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
      final onboardingService = Provider.of<EnhancedOnboardingService>(
        context,
        listen: false,
      );
      await onboardingService.saveUserGoal(_goalController.text.trim());

      if (mounted) {
        // Navigate to the task introduction screen
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (context) => const TaskIntroScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to save your goal. Please try again.');
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
        previousPageTitle: 'Name',
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
                  'We\'ll tailor the app to help you achieve this goal and provide personalized recommendations.',
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Goal input field
                CupertinoTextField(
                  controller: _goalController,
                  placeholder: 'Enter your goal',
                  padding: const EdgeInsets.all(16),
                  clearButtonMode: OverlayVisibilityMode.editing,
                  maxLines: 2,
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemGrey6,
                      context,
                    ),
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
                const SizedBox(height: 16),
                // Goal suggestions
                Text(
                  'Suggestions:',
                  style: theme.textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _goalSuggestions.map((suggestion) {
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(16),
                          onPressed: () => _selectSuggestion(suggestion),
                          child: Text(
                            suggestion,
                            style: theme.textTheme.textStyle.copyWith(
                              fontSize: 14,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),
                // Feature preview
                Container(
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
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.lightbulb_fill,
                            color: CupertinoColors.systemYellow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How Flowo Helps You Achieve Goals',
                            style: theme.textTheme.textStyle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.list_bullet,
                            color: CupertinoColors.activeGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Break down your goal into manageable tasks',
                              style: theme.textTheme.textStyle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.repeat,
                            color: CupertinoColors.activeGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Build habits that support your goal',
                              style: theme.textTheme.textStyle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.chart_bar_alt_fill,
                            color: CupertinoColors.activeGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Track your progress with detailed analytics',
                              style: theme.textTheme.textStyle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
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
                            index <= 2
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey4,
                      ),
                    ),
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

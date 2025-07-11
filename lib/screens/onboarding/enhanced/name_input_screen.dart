import 'package:flowo_client/screens/onboarding/enhanced/goal_input_screen.dart';
import 'package:flowo_client/services/onboarding/enhanced_onboarding_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Enhanced name input screen for the onboarding process
class EnhancedNameInputScreen extends StatefulWidget {
  const EnhancedNameInputScreen({super.key});

  @override
  State<EnhancedNameInputScreen> createState() =>
      _EnhancedNameInputScreenState();
}

class _EnhancedNameInputScreenState extends State<EnhancedNameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isNameValid = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateName);
    _nameController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _submitName() async {
    if (!_isNameValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Save the name
      final onboardingService = Provider.of<EnhancedOnboardingService>(
        context,
        listen: false,
      );
      await onboardingService.saveUserName(_nameController.text.trim());

      if (mounted) {
        // Navigate to the goal input screen
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => const EnhancedGoalInputScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to save your name. Please try again.');
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
        previousPageTitle: 'Welcome',
        middle: const Text('Your Name'),
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
                // Person icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.person_fill,
                        color: CupertinoColors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Name question
                Text(
                  'What\'s your name?',
                  style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),
                // Name description
                Text(
                  'We\'ll use your name to personalize your experience and make the app feel more welcoming.',
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 16,
                    color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Name input field
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'Enter your name',
                  padding: const EdgeInsets.all(16),
                  clearButtonMode: OverlayVisibilityMode.editing,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.words,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      width: 1.0,
                    ),
                  ),
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
                  ),
                  placeholderStyle: theme.textTheme.textStyle.copyWith(
                    color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
                  ),
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
                            'Personalization Preview',
                            style: theme.textTheme.textStyle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your name will appear in:',
                        style: theme.textTheme.textStyle,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.activeGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Daily greetings on your home screen',
                              style: theme.textTheme.textStyle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.activeGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Task completion celebrations',
                              style: theme.textTheme.textStyle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.activeGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Personalized notifications',
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
                        color: index <= 1
                            ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
                            : CupertinoDynamicColor.resolve(CupertinoColors.systemGrey4, context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Continue button
                CupertinoButton(
                  onPressed: _isNameValid ? _submitName : null,
                  color: CupertinoColors.activeBlue,
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

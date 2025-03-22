import 'package:flowo_client/design/glassmorphic_container.dart';
import 'package:flowo_client/screens/onboarding/goal_input_screen.dart';
import 'package:flowo_client/services/onboarding_service.dart';
import 'package:flowo_client/theme_notifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// First screen of the onboarding process that asks for the user's name
class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
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
      final onboardingService = Provider.of<OnboardingService>(
        context,
        listen: false,
      );
      await onboardingService.saveUserName(_nameController.text.trim());

      if (mounted) {
        // Navigate to the goal input screen
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (context) => const GoalInputScreen()),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final primaryColor = theme.primaryColor;
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Welcome to Flowo'),
        backgroundColor: theme.barBackgroundColor.withOpacity(0.8),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // App logo with glassmorphic effect
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
                      CupertinoIcons.calendar_today,
                      color: CupertinoColors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App name and tagline in a glassmorphic card
              GlassmorphicCard(
                borderRadius: BorderRadius.circular(16),
                blur: glassmorphicTheme.defaultBlur,
                opacity: glassmorphicTheme.defaultOpacity,
                borderWidth: glassmorphicTheme.defaultBorderWidth,
                child: Column(
                  children: [
                    // App name
                    Text(
                      'Flowo',
                      style: theme.textTheme.navLargeTitleTextStyle,
                    ),
                    const SizedBox(height: 8),
                    // App tagline
                    Text(
                      'Your personal productivity assistant',
                      style: theme.textTheme.textStyle.copyWith(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Text(
                      'What\'s your name?',
                      style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We\'ll personalize your experience',
                      style: theme.textTheme.textStyle.copyWith(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name input field with glassmorphic effect
                    GlassmorphicContainer(
                      borderRadius: BorderRadius.circular(12),
                      blur: glassmorphicTheme.defaultBlur,
                      opacity: 0.1, // More transparent for input field
                      borderWidth: 1.0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: CupertinoTextField(
                        controller: _nameController,
                        placeholder: 'Enter your name',
                        padding: const EdgeInsets.all(16),
                        clearButtonMode: OverlayVisibilityMode.editing,
                        autocorrect: false,
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
                onTap: _isNameValid && !_isSubmitting ? _submitName : null,
                child: GlassmorphicContainer(
                  height: 56,
                  borderRadius: BorderRadius.circular(12),
                  blur: glassmorphicTheme.defaultBlur,
                  opacity: _isNameValid ? 0.3 : 0.1, // More opaque when enabled
                  borderWidth: glassmorphicTheme.defaultBorderWidth,
                  borderColor:
                      _isNameValid
                          ? primaryColor.withOpacity(0.5)
                          : CupertinoColors.systemGrey4.withOpacity(0.3),
                  backgroundColor:
                      _isNameValid
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

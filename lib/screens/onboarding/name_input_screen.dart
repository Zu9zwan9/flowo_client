import 'package:flowo_client/screens/onboarding/goal_input_screen.dart';
import 'package:flowo_client/services/onboarding_service.dart';
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // App logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
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
              // App name
              const Center(
                child: Text(
                  'Flowo',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              // App tagline
              Center(
                child: Text(
                  'Your personal productivity assistant',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDarkMode
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Welcome message
              const Text(
                'What\'s your name?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Name input field
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Enter your name',
                padding: const EdgeInsets.all(16),
                clearButtonMode: OverlayVisibilityMode.editing,
                autocorrect: false,
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

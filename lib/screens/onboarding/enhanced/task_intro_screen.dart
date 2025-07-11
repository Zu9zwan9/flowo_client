import 'package:flowo_client/screens/onboarding/enhanced/calendar_intro_screen.dart';
import 'package:flowo_client/services/onboarding/enhanced_onboarding_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Task management introduction screen for the enhanced onboarding process
class TaskIntroScreen extends StatefulWidget {
  const TaskIntroScreen({super.key});

  @override
  State<TaskIntroScreen> createState() => _TaskIntroScreenState();
}

class _TaskIntroScreenState extends State<TaskIntroScreen> {
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
    await onboardingService.markStepCompleted('tasks');
  }

  Future<void> _continueToNextScreen() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      if (mounted) {
        // Navigate to the calendar introduction screen
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (context) => const CalendarIntroScreen()),
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
        previousPageTitle: 'Goal',
        middle: const Text('Task Management'),
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
                // Task icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen,
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
                        CupertinoIcons.list_bullet,
                        color: CupertinoColors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Feature title
                Text(
                  'Manage Your Tasks',
                  style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Feature description
                Text(
                  'Flowo helps you organize and track your tasks efficiently, so you can focus on what matters most.',
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Task management features
                _buildFeatureItem(
                  context,
                  icon: CupertinoIcons.add_circled,
                  title: 'Create Tasks',
                  description:
                      'Quickly add new tasks with due dates, priorities, and categories.',
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(
                  context,
                  icon: CupertinoIcons.checkmark_circle,
                  title: 'Track Completion',
                  description:
                      'Mark tasks as complete and see your progress over time.',
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(
                  context,
                  icon: CupertinoIcons.bell,
                  title: 'Get Reminders',
                  description:
                      'Set reminders for important tasks so you never miss a deadline.',
                ),
                const SizedBox(height: 40),
                // Task management demo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemGrey6,
                      context,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.systemGrey5,
                        context,
                      ),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example Task List',
                        style: theme.textTheme.textStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTaskItem(
                        context,
                        title: 'Create project plan',
                        isCompleted: true,
                        priority: 'High',
                      ),
                      const SizedBox(height: 8),
                      _buildTaskItem(
                        context,
                        title: 'Schedule team meeting',
                        isCompleted: false,
                        priority: 'Medium',
                      ),
                      const SizedBox(height: 8),
                      _buildTaskItem(
                        context,
                        title: 'Review quarterly goals',
                        isCompleted: false,
                        priority: 'High',
                      ),
                      const SizedBox(height: 8),
                      _buildTaskItem(
                        context,
                        title: 'Update documentation',
                        isCompleted: false,
                        priority: 'Low',
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
                            index <= 3
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Continue button
                CupertinoButton(
                  onPressed: _continueToNextScreen,
                  color: CupertinoColors.systemGreen,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child:
                      _isLoading
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

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = CupertinoTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, color: CupertinoColors.systemGreen, size: 24),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
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
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.textStyle.copyWith(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(
    BuildContext context, {
    required String title,
    required bool isCompleted,
    required String priority,
  }) {
    final theme = CupertinoTheme.of(context);

    Color priorityColor;
    switch (priority) {
      case 'High':
        priorityColor = CupertinoColors.systemRed;
        break;
      case 'Medium':
        priorityColor = CupertinoColors.systemOrange;
        break;
      case 'Low':
        priorityColor = CupertinoColors.systemGreen;
        break;
      default:
        priorityColor = CupertinoColors.systemGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey6, context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGrey5,
            context,
          ),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            color:
                isCompleted
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemGrey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.textStyle.copyWith(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color:
                    isCompleted
                        ? CupertinoColors.systemGrey
                        : CupertinoDynamicColor.resolve(
                          CupertinoColors.label,
                          context,
                        ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              priority,
              style: theme.textTheme.textStyle.copyWith(
                fontSize: 12,
                color: priorityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

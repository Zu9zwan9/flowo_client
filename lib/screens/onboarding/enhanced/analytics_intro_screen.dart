import 'package:flowo_client/screens/onboarding/enhanced/completion_screen.dart';
import 'package:flowo_client/services/onboarding/enhanced_onboarding_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Analytics introduction screen for the enhanced onboarding process
class AnalyticsIntroScreen extends StatefulWidget {
  const AnalyticsIntroScreen({super.key});

  @override
  State<AnalyticsIntroScreen> createState() => _AnalyticsIntroScreenState();
}

class _AnalyticsIntroScreenState extends State<AnalyticsIntroScreen> {
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
    await onboardingService.markStepCompleted('analytics');
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
        // Navigate to the completion screen
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (context) => const CompletionScreen()),
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
        previousPageTitle: 'Calendar',
        middle: const Text('Analytics & Insights'),
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
                // Analytics icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemPurple,
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
                        CupertinoIcons.chart_bar_alt_fill,
                        color: CupertinoColors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Feature title
                Text(
                  'Track Your Progress',
                  style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Feature description
                Text(
                  'Flowo\'s analytics help you understand your productivity patterns and track progress toward your goals.',
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Analytics features
                _buildFeatureItem(
                  context,
                  icon: CupertinoIcons.chart_pie,
                  title: 'Productivity Insights',
                  description:
                      'See how you spend your time and identify opportunities for improvement.',
                  color: CupertinoColors.systemPurple,
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(
                  context,
                  icon: CupertinoIcons.graph_circle,
                  title: 'Goal Tracking',
                  description:
                      'Monitor your progress toward your goals with visual indicators.',
                  color: CupertinoColors.systemPurple,
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(
                  context,
                  icon: CupertinoIcons.arrow_up_right_square,
                  title: 'Trend Analysis',
                  description:
                      'Identify patterns in your productivity over time with trend charts.',
                  color: CupertinoColors.systemPurple,
                ),
                const SizedBox(height: 40),
                // Analytics demo
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
                        'Analytics Preview',
                        style: theme.textTheme.textStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Task completion chart
                      _buildTaskCompletionChart(context),
                      const SizedBox(height: 16),
                      // Productivity score
                      _buildProductivityScore(context),
                      const SizedBox(height: 16),
                      // Weekly summary
                      Text(
                        'Weekly Summary',
                        style: theme.textTheme.textStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildWeeklySummary(context),
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
                            index <= 5
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
                  color: CupertinoColors.systemPurple,
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
    required Color color,
  }) {
    final theme = CupertinoTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(icon, color: color, size: 24)),
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

  Widget _buildTaskCompletionChart(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    // Sample data for task completion
    final completedTasks = 18;
    final totalTasks = 25;
    final completionPercentage = (completedTasks / totalTasks * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Completion',
          style: theme.textTheme.textStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width:
                              MediaQuery.of(context).size.width *
                              0.6 *
                              (completedTasks / totalTasks),
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedTasks/$totalTasks tasks completed',
                        style: theme.textTheme.textStyle.copyWith(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      Text(
                        '$completionPercentage%',
                        style: theme.textTheme.textStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductivityScore(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    // Sample productivity score
    const productivityScore = 85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productivity Score',
          style: theme.textTheme.textStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: CupertinoColors.systemPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$productivityScore',
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Great job!',
                    style: theme.textTheme.textStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your productivity is 15% higher than last week.',
                    style: theme.textTheme.textStyle.copyWith(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklySummary(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    // Sample data for weekly summary
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final taskValues = [4, 6, 5, 8, 7, 3, 2];
    final maxValue = taskValues.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(CupertinoColors.white, context),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(weekDays.length, (index) {
          final value = taskValues[index];
          final barHeight = (value / maxValue) * 70;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: barHeight,
                decoration: BoxDecoration(
                  color:
                      index ==
                              3 // Thursday has highest value
                          ? CupertinoColors.systemPurple
                          : CupertinoColors.systemPurple.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                weekDays[index],
                style: theme.textTheme.textStyle.copyWith(
                  fontSize: 10,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$value',
                style: theme.textTheme.textStyle.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

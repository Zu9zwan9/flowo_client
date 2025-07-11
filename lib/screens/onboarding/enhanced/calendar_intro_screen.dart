import 'package:flowo_client/screens/onboarding/enhanced/analytics_intro_screen.dart';
import 'package:flowo_client/services/onboarding/enhanced_onboarding_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Calendar introduction screen for the enhanced onboarding process
class CalendarIntroScreen extends StatefulWidget {
  const CalendarIntroScreen({super.key});

  @override
  State<CalendarIntroScreen> createState() => _CalendarIntroScreenState();
}

class _CalendarIntroScreenState extends State<CalendarIntroScreen> {
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
    await onboardingService.markStepCompleted('calendar');
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
        // Navigate to the analytics introduction screen
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => const AnalyticsIntroScreen(),
          ),
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
        previousPageTitle: 'Tasks',
        middle: const Text('Calendar & Events'),
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
                // Calendar icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemPink,
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
                        CupertinoIcons.calendar,
                        color: CupertinoColors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Feature title
                Text(
                  'Plan Your Schedule',
                  style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Feature description
                Text(
                  'Flowo\'s calendar helps you visualize your schedule, manage events, and stay on top of your commitments.',
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Calendar features
                _buildFeatureItem(
                  context,
                  icon: CupertinoIcons.calendar_badge_plus,
                  title: 'Schedule Events',
                  description:
                      'Create and manage events with customizable reminders and recurrence.',
                  color: CupertinoColors.systemPink,
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(
                  context,
                  icon: CupertinoIcons.calendar_today,
                  title: 'Daily Overview',
                  description:
                      'See your daily schedule at a glance with a clear timeline view.',
                  color: CupertinoColors.systemPink,
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(
                  context,
                  icon: CupertinoIcons.arrow_2_circlepath,
                  title: 'Recurring Events',
                  description:
                      'Set up recurring events for regular activities and habits.',
                  color: CupertinoColors.systemPink,
                ),
                const SizedBox(height: 40),
                // Calendar demo
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
                        'Calendar Preview',
                        style: theme.textTheme.textStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mini calendar view
                      _buildMiniCalendar(context),
                      const SizedBox(height: 16),
                      // Daily schedule
                      Text(
                        'Today\'s Schedule',
                        style: theme.textTheme.textStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildScheduleItem(
                        context,
                        time: '9:00 AM',
                        title: 'Team Meeting',
                        location: 'Conference Room',
                        color: CupertinoColors.systemBlue,
                      ),
                      const SizedBox(height: 8),
                      _buildScheduleItem(
                        context,
                        time: '12:00 PM',
                        title: 'Lunch Break',
                        location: 'Cafeteria',
                        color: CupertinoColors.systemGreen,
                      ),
                      const SizedBox(height: 8),
                      _buildScheduleItem(
                        context,
                        time: '2:30 PM',
                        title: 'Project Review',
                        location: 'Meeting Room 2',
                        color: CupertinoColors.systemOrange,
                      ),
                      const SizedBox(height: 8),
                      _buildScheduleItem(
                        context,
                        time: '4:00 PM',
                        title: 'Client Call',
                        location: 'Phone',
                        color: CupertinoColors.systemPurple,
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
                            index <= 4
                                ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
                                : CupertinoDynamicColor.resolve(CupertinoColors.systemGrey4, context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Continue button
                CupertinoButton(
                  onPressed: _continueToNextScreen,
                  color: CupertinoColors.systemPink,
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
                  color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCalendar(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final today = DateTime.now();
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    // Adjust for Sunday as first day of week (0-indexed)
    final startOffset = firstWeekday % 7;

    return Column(
      children: [
        // Month and year header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chevron_left,
              color: CupertinoColors.systemGrey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '${_getMonthName(today.month)} ${today.year}',
              style: theme.textTheme.textStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (day) => SizedBox(
                      width: 24,
                      child: Text(
                        day,
                        style: theme.textTheme.textStyle.copyWith(
                          fontSize: 12,
                          color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: 42, // 6 weeks * 7 days
          itemBuilder: (context, index) {
            final adjustedIndex = index - startOffset;
            final day = adjustedIndex + 1;

            if (adjustedIndex < 0 || day > daysInMonth) {
              return const SizedBox.shrink();
            }

            final isToday = day == today.day;
            final hasEvent = [5, 12, 15, 20, 25].contains(day);

            return Container(
              margin: const EdgeInsets.all(2),
              decoration:
                  isToday
                      ? BoxDecoration(
                        color: CupertinoColors.systemPink,
                        shape: BoxShape.circle,
                      )
                      : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: theme.textTheme.textStyle.copyWith(
                      fontSize: 12,
                      color:
                          isToday
                              ? CupertinoColors.white
                              : CupertinoDynamicColor.resolve(
                                CupertinoColors.label,
                                context,
                              ),
                    ),
                  ),
                  if (hasEvent && !isToday)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemPink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildScheduleItem(
    BuildContext context, {
    required String time,
    required String title,
    required String location,
    required Color color,
  }) {
    final theme = CupertinoTheme.of(context);

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
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: theme.textTheme.textStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  location,
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 12,
                    color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.right_chevron,
            color: CupertinoColors.systemGrey,
            size: 16,
          ),
        ],
      ),
    );
  }
}

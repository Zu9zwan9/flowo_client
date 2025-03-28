import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../models/pomodoro_statistics.dart';

class PomodoroStatisticsScreen extends StatelessWidget {
  final PomodoroStatistics statistics;

  const PomodoroStatisticsScreen({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    // Get dynamic colors based on system theme
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    // Get statistics data
    final totalSessions = statistics.totalSessions;
    final totalFocusTime = statistics.totalFocusTime;
    final currentStreak = statistics.currentStreak;
    final longestStreak = statistics.longestStreak;

    // Get weekly data
    final weeklySessions = statistics.getSessionsForWeek();
    final weeklyFocusTime = statistics.getFocusTimeForWeek();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Pomodoro Statistics'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Summary cards
            Row(
              children: [
                _buildStatCard(
                  context,
                  title: 'Total Sessions',
                  value: totalSessions.toString(),
                  icon: CupertinoIcons.timer,
                  color: primaryColor,
                  flex: 1,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  title: 'Total Focus Time',
                  value: PomodoroStatistics.formatDuration(totalFocusTime),
                  icon: CupertinoIcons.clock,
                  color: CupertinoColors.activeOrange,
                  flex: 1,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Streak cards
            Row(
              children: [
                _buildStatCard(
                  context,
                  title: 'Current Streak',
                  value:
                      '$currentStreak ${currentStreak == 1 ? 'day' : 'days'}',
                  icon: CupertinoIcons.flame,
                  color: CupertinoColors.systemRed,
                  flex: 1,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  title: 'Longest Streak',
                  value:
                      '$longestStreak ${longestStreak == 1 ? 'day' : 'days'}',
                  icon: CupertinoIcons.star,
                  color: CupertinoColors.systemYellow,
                  flex: 1,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Weekly statistics header
            Text(
              'This Week',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 16),

            // Weekly chart
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildWeeklyChart(context, weeklySessions),
            ),

            const SizedBox(height: 24),

            // Daily breakdown header
            Text(
              'Daily Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 16),

            // Daily breakdown list
            ...weeklySessions.entries.map((entry) {
              final date = DateTime.parse(entry.key);
              final sessions = entry.value;
              final focusTime = weeklyFocusTime[entry.key] ?? 0;

              return _buildDailyItem(
                context,
                date: date,
                sessions: sessions,
                focusTime: focusTime,
              );
            }).toList(),

            const SizedBox(height: 24),

            // Reset statistics button
            CupertinoButton(
              color: CupertinoColors.systemRed,
              onPressed: () {
                _showResetConfirmation(context);
              },
              child: const Text('Reset Statistics'),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoTheme.of(
                  context,
                ).textTheme.textStyle.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(
    BuildContext context,
    Map<String, int> weeklySessions,
  ) {
    final maxSessions = weeklySessions.values.fold(
      0,
      (max, value) => value > max ? value : max,
    );
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final date = startOfWeek.add(Duration(days: index));
        final dateString =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final sessions = weeklySessions[dateString] ?? 0;

        // Calculate bar height (minimum 10 for visibility)
        final barHeight =
            maxSessions > 0 ? 150 * (sessions / maxSessions) : 0.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              sessions.toString(),
              style: TextStyle(
                fontSize: 12,
                color: CupertinoTheme.of(
                  context,
                ).textTheme.textStyle.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: barHeight > 0 ? max(barHeight, 10) : 0,
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).primaryColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: TextStyle(
                fontSize: 12,
                color: CupertinoTheme.of(
                  context,
                ).textTheme.textStyle.color?.withOpacity(0.7),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDailyItem(
    BuildContext context, {
    required DateTime date,
    required int sessions,
    required int focusTime,
  }) {
    final isToday = _isToday(date);
    final dayName = _getDayName(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isToday
                ? CupertinoTheme.of(context).primaryColor.withOpacity(0.1)
                : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border:
            isToday
                ? Border.all(
                  color: CupertinoTheme.of(
                    context,
                  ).primaryColor.withOpacity(0.3),
                  width: 1,
                )
                : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayName, ${date.day}/${date.month}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sessions ${sessions == 1 ? 'session' : 'sessions'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoTheme.of(
                      context,
                    ).textTheme.textStyle.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            PomodoroStatistics.formatDuration(focusTime),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getDayName(DateTime date) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  void _showResetConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Reset Statistics?'),
            content: const Text(
              'This will reset all your Pomodoro statistics. This action cannot be undone.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Reset'),
                onPressed: () {
                  statistics.reset();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }
}

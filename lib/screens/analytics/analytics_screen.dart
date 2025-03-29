import 'package:flowo_client/blocs/analytics/analytics_cubit.dart';
import 'package:flowo_client/blocs/analytics/analytics_state.dart';
import 'package:flowo_client/models/analytics_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Color,
        BoxShadow,
        TextStyle,
        FontWeight,
        CircularProgressIndicator,
        AlwaysStoppedAnimation;
import 'package:flutter_bloc/flutter_bloc.dart';

// Formatter interface for dependency inversion (SOLID)
abstract class AnalyticsFormatter {
  String formatNumber(num value);

  String formatPercent(double value);

  String getEfficiencyMessage(double score);
}

// Concrete implementation of formatter
class DefaultAnalyticsFormatter implements AnalyticsFormatter {
  @override
  String formatNumber(num value) => value.toString();

  @override
  String formatPercent(double value) => '${value.toStringAsFixed(1)}%';

  @override
  String getEfficiencyMessage(double score) {
    if (score >= 90) {
      return 'Excellent! You\'re extremely efficient at managing your tasks.';
    } else if (score >= 75) {
      return 'Great job! You\'re doing well at managing your tasks.';
    } else if (score >= 60) {
      return 'Good progress. Keep working on improving your task management.';
    } else if (score >= 40) {
      return 'You\'re making progress, but there\'s room for improvement.';
    } else {
      return 'You might need to work on your task management skills.';
    }
  }
}

/// Screen for displaying analytics and statistics
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsCubit _analyticsCubit;
  final AnalyticsFormatter _formatter = DefaultAnalyticsFormatter();

  @override
  void initState() {
    super.initState();
    // Arrange - Get the analytics cubit
    _analyticsCubit = BlocProvider.of<AnalyticsCubit>(context);
    // Act - Load the analytics data
    _analyticsCubit.loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
          builder: (context, state) {
            // Assert - Check the state and render appropriate UI
            if (state is AnalyticsLoading) {
              return const Center(child: CupertinoActivityIndicator());
            } else if (state is AnalyticsError) {
              return _buildErrorState(context, state.message);
            } else if (state is AnalyticsLoaded) {
              return _buildAnalyticsContent(context, state.analyticsData);
            }

            return const Center(child: CupertinoActivityIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemRed.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading analytics',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: CupertinoTheme.of(context).textTheme.textStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () => _analyticsCubit.loadAnalytics(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, AnalyticsData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AnalyticsCard(
          title: 'Summary',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatItem(
                    icon: CupertinoIcons.list_bullet,
                    value: _formatter.formatNumber(data.totalTasks),
                    label: 'Total Tasks',
                  ),
                  StatItem(
                    icon: CupertinoIcons.check_mark,
                    value: _formatter.formatNumber(data.completedTasks),
                    label: 'Completed',
                    color: CupertinoColors.activeGreen,
                  ),
                  StatItem(
                    icon: CupertinoIcons.exclamationmark_circle,
                    value: _formatter.formatNumber(data.overdueTasks),
                    label: 'Overdue',
                    color: CupertinoColors.systemRed,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ProgressItem(
                    value: data.completionRate,
                    label: 'Completion Rate',
                    color: CupertinoColors.activeGreen,
                    formatter: _formatter,
                  ),
                  ProgressItem(
                    value: data.overdueRate,
                    label: 'Overdue Rate',
                    color: CupertinoColors.systemRed,
                    formatter: _formatter,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (data.aiSuggestions.isNotEmpty)
          AiSuggestionsCard(suggestions: data.aiSuggestions),
        const SizedBox(height: 16),
        EfficiencyScoreCard(score: data.efficiencyScore, formatter: _formatter),
      ],
    );
  }
}

/// Card widget with iOS styling
class AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const AnalyticsCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? CupertinoColors.black.withOpacity(0.1)
                : CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              title,
              style: CupertinoTheme.of(
                context,
              ).textTheme.navTitleTextStyle.copyWith(fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a statistic with an icon
class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color != null
            ? CupertinoDynamicColor.resolve(color!, context)
            : CupertinoTheme.of(context).primaryColor;

    return Column(
      children: [
        Icon(icon, size: 28, color: resolvedColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoTheme.of(context).textTheme.textStyle.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: CupertinoTheme.of(
            context,
          ).textTheme.tabLabelTextStyle.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

/// Widget for displaying a circular progress indicator
class ProgressItem extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  final AnalyticsFormatter formatter;

  const ProgressItem({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    // Ensure value is finite and between 0-100
    final safeValue = value.isFinite ? value.clamp(0.0, 100.0) : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: safeValue / 100,
                backgroundColor: CupertinoColors.systemGrey5.resolveFrom(
                  context,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(resolvedColor),
                strokeWidth: 8,
              ),
            ),
            Text(
              formatter.formatPercent(safeValue),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: CupertinoTheme.of(
            context,
          ).textTheme.tabLabelTextStyle.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

/// Card for displaying AI suggestions
class AiSuggestionsCard extends StatelessWidget {
  final List<String> suggestions;

  const AiSuggestionsCard({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return AnalyticsCard(
      title: 'AI Suggestions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.lightbulb,
                      color: CupertinoColors.systemYellow.resolveFrom(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

/// Card for displaying efficiency score
class EfficiencyScoreCard extends StatelessWidget {
  final double score;
  final AnalyticsFormatter formatter;

  const EfficiencyScoreCard({
    super.key,
    required this.score,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    return AnalyticsCard(
      title: 'Efficiency Score',
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: 24,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatter.getEfficiencyMessage(score),
            style: CupertinoTheme.of(context).textTheme.textStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

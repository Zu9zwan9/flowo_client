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

/// Screen for displaying analytics and statistics
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsCubit _analyticsCubit;

  @override
  void initState() {
    super.initState();
    _analyticsCubit = BlocProvider.of<AnalyticsCubit>(context);
    _analyticsCubit.loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Analytics & Insights'),
      ),
      child: SafeArea(
        child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            } else if (state is AnalyticsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 48,
                      color: CupertinoColors.systemRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading analytics',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navTitleTextStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: CupertinoTheme.of(context).textTheme.textStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton(
                      onPressed: () => _analyticsCubit.loadAnalytics(),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            } else if (state is AnalyticsLoaded) {
              return _buildAnalyticsContent(context, state.analyticsData);
            }

            return const Center(
              child: CupertinoActivityIndicator(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, AnalyticsData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(context, data),
        const SizedBox(height: 16),
        _buildAiSuggestionsCard(context, data),
        const SizedBox(height: 16),
        _buildEfficiencyCard(context, data),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, AnalyticsData data) {
    return _buildCard(
      context,
      title: 'Summary',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                icon: CupertinoIcons.list_bullet,
                value: data.totalTasks.toString(),
                label: 'Total Tasks',
              ),
              _buildStatItem(
                context,
                icon: CupertinoIcons.check_mark,
                value: data.completedTasks.toString(),
                label: 'Completed',
                color: CupertinoColors.activeGreen,
              ),
              _buildStatItem(
                context,
                icon: CupertinoIcons.exclamationmark_circle,
                value: data.overdueTasks.toString(),
                label: 'Overdue',
                color: CupertinoColors.systemRed,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressItem(
                context,
                value: data.completionRate,
                label: 'Completion Rate',
                color: CupertinoColors.activeGreen,
              ),
              _buildProgressItem(
                context,
                value: data.overdueRate,
                label: 'Overdue Rate',
                color: CupertinoColors.systemRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestionsCard(BuildContext context, AnalyticsData data) {
    if (data.aiSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildCard(
      context,
      title: 'AI Suggestions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.aiSuggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.lightbulb,
                  color: CupertinoColors.systemYellow,
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

  Widget _buildEfficiencyCard(BuildContext context, AnalyticsData data) {
    return _buildCard(
      context,
      title: 'Efficiency Score',
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.efficiencyScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              const Text(
                '/100',
                style: TextStyle(
                  fontSize: 24,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getEfficiencyMessage(data.efficiencyScore),
            style: CupertinoTheme.of(context).textTheme.textStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getEfficiencyMessage(double score) {
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

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: color ?? CupertinoTheme.of(context).primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
      ],
    );
  }

  Widget _buildProgressItem(
    BuildContext context, {
    required double value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: value / 100,
                backgroundColor: CupertinoColors.systemGrey5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 8,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

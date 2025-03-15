import 'package:flowo_client/models/category.dart';
import 'package:flutter/cupertino.dart';

/// Model class for analytics data
class AnalyticsData {
  /// Total number of tasks
  final int totalTasks;

  /// Number of completed tasks
  final int completedTasks;

  /// Number of overdue tasks
  final int overdueTasks;

  /// Completion rate (percentage)
  final double completionRate;

  /// Overdue rate (percentage)
  final double overdueRate;

  /// Time spent by category (in minutes)
  final Map<Category, int> timeSpentByCategory;

  /// AI-generated suggestions based on task patterns
  final List<String> aiSuggestions;

  /// Efficiency score (0-100)
  final double efficiencyScore;

  /// Average time to complete tasks (in minutes)
  final double averageCompletionTime;

  /// Most productive time of day (hour of day, 0-23)
  final int? mostProductiveHour;

  /// Most common category
  final Category? mostCommonCategory;

  /// Constructor
  AnalyticsData({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.completionRate,
    required this.overdueRate,
    required this.timeSpentByCategory,
    required this.aiSuggestions,
    required this.efficiencyScore,
    required this.averageCompletionTime,
    this.mostProductiveHour,
    this.mostCommonCategory,
  });

  /// Create an empty analytics data object
  factory AnalyticsData.empty() {
    return AnalyticsData(
      totalTasks: 0,
      completedTasks: 0,
      overdueTasks: 0,
      completionRate: 0,
      overdueRate: 0,
      timeSpentByCategory: {},
      aiSuggestions: [],
      efficiencyScore: 0,
      averageCompletionTime: 0,
    );
  }
}

/// Data point for category distribution charts
class CategoryDataPoint {
  final Category category;
  final int value;
  final double percentage;

  CategoryDataPoint({
    required this.category,
    required this.value,
    required this.percentage,
  });
}

/// Data point for priority distribution charts
class PriorityDataPoint {
  final int priority;
  final int value;

  PriorityDataPoint({
    required this.priority,
    required this.value,
  });
}

/// Internal class for chart data
class _ChartData {
  final String x;
  final int y;
  final Color color;

  _ChartData(this.x, this.y, this.color);
}

/// Internal class for time data
class _TimeData {
  final String category;
  final int time;
  final double percentage;

  _TimeData(this.category, this.time, this.percentage);
}

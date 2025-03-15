

import 'package:flowo_client/models/analytics_data.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:hive/hive.dart';

/// Service for collecting and processing analytics data
class AnalyticsService {
  /// Get analytics data from the task database
  Future<AnalyticsData> getAnalyticsData() async {
    try {
      final tasksBox = Hive.box<Task>('tasks');
      final tasks = tasksBox.values.toList();
      
      // Filter out any special system tasks
      tasks.removeWhere((task) => task.id == 'free_time_manager');
      
      // Calculate basic metrics
      final totalTasks = tasks.length;
      final completedTasks = tasks.where((task) => task.isDone).length;
      final overdueTasks = tasks.where((task) => task.overdue).length;
      
      // Calculate rates
      final completionRate = totalTasks > 0 
          ? (completedTasks / totalTasks) * 100 
          : 0.0;
      final overdueRate = totalTasks > 0 
          ? (overdueTasks / totalTasks) * 100 
          : 0.0;
      
      // Calculate time spent by category
      final timeSpentByCategory = _calculateTimeSpentByCategory(tasks);
      
      // Generate AI suggestions
      final aiSuggestions = _generateAiSuggestions(
        tasks, 
        completionRate, 
        overdueRate,
        timeSpentByCategory,
      );
      
      // Calculate efficiency score
      final efficiencyScore = _calculateEfficiencyScore(
        completionRate, 
        overdueRate,
        tasks,
      );
      
      // Calculate average completion time
      final averageCompletionTime = _calculateAverageCompletionTime(tasks);
      
      // Find most productive hour
      final mostProductiveHour = _findMostProductiveHour(tasks);
      
      // Find most common category
      final mostCommonCategory = _findMostCommonCategory(tasks);
      
      return AnalyticsData(
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        overdueTasks: overdueTasks,
        completionRate: completionRate,
        overdueRate: overdueRate,
        timeSpentByCategory: timeSpentByCategory,
        aiSuggestions: aiSuggestions,
        efficiencyScore: efficiencyScore,
        averageCompletionTime: averageCompletionTime,
        mostProductiveHour: mostProductiveHour,
        mostCommonCategory: mostCommonCategory,
      );
    } catch (e) {
      logger.e('Error getting analytics data: $e');
      return AnalyticsData.empty();
    }
  }
  
  /// Calculate time spent by category
  Map<Category, int> _calculateTimeSpentByCategory(List<Task> tasks) {
    final timeSpentByCategory = <Category, int>{};
    
    for (final task in tasks) {
      if (task.isDone) {
        final category = task.category;
        final timeSpent = task.estimatedTime;
        
        if (timeSpentByCategory.containsKey(category)) {
          timeSpentByCategory[category] = timeSpentByCategory[category]! + timeSpent;
        } else {
          timeSpentByCategory[category] = timeSpent;
        }
      }
    }
    
    return timeSpentByCategory;
  }
  
  /// Generate AI suggestions based on task patterns
  List<String> _generateAiSuggestions(
    List<Task> tasks,
    double completionRate,
    double overdueRate,
    Map<Category, int> timeSpentByCategory,
  ) {
    final suggestions = <String>[];
    
    // Suggestion based on completion rate
    if (completionRate < 50) {
      suggestions.add(
        'Your task completion rate is below 50%. Try breaking down large tasks into smaller, more manageable subtasks.'
      );
    } else if (completionRate > 80) {
      suggestions.add(
        'Great job! Your task completion rate is above 80%. Keep up the good work!'
      );
    }
    
    // Suggestion based on overdue rate
    if (overdueRate > 30) {
      suggestions.add(
        'You have a high rate of overdue tasks. Consider setting more realistic deadlines or allocating more time for tasks.'
      );
    }
    
    // Suggestion based on category distribution
    if (timeSpentByCategory.isNotEmpty) {
      final mostTimeCategory = timeSpentByCategory.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      suggestions.add(
        'You spend most of your time on "${mostTimeCategory.name}" tasks. Consider if this aligns with your priorities.'
      );
    }
    
    // Suggestion based on task priority
    final highPriorityTasks = tasks.where((task) => task.priority >= 3).toList();
    final highPriorityCompletionRate = highPriorityTasks.isNotEmpty
        ? highPriorityTasks.where((task) => task.isDone).length / highPriorityTasks.length * 100
        : 0;
    
    if (highPriorityCompletionRate < 70) {
      suggestions.add(
        'Your completion rate for high-priority tasks is below 70%. Try focusing on high-priority tasks first.'
      );
    }
    
    // Suggestion based on estimated time accuracy
    // This would require tracking actual time spent, which we don't have yet
    
    return suggestions;
  }
  
  /// Calculate efficiency score (0-100)
  double _calculateEfficiencyScore(
    double completionRate,
    double overdueRate,
    List<Task> tasks,
  ) {
    // Base score on completion rate (0-60 points)
    double score = completionRate * 0.6;
    
    // Penalize for overdue tasks (0-20 points)
    score -= overdueRate * 0.2;
    
    // Bonus for completing high-priority tasks (0-20 points)
    final highPriorityTasks = tasks.where((task) => task.priority >= 3).toList();
    final highPriorityCompletionRate = highPriorityTasks.isNotEmpty
        ? highPriorityTasks.where((task) => task.isDone).length / highPriorityTasks.length * 100
        : 0;
    
    score += highPriorityCompletionRate * 0.2;
    
    // Ensure score is between 0 and 100
    return score.clamp(0, 100);
  }
  
  /// Calculate average completion time (in minutes)
  double _calculateAverageCompletionTime(List<Task> tasks) {
    final completedTasks = tasks.where((task) => task.isDone).toList();
    
    if (completedTasks.isEmpty) {
      return 0;
    }
    
    final totalEstimatedTime = completedTasks.fold<int>(
      0, (sum, task) => sum + task.estimatedTime);
    
    return totalEstimatedTime / completedTasks.length;
  }
  
  /// Find most productive hour (0-23)
  int? _findMostProductiveHour(List<Task> tasks) {
    // This would require tracking when tasks are completed, which we don't have yet
    // For now, return null or a default value
    return null;
  }
  
  /// Find most common category
  Category? _findMostCommonCategory(List<Task> tasks) {
    if (tasks.isEmpty) {
      return null;
    }
    
    final categoryCount = <Category, int>{};
    
    for (final task in tasks) {
      final category = task.category;
      
      if (categoryCount.containsKey(category)) {
        categoryCount[category] = categoryCount[category]! + 1;
      } else {
        categoryCount[category] = 1;
      }
    }
    
    if (categoryCount.isEmpty) {
      return null;
    }
    
    return categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  /// Get category distribution data for charts
  List<CategoryDataPoint> getCategoryDistribution() {
    try {
      final tasksBox = Hive.box<Task>('tasks');
      final tasks = tasksBox.values.toList();
      
      // Filter out any special system tasks
      tasks.removeWhere((task) => task.id == 'free_time_manager');
      
      final categoryCount = <Category, int>{};
      
      for (final task in tasks) {
        final category = task.category;
        
        if (categoryCount.containsKey(category)) {
          categoryCount[category] = categoryCount[category]! + 1;
        } else {
          categoryCount[category] = 1;
        }
      }
      
      final totalTasks = tasks.length;
      
      return categoryCount.entries.map((entry) {
        final percentage = totalTasks > 0 
            ? (entry.value / totalTasks) * 100 
            : 0.0;
        
        return CategoryDataPoint(
          category: entry.key,
          value: entry.value,
          percentage: percentage,
        );
      }).toList();
    } catch (e) {
      logger.e('Error getting category distribution: $e');
      return [];
    }
  }
  
  /// Get priority distribution data for charts
  List<PriorityDataPoint> getPriorityDistribution() {
    try {
      final tasksBox = Hive.box<Task>('tasks');
      final tasks = tasksBox.values.toList();
      
      // Filter out any special system tasks
      tasks.removeWhere((task) => task.id == 'free_time_manager');
      
      final priorityCount = <int, int>{};
      
      for (final task in tasks) {
        final priority = task.priority;
        
        if (priorityCount.containsKey(priority)) {
          priorityCount[priority] = priorityCount[priority]! + 1;
        } else {
          priorityCount[priority] = 1;
        }
      }
      
      return priorityCount.entries.map((entry) {
        return PriorityDataPoint(
          priority: entry.key,
          value: entry.value,
        );
      }).toList();
    } catch (e) {
      logger.e('Error getting priority distribution: $e');
      return [];
    }
  }
  
  /// Get completion rate by category data for charts
  List<CategoryDataPoint> getCompletionRateByCategory() {
    try {
      final tasksBox = Hive.box<Task>('tasks');
      final tasks = tasksBox.values.toList();
      
      // Filter out any special system tasks
      tasks.removeWhere((task) => task.id == 'free_time_manager');
      
      final categoryTasks = <Category, List<Task>>{};
      
      for (final task in tasks) {
        final category = task.category;
        
        if (categoryTasks.containsKey(category)) {
          categoryTasks[category]!.add(task);
        } else {
          categoryTasks[category] = [task];
        }
      }
      
      return categoryTasks.entries.map((entry) {
        final totalTasks = entry.value.length;
        final completedTasks = entry.value.where((task) => task.isDone).length;
        final percentage = totalTasks > 0 
            ? (completedTasks / totalTasks) * 100 
            : 0.0;
        
        return CategoryDataPoint(
          category: entry.key,
          value: completedTasks,
          percentage: percentage,
        );
      }).toList();
    } catch (e) {
      logger.e('Error getting completion rate by category: $e');
      return [];
    }
  }
}

import 'package:flutter/cupertino.dart';

/// Utility class for handling task category-related functionality.
///
/// This class provides methods for consistent category color mapping across the app.
/// Each category type has a specific color associated with it, and similar categories
/// share the same color scheme.
class CategoryUtils {
  static Color getTypeTaskColor(String category) {
    // Assuming this already exists
    switch (category.toLowerCase()) {
      case 'event':
        return CupertinoColors.systemRed;
      case 'habit':
        return CupertinoColors.systemGreen;
      case 'task':
        return CupertinoColors.systemBlue;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'event':
        return CupertinoIcons.calendar;
      case 'habit':
        return CupertinoIcons.repeat;
      case 'task':
        return CupertinoIcons.checkmark_circle;
      default:
        return CupertinoIcons.list_bullet;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
      case 'brainstorm':
        return CupertinoColors.systemBlue;
      case 'personal':
      case 'design':
        return CupertinoColors.systemGreen;
      case 'shopping':
      case 'habit':
        return CupertinoColors.systemOrange;
      case 'health':
      case 'workout':
        return CupertinoColors.systemRed;
      case 'education':
      case 'event':
        return CupertinoColors.systemPurple;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}

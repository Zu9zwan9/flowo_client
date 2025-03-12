import 'package:flutter/cupertino.dart';

/// Utility class for handling task category-related functionality.
///
/// This class provides methods for consistent category color mapping across the app.
/// Each category type has a specific color associated with it, and similar categories
/// share the same color scheme.
class CategoryUtils {
  /// Returns the color associated with the given category.
  ///
  /// The method is case-insensitive and maps similar categories to the same color:
  /// - Blue: work, brainstorm
  /// - Green: personal, design
  /// - Orange: shopping, habit
  /// - Red: health, workout
  /// - Purple: education, event
  ///
  /// Returns [CupertinoColors.systemGrey] for unknown categories.
  ///
  /// Example:
  /// ```dart
  /// final color = CategoryUtils.getCategoryColor('work'); // Returns systemBlue
  /// ```
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

import 'package:flutter/cupertino.dart';

/// Theme helper for consistent styling across components
class TaskComponentsTheme {
  final BuildContext context;

  TaskComponentsTheme(this.context);

  // Text styles
  TextStyle get labelStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: CupertinoColors.label.resolveFrom(context),
  );

  TextStyle get placeholderStyle => TextStyle(
    fontSize: 16,
    color: CupertinoColors.systemGrey2.resolveFrom(context),
  );

  TextStyle get segmentTextStyle => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: CupertinoColors.label.resolveFrom(context),
  );

  TextStyle get buttonLabelStyle => const TextStyle(
    color: CupertinoColors.white,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  // Colors
  Color get primaryColor => CupertinoTheme.of(context).primaryColor;
  Color get backgroundColor =>
      CupertinoColors.systemBackground.resolveFrom(context);
  Color get borderColor => CupertinoColors.systemGrey5.resolveFrom(context);

  // Decorations
  BoxDecoration get searchDecoration => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: borderColor),
  );
}

/// A search bar component for tasks that adapts to the system theme
class TaskSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String? placeholder;

  const TaskSearchBar({super.key, required this.controller, this.placeholder});

  @override
  Widget build(BuildContext context) {
    final theme = TaskComponentsTheme(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoSearchTextField(
        controller: controller,
        placeholder: placeholder ?? 'Search by Name',
        style: theme.labelStyle,
        placeholderStyle: theme.placeholderStyle,
        decoration: theme.searchDecoration,
      ),
    );
  }
}

/// A segmented control for filtering tasks by type
class TaskTypeFilter extends StatelessWidget {
  final TaskFilterType selectedFilter;
  final ValueChanged<TaskFilterType> onFilterChanged;
  final Map<TaskFilterType, String>? customLabels;

  const TaskTypeFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.customLabels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TaskComponentsTheme(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoSegmentedControl<TaskFilterType>(
        groupValue: selectedFilter,
        onValueChanged: onFilterChanged,
        borderColor: theme.borderColor,
        selectedColor: theme.primaryColor,
        pressedColor: theme.primaryColor.withOpacity(0.2),
        children: _buildSegmentChildren(context),
      ),
    );
  }

  Map<TaskFilterType, Widget> _buildSegmentChildren(BuildContext context) {
    final labels =
        customLabels ??
        {
          TaskFilterType.all: 'All',
          TaskFilterType.event: 'Events',
          TaskFilterType.task: 'Tasks',
          TaskFilterType.habit: 'Habits',
        };

    return {
      for (final type in TaskFilterType.values)
        if (labels.containsKey(type))
          type: _buildSegmentChild(context, labels[type]!),
    };
  }

  Widget _buildSegmentChild(BuildContext context, String text) {
    final theme = TaskComponentsTheme(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(text, style: theme.segmentTextStyle),
    );
  }
}

/// An action button with icon and label that follows system styling
class TaskActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const TaskActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TaskComponentsTheme(context);
    final buttonColor = backgroundColor ?? theme.primaryColor;
    final buttonPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10);

    return CupertinoButton(
      onPressed: onPressed,
      color: buttonColor,
      borderRadius: BorderRadius.circular(30),
      padding: buttonPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: CupertinoColors.white),
          const SizedBox(width: 8),
          Text(label, style: theme.buttonLabelStyle),
        ],
      ),
    );
  }
}

/// Factory for creating themed task components
class TaskComponentsFactory {
  final BuildContext context;

  TaskComponentsFactory(this.context);

  TaskSearchBar createSearchBar({
    required TextEditingController controller,
    String? placeholder,
  }) {
    return TaskSearchBar(controller: controller, placeholder: placeholder);
  }

  TaskTypeFilter createTypeFilter({
    required TaskFilterType selectedFilter,
    required ValueChanged<TaskFilterType> onFilterChanged,
    Map<TaskFilterType, String>? customLabels,
  }) {
    return TaskTypeFilter(
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
      customLabels: customLabels,
    );
  }

  TaskActionButton createActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
  }) {
    return TaskActionButton(
      onPressed: onPressed,
      icon: icon,
      label: label,
      backgroundColor: backgroundColor,
      padding: padding,
    );
  }
}

/// Enum representing different task filter types
enum TaskFilterType { all, event, task, habit }

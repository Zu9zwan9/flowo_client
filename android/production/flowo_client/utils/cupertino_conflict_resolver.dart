import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/conflict_detector.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A utility class for showing conflict resolution dialogs
class CupertinoConflictResolver {
  /// Shows a conflict resolution dialog and returns the user's choice
  ///
  /// Returns:
  /// - true if the user wants to proceed with the new task (replacing conflicting tasks)
  /// - false if the user wants to adjust the new task
  /// - null if the user cancels the operation
  static Future<bool?> showConflictDialog({
    required BuildContext context,
    required List<ScheduledTask> conflicts,
    required Map<String, Task> tasksMap,
    required String actionType,
  }) async {
    // Get the system accent color for dynamic theming
    final Color accentColor = CupertinoTheme.of(context).primaryColor;

    // Group conflicts by type for better presentation
    final Map<String, List<ScheduledTask>> groupedConflicts = {};
    for (final conflict in conflicts) {
      final type = ConflictDetector.getConflictTypeDescription(conflict.type);
      groupedConflicts.putIfAbsent(type, () => []).add(conflict);
    }

    // Build the conflict description text
    final StringBuffer description = StringBuffer();
    description.write(
      'The $actionType you are trying to schedule overlaps with:',
    );

    groupedConflicts.forEach((type, tasks) {
      description.write(
        '\n\n• ${tasks.length} $type${tasks.length > 1 ? 's' : ''}:',
      );

      for (int i = 0; i < tasks.length && i < 3; i++) {
        final task = tasksMap[tasks[i].parentTaskId];
        if (task != null) {
          final startTime = TimeOfDay.fromDateTime(tasks[i].startTime);
          final endTime = TimeOfDay.fromDateTime(tasks[i].endTime);

          description.write(
            '\n  - ${task.title} (${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)})',
          );
        }
      }

      if (tasks.length > 3) {
        description.write('\n  - and ${tasks.length - 3} more...');
      }
    });

    description.write('\n\nHow would you like to proceed?');

    logInfo(
      'Showing conflict resolution dialog for $actionType with ${conflicts.length} conflicts',
    );

    return showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            'Schedule Conflict',
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          message: Text(
            description.toString(),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                'Replace conflicting items',
                style: TextStyle(color: accentColor),
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Adjust my schedule',
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  /// Format TimeOfDay in a user-friendly way
  static String _formatTimeOfDay(TimeOfDay time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

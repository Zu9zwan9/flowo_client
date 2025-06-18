import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/task_page/category_tag.dart';
import '../widgets/task_page/task_description.dart';
import 'event_form_screen.dart';

class TaskPageConstants {
  static const double padding = 16.0;
  static const double cornerRadius = 12.0;
  static const double shadowBlurRadius = 4.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
}

class EventDateTimeFormatter {
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}

// Main EventScreen
class EventScreen extends StatefulWidget {
  final Task event;

  const EventScreen({super.key, required this.event});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Task _event;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _notesController = TextEditingController(text: _event.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_event.title, style: theme.textTheme.navTitleTextStyle),
        trailing: SizedBox(
          width: 90,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Icon(CupertinoIcons.pencil, size: 20),
                onPressed: () => _navigateToEditScreen(context),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Icon(
                  CupertinoIcons.delete,
                  size: 20,
                  color: CupertinoColors.destructiveRed,
                ),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TaskPageConstants.padding),
          children: [
            EventHeader(event: _event),
            const SizedBox(height: 24),
            EventDetails(event: _event),
            const SizedBox(height: 24),
            TaskDescription(task: _event, controller: _notesController),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => EventFormScreen(event: _event)),
    ).then(
      (_) => setState(() {
        _event = widget.event;
        _notesController.text = _event.notes ?? '';
      }),
    );
  }

  void _confirmDelete(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Event'),
            content: Text('Delete "${_event.title}"?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  context.read<TaskManagerCubit>().deleteTask(_event);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

// Event Header Widget
class EventHeader extends StatelessWidget {
  final Task event;

  const EventHeader({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final scheduledTask =
        event.scheduledTasks.isNotEmpty ? event.scheduledTasks.first : null;
    final startTime =
        scheduledTask?.startTime ??
        DateTime.fromMillisecondsSinceEpoch(event.deadline);
    final endTime =
        scheduledTask?.endTime ?? startTime.add(const Duration(hours: 1));
    final eventColor =
        event.color != null ? Color(event.color!) : CupertinoColors.activeBlue;

    return Container(
      padding: const EdgeInsets.all(TaskPageConstants.padding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(TaskPageConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: TaskPageConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryTag(categoryName: event.category.name),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    EventDateTimeFormatter.formatDuration(startTime, endTime),
                    style: theme.textTheme.textStyle.copyWith(
                      color: eventColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                CupertinoIcons.calendar,
                size: 14,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  EventDateTimeFormatter.formatDate(startTime),
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.time,
                size: 14,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${EventDateTimeFormatter.formatTime(startTime)} - ${EventDateTimeFormatter.formatTime(endTime)}',
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Event Details Widget
class EventDetails extends StatelessWidget {
  final Task event;

  const EventDetails({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final locationString =
        event.location != null
            ? event.location.toString()
            : "1200 Main St, City, Country";

    return Container(
      padding: const EdgeInsets.all(TaskPageConstants.padding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(TaskPageConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: TaskPageConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          if (locationString.isNotEmpty)
            Row(
              children: [
                const Icon(
                  CupertinoIcons.location,
                  size: 14,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationString,
                    style: theme.textTheme.textStyle.copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (locationString.isNotEmpty) const SizedBox(height: 8),
          if (event.color != null)
            Row(
              children: [
                Icon(
                  CupertinoIcons.circle_fill,
                  size: 14,
                  color: Color(event.color!),
                ),
                const SizedBox(width: 4),
                Text(
                  'Color',
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '../../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../../models/task.dart';
import '../../../models/task_session.dart';

class SessionsWidget extends StatefulWidget {
  final Task task;
  final TaskManagerCubit taskManagerCubit;

  const SessionsWidget({
    required this.task,
    required this.taskManagerCubit,
    super.key,
  });

  @override
  State<SessionsWidget> createState() => _SessionsWidgetState();
}

class _SessionsWidgetState extends State<SessionsWidget> {
  late List<TaskSession> _sessions;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.task.activeSession != null && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadSessions() {
    _sessions = List<TaskSession>.from(widget.task.sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateSessionStats() {
    final task = Hive.box<Task>('tasks').get(widget.task.id) ?? widget.task;
    final sessions = task.sessions;
    if (sessions.isEmpty) {
      return {
        'avgDuration': 0,
        'mostProductiveHour': 0,
        'completedSessions': 0,
        'totalSessions': 0,
        'timeEfficiencyRatio': null,
        'timeEfficiencyDescription': 'No data',
      };
    }

    final completedSessions = sessions.where((s) => s.endTime != null).toList();
    final avgDuration =
        completedSessions.isEmpty
            ? 0
            : completedSessions.fold<int>(
                  0,
                  (sum, session) => sum + session.duration,
                ) ~/
                completedSessions.length;
    final hourCounts = <int, int>{};
    for (var session in sessions) {
      hourCounts[session.startTime.hour] =
          (hourCounts[session.startTime.hour] ?? 0) + 1;
    }
    int mostProductiveHour = 0;
    int maxCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        mostProductiveHour = hour;
      }
    });

    return {
      'avgDuration': avgDuration,
      'mostProductiveHour': mostProductiveHour,
      'completedSessions': completedSessions.length,
      'totalSessions': sessions.length,
      'timeEfficiencyRatio': task.isDone ? task.getTimeEfficiencyRatio() : null,
      'timeEfficiencyDescription':
          task.isDone
              ? task.getTimeEfficiencyDescription()
              : 'Task not completed',
    };
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final theme = CupertinoTheme.of(context);
    final isDisabled = onPressed == null;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isDisabled
                      ? CupertinoColors.systemGrey5
                      : color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isDisabled
                        ? CupertinoColors.systemGrey4
                        : color.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: isDisabled ? CupertinoColors.systemGrey : color,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.textStyle.copyWith(
              fontSize: 12,
              color:
                  isDisabled
                      ? CupertinoColors.systemGrey
                      : theme.textTheme.textStyle.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, TaskSession session) {
    final isActive = session.isActive;
    final startDate = session.startTime;
    final endDate = session.endTime;

    final completionPercentage =
        widget.task.estimatedTime > 0
            ? (session.duration / widget.task.estimatedTime * 100)
                .clamp(0, 100)
                .toInt()
            : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isActive
                ? CupertinoColors.activeGreen
                    .resolveFrom(context)
                    .withOpacity(0.05)
                : CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border:
            isActive
                ? Border.all(
                  color: CupertinoColors.activeGreen
                      .resolveFrom(context)
                      .withOpacity(0.2),
                )
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${startDate.day}/${startDate.month}/${startDate.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    Text(
                      'Started at ${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}${endDate != null ? ' - Ended at ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}' : ' (In Progress)'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isActive) ...[
                CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  child: Icon(
                    CupertinoIcons.pencil,
                    size: 18,
                    color: CupertinoColors.systemBlue.resolveFrom(context),
                  ),
                  onPressed: () => _showEditSessionDialog(context, session),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  child: Icon(
                    CupertinoIcons.trash,
                    size: 18,
                    color: CupertinoColors.destructiveRed.resolveFrom(context),
                  ),
                  onPressed: () => _showDeleteSessionDialog(context, session),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemGrey)
                      .resolveFrom(context)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDuration(session.duration),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: (isActive
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.label)
                        .resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
          if (completionPercentage != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context),
              valueColor: AlwaysStoppedAnimation(
                isActive
                    ? CupertinoColors.activeGreen.resolveFrom(context)
                    : CupertinoColors.activeBlue.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$completionPercentage% of estimated time',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
          if (session.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              session.notes!,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditNotesDialog(BuildContext context, TaskSession session) {
    final TextEditingController notesController = TextEditingController(
      text: session.notes,
    );

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Session Notes'),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: CupertinoTextField(
                controller: notesController,
                placeholder: 'What did you accomplish in this session?',
                maxLines: 5,
                minLines: 3,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4.resolveFrom(context),
                  ),
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Save'),
                onPressed: () {
                  session.notes = notesController.text.trim();
                  if (session.isInBox) {
                    session.save();
                  }
                  _loadSessions();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    ).then((_) => notesController.dispose());
  }

  void _showEditSessionDialog(BuildContext context, TaskSession session) {
    DateTime startTime = session.startTime;
    DateTime? endTime = session.endTime;
    final notesController = TextEditingController(text: session.notes);

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: StatefulBuilder(
              builder:
                  (context, setState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: CupertinoColors.activeBlue.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              'Edit Session',
                              style:
                                  CupertinoTheme.of(
                                    context,
                                  ).textTheme.navTitleTextStyle,
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: CupertinoColors.activeBlue.resolveFrom(
                                    context,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                session.startTime = startTime;
                                session.endTime = endTime;
                                session.notes =
                                    notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim();
                                widget.task.totalDuration = widget.task.sessions
                                    .fold<int>(
                                      0,
                                      (sum, s) =>
                                          sum +
                                          (s.endTime != null ? s.duration : 0),
                                    );
                                widget.task.save();
                                _loadSessions();
                                setState(() {});
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Start Time field
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        showCupertinoModalPopup(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Container(
                                              height: 216,
                                              padding: const EdgeInsets.only(
                                                top: 6.0,
                                              ),
                                              margin: EdgeInsets.only(
                                                bottom:
                                                    MediaQuery.of(
                                                      context,
                                                    ).viewInsets.bottom,
                                              ),
                                              color: CupertinoColors
                                                  .systemBackground
                                                  .resolveFrom(context),
                                              child: SafeArea(
                                                top: false,
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                        ),
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Done',
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                        ),
                                                      ],
                                                    ),
                                                    Expanded(
                                                      child: CupertinoDatePicker(
                                                        mode:
                                                            CupertinoDatePickerMode
                                                                .dateAndTime,
                                                        initialDateTime:
                                                            startTime,
                                                        maximumDate:
                                                            endTime ??
                                                            DateTime.now(),
                                                        onDateTimeChanged: (
                                                          DateTime newDate,
                                                        ) {
                                                          setState(
                                                            () =>
                                                                startTime =
                                                                    newDate,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemFill
                                              .resolveFrom(context),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: CupertinoColors.activeBlue
                                                .resolveFrom(context)
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${startTime.toLocal().toString().split('.')[0]}',
                                              style: TextStyle(
                                                color: CupertinoColors.label
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.time,
                                              color: CupertinoColors.activeBlue
                                                  .resolveFrom(context),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // End Time field
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'End Time',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.label
                                                .resolveFrom(context),
                                          ),
                                        ),
                                        if (session.endTime == null)
                                          Text(
                                            'Session in progress',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: CupertinoColors.activeGreen
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap:
                                          session.endTime != null ||
                                                  session.isActive
                                              ? () {
                                                showCupertinoModalPopup(
                                                  context: context,
                                                  builder: (
                                                    BuildContext context,
                                                  ) {
                                                    return Container(
                                                      height: 216,
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 6.0,
                                                          ),
                                                      margin: EdgeInsets.only(
                                                        bottom:
                                                            MediaQuery.of(
                                                              context,
                                                            ).viewInsets.bottom,
                                                      ),
                                                      color: CupertinoColors
                                                          .systemBackground
                                                          .resolveFrom(context),
                                                      child: SafeArea(
                                                        top: false,
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                CupertinoButton(
                                                                  child:
                                                                      const Text(
                                                                        'Cancel',
                                                                      ),
                                                                  onPressed:
                                                                      () =>
                                                                          Navigator.of(
                                                                            context,
                                                                          ).pop(),
                                                                ),
                                                                CupertinoButton(
                                                                  child:
                                                                      const Text(
                                                                        'Done',
                                                                      ),
                                                                  onPressed:
                                                                      () =>
                                                                          Navigator.of(
                                                                            context,
                                                                          ).pop(),
                                                                ),
                                                              ],
                                                            ),
                                                            Expanded(
                                                              child: CupertinoDatePicker(
                                                                mode:
                                                                    CupertinoDatePickerMode
                                                                        .dateAndTime,
                                                                initialDateTime:
                                                                    endTime ??
                                                                    DateTime.now(),
                                                                minimumDate:
                                                                    startTime,
                                                                maximumDate:
                                                                    DateTime.now(),
                                                                onDateTimeChanged: (
                                                                  DateTime
                                                                  newDate,
                                                                ) {
                                                                  setState(
                                                                    () =>
                                                                        endTime =
                                                                            newDate,
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                              : null,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemFill
                                              .resolveFrom(context),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: CupertinoColors.activeBlue
                                                .resolveFrom(context)
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              endTime != null
                                                  ? '${endTime?.toLocal().toString().split('.')[0]}'
                                                  : 'Not ended yet',
                                              style: TextStyle(
                                                color:
                                                    endTime != null
                                                        ? CupertinoColors.label
                                                            .resolveFrom(
                                                              context,
                                                            )
                                                        : CupertinoColors
                                                            .secondaryLabel
                                                            .resolveFrom(
                                                              context,
                                                            ),
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.time,
                                              color:
                                                  endTime != null
                                                      ? CupertinoColors
                                                          .activeBlue
                                                          .resolveFrom(context)
                                                      : CupertinoColors
                                                          .secondaryLabel
                                                          .resolveFrom(context),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Session duration
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Session Duration',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemFill
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(
                                              endTime != null
                                                  ? endTime!
                                                      .difference(startTime)
                                                      .inMilliseconds
                                                  : DateTime.now()
                                                      .difference(startTime)
                                                      .inMilliseconds,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: CupertinoColors.label
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                          Icon(
                                            CupertinoIcons.timer,
                                            color: CupertinoColors.systemGrey
                                                .resolveFrom(context),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Notes field
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Session Notes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CupertinoTextField(
                                      controller: notesController,
                                      placeholder:
                                          'What did you accomplish in this session?',
                                      maxLines: 5,
                                      minLines: 3,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemFill
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: CupertinoColors.activeBlue
                                              .resolveFrom(context)
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    DateTime startTime = DateTime.now().subtract(const Duration(hours: 1));
    DateTime endTime = DateTime.now();
    final notesController = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: StatefulBuilder(
              builder:
                  (context, setState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: CupertinoColors.activeBlue.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              'Add Session',
                              style:
                                  CupertinoTheme.of(
                                    context,
                                  ).textTheme.navTitleTextStyle,
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  color: CupertinoColors.activeBlue.resolveFrom(
                                    context,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                final newSession = TaskSession(
                                  id:
                                      DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                  taskId: widget.task.id,
                                  startTime: startTime,
                                  endTime: endTime,
                                  notes:
                                      notesController.text.trim().isEmpty
                                          ? null
                                          : notesController.text.trim(),
                                );
                                widget.task.sessions.add(newSession);
                                widget.task.totalDuration = widget.task.sessions
                                    .fold<int>(
                                      0,
                                      (sum, s) =>
                                          sum +
                                          (s.endTime != null ? s.duration : 0),
                                    );
                                widget.task.save();
                                _loadSessions();
                                setState(() {});
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Start Time field
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        showCupertinoModalPopup(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Container(
                                              height: 216,
                                              padding: const EdgeInsets.only(
                                                top: 6.0,
                                              ),
                                              margin: EdgeInsets.only(
                                                bottom:
                                                    MediaQuery.of(
                                                      context,
                                                    ).viewInsets.bottom,
                                              ),
                                              color: CupertinoColors
                                                  .systemBackground
                                                  .resolveFrom(context),
                                              child: SafeArea(
                                                top: false,
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                        ),
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Done',
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                        ),
                                                      ],
                                                    ),
                                                    Expanded(
                                                      child: CupertinoDatePicker(
                                                        mode:
                                                            CupertinoDatePickerMode
                                                                .dateAndTime,
                                                        initialDateTime:
                                                            startTime,
                                                        maximumDate: endTime,
                                                        onDateTimeChanged: (
                                                          DateTime newDate,
                                                        ) {
                                                          setState(
                                                            () =>
                                                                startTime =
                                                                    newDate,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemFill
                                              .resolveFrom(context),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: CupertinoColors.activeBlue
                                                .resolveFrom(context)
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${startTime.toLocal().toString().split('.')[0]}',
                                              style: TextStyle(
                                                color: CupertinoColors.label
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.time,
                                              color: CupertinoColors.activeBlue
                                                  .resolveFrom(context),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // End Time field
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        showCupertinoModalPopup(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Container(
                                              height: 216,
                                              padding: const EdgeInsets.only(
                                                top: 6.0,
                                              ),
                                              margin: EdgeInsets.only(
                                                bottom:
                                                    MediaQuery.of(
                                                      context,
                                                    ).viewInsets.bottom,
                                              ),
                                              color: CupertinoColors
                                                  .systemBackground
                                                  .resolveFrom(context),
                                              child: SafeArea(
                                                top: false,
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                        ),
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Done',
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                        ),
                                                      ],
                                                    ),
                                                    Expanded(
                                                      child: CupertinoDatePicker(
                                                        mode:
                                                            CupertinoDatePickerMode
                                                                .dateAndTime,
                                                        initialDateTime:
                                                            endTime,
                                                        minimumDate: startTime,
                                                        maximumDate:
                                                            DateTime.now(),
                                                        onDateTimeChanged: (
                                                          DateTime newDate,
                                                        ) {
                                                          setState(
                                                            () =>
                                                                endTime =
                                                                    newDate,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemFill
                                              .resolveFrom(context),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: CupertinoColors.activeBlue
                                                .resolveFrom(context)
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${endTime.toLocal().toString().split('.')[0]}',
                                              style: TextStyle(
                                                color: CupertinoColors.label
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.time,
                                              color: CupertinoColors.activeBlue
                                                  .resolveFrom(context),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Session duration
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Session Duration',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemFill
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(
                                              endTime
                                                  .difference(startTime)
                                                  .inMilliseconds,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: CupertinoColors.label
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                          Icon(
                                            CupertinoIcons.timer,
                                            color: CupertinoColors.systemGrey
                                                .resolveFrom(context),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Notes field
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Session Notes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CupertinoTextField(
                                      controller: notesController,
                                      placeholder:
                                          'What did you accomplish in this session?',
                                      maxLines: 5,
                                      minLines: 3,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemFill
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: CupertinoColors.activeBlue
                                              .resolveFrom(context)
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  void _showDeleteSessionDialog(BuildContext context, TaskSession session) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Session'),
            content: Text(
              'Are you sure you want to delete this session from ${session.startTime.toLocal().toString().split('.')[0]}?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () {
                  widget.task.sessions.removeWhere((s) => s.id == session.id);
                  widget.task.totalDuration = widget.task.sessions.fold<int>(
                    0,
                    (sum, s) => sum + (s.endTime != null ? s.duration : 0),
                  );
                  widget.task.save();
                  _loadSessions();
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  void _showAllSessions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Sessions',
                      style:
                          CupertinoTheme.of(
                            context,
                          ).textTheme.navTitleTextStyle,
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder:
                        (context, index) =>
                            _buildSessionItem(context, _sessions[index]),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            context,
            icon: CupertinoIcons.play_fill,
            label: 'Start',
            color: CupertinoColors.activeGreen,
            onPressed:
                widget.task.isDone || widget.task.isInProgress
                    ? null
                    : () {
                      widget.taskManagerCubit.startTask(widget.task);
                      setState(() {});
                    },
          ),
          _buildControlButton(
            context,
            icon: CupertinoIcons.pause_fill,
            label: 'Pause',
            color: CupertinoColors.systemOrange,
            onPressed:
                widget.task.isInProgress
                    ? () {
                      widget.taskManagerCubit.pauseTask(widget.task);
                      setState(() {});
                    }
                    : null,
          ),
          _buildControlButton(
            context,
            icon: CupertinoIcons.stop_fill,
            label: 'Stop',
            color: CupertinoColors.destructiveRed,
            onPressed:
                widget.task.isInProgress || widget.task.isPaused
                    ? () {
                      widget.taskManagerCubit.stopTask(widget.task);
                      setState(() {});
                    }
                    : null,
          ),
          _buildControlButton(
            context,
            icon: CupertinoIcons.add,
            label: 'Add Session',
            color: CupertinoColors.systemBlue,
            onPressed: () => _showAddSessionDialog(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Task>>(
      valueListenable: Hive.box<Task>('tasks').listenable(),
      builder: (context, box, _) {
        final task = box.get(widget.task.id) ?? widget.task;
        _loadSessions();
        final totalDuration = widget.taskManagerCubit.getTotalDuration(task);
        final activeSession = task.activeSession;
        final sessionStats = _calculateSessionStats();

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.1),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 20,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sessions',
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.navTitleTextStyle.copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  Text(
                    'Total: ${_formatDuration(totalDuration)}',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_sessions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemFill.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Statistics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: CupertinoIcons.time,
                              label: 'Avg. Duration',
                              value: _formatDuration(
                                sessionStats['avgDuration'],
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: CupertinoIcons.chart_bar,
                              label: 'Most Productive',
                              value: '${sessionStats['mostProductiveHour']}:00',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: CupertinoIcons.checkmark_circle,
                              label: 'Completed',
                              value:
                                  '${sessionStats['completedSessions']}/${sessionStats['totalSessions']}',
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: CupertinoIcons.calendar,
                              label: 'First Session',
                              value:
                                  _sessions.isNotEmpty
                                      ? '${_sessions.last.startTime.day}/${_sessions.last.startTime.month}'
                                      : 'N/A',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: CupertinoIcons.chart_pie,
                              label: 'Time Efficiency',
                              value:
                                  sessionStats['timeEfficiencyRatio'] != null
                                      ? '${(sessionStats['timeEfficiencyRatio'] * 100).toStringAsFixed(0)}%'
                                      : 'N/A',
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: CupertinoIcons.info_circle,
                              label: 'Estimation',
                              value: sessionStats['timeEfficiencyDescription'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (activeSession != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeGreen
                        .resolveFrom(context)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.activeGreen
                          .resolveFrom(context)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.timer,
                            color: CupertinoColors.activeGreen.resolveFrom(
                              context,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session in progress',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.activeGreen
                                        .resolveFrom(context),
                                  ),
                                ),
                                Text(
                                  'Started at ${activeSession.startTime.hour.toString().padLeft(2, '0')}:${activeSession.startTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatDuration(activeSession.duration),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.activeGreen.resolveFrom(
                                context,
                              ),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                              Text(
                                '${((activeSession.duration / widget.task.estimatedTime) * 100).clamp(0, 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.activeGreen
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemFill.resolveFrom(
                                    context,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                height: 8,
                                width:
                                    (MediaQuery.of(context).size.width - 64) *
                                    (activeSession.duration /
                                            widget.task.estimatedTime)
                                        .clamp(0, 1),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.activeGreen
                                      .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Elapsed: ${_formatDuration(activeSession.duration)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                              Text(
                                'Estimated: ${_formatDuration(widget.task.estimatedTime)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              _buildControlButtons(context),
              if (_sessions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  'Recent Sessions',
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(_sessions
                    .take(5)
                    .map((session) => _buildSessionItem(context, session))),
                if (_sessions.length > 5) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'View all ${_sessions.length} sessions',
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(color: CupertinoColors.activeBlue),
                      ),
                      onPressed: () => _showAllSessions(context),
                    ),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'No sessions yet',
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.textStyle.copyWith(
                      color: CupertinoColors.systemGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

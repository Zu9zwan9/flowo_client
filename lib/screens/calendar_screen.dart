import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/utils/date_time_formatter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../blocs/tasks_controller/task_manager_state.dart';
import '../models/scheduled_task.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTime selectedDate = DateTime.now();

  void _onDateSelected(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
    });
    context.read<CalendarCubit>().selectDate(newDate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Calendar'),
      ),
      child: SafeArea(child: _buildSplitView()),
    );
  }

  Widget _buildSplitView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 400,
          child: _buildCalendar(showAgenda: false, context: context),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Text(
            '${_weekdayName(selectedDate.weekday)}, ${_monthName(selectedDate.month)} ${selectedDate.day}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
        ),
        Expanded(
          child: _buildCustomAgenda(),
        ),
      ],
    );
  }

  Widget _buildCalendar(
      {required bool showAgenda, required BuildContext context}) {
    return BlocBuilder<TaskManagerCubit, TaskManagerState>(
      builder: (context, state) {
        return SfCalendar(
          view: CalendarView.month,
          showNavigationArrow: true,
          showDatePickerButton: true,
          dataSource: TaskDataSource(
              context.read<TaskManagerCubit>().getScheduledTasks()),
          initialSelectedDate: selectedDate,
          onTap: (details) {
            if (details.date != null) {
              _onDateSelected(details.date!);
            }
          },
          monthViewSettings: MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            showAgenda: showAgenda,
            agendaStyle: const AgendaStyle(
              appointmentTextStyle:
                  TextStyle(fontSize: 14, color: CupertinoColors.black),
              dateTextStyle:
                  TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
              dayTextStyle:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          selectionDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: CupertinoColors.activeBlue.withOpacity(0.2),
          ),
          todayHighlightColor: CupertinoColors.activeBlue,
          headerStyle: const CalendarHeaderStyle(
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          viewHeaderStyle: const ViewHeaderStyle(
            dayTextStyle:
                TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
          ),
          appointmentTextStyle: const TextStyle(fontSize: 14),
        );
      },
    );
  }

  Widget _buildCustomAgenda() {
    final brightness = CupertinoTheme.of(context).brightness;
    final containerColor = brightness == Brightness.dark
        ? CupertinoColors.darkBackgroundGray
        : CupertinoColors.white;
    final textColor = brightness == Brightness.dark
        ? CupertinoColors.white
        : CupertinoColors.black;
    final secondaryTextColor = brightness == Brightness.dark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey;

    return FutureBuilder<List<TaskWithSchedules>>(
      future: context
          .read<TaskManagerCubit>()
          .getScheduledTasksForDate(selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: secondaryTextColor)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text('No tasks scheduled',
                  style: TextStyle(fontSize: 16, color: secondaryTextColor)));
        } else {
          final taskSchedulePairs = snapshot.data!
              .expand((taskWithSchedules) => taskWithSchedules.scheduledTasks
                  .map((scheduledTask) => (
                        task: taskWithSchedules.task,
                        scheduledTask: scheduledTask
                      )))
              .toList()
            ..sort((a, b) =>
                a.scheduledTask.startTime.compareTo(b.scheduledTask.startTime));

          return CupertinoScrollbar(
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: taskSchedulePairs.length,
              itemBuilder: (context, index) {
                final pair = taskSchedulePairs[index];
                final task = pair.task;
                final scheduledTask = pair.scheduledTask;
                final startTime = scheduledTask.startTime;
                final endTime = scheduledTask.endTime;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(height: 6),
                            Text(DateTimeFormatter.formatTime(startTime),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor)),
                            const SizedBox(height: 16),
                            Text(DateTimeFormatter.formatTime(endTime),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 1),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: containerColor,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      CupertinoColors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                color: _getCategoryColor(task.category.name),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title == 'Free Time'
                                          ? scheduledTask.type
                                              .toString()
                                              .split('.')
                                              .last
                                          : task.title,
                                      style: CupertinoTheme.of(context)
                                          .textTheme
                                          .textStyle
                                          .copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: textColor),
                                    ),
                                    if (task.notes != null &&
                                        task.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        task.notes!,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: secondaryTextColor),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'brainstorm':
        return CupertinoColors.systemBlue;
      case 'design':
        return CupertinoColors.systemGreen;
      case 'workout':
        return CupertinoColors.systemRed;
      case 'meeting':
        return CupertinoColors.systemOrange;
      case 'presentation':
        return CupertinoColors.systemPurple;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}

class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<ScheduledTask> scheduledTasks) {
    appointments = scheduledTasks;
  }

  @override
  DateTime getStartTime(int index) => appointments![index].startTime;

  @override
  DateTime getEndTime(int index) => appointments![index].endTime;

  @override
  String getSubject(int index) =>
      appointments![index].parentTask?.title ?? 'Untitled';

  @override
  Color getColor(int index) => _getCategoryColor(
      appointments![index].parentTask?.category.name ?? 'default');
}

Color _getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'brainstorm':
      return CupertinoColors.systemBlue;
    case 'design':
      return CupertinoColors.systemGreen;
    case 'workout':
      return CupertinoColors.systemRed;
    case 'meeting':
      return CupertinoColors.systemOrange;
    case 'presentation':
      return CupertinoColors.systemPurple;
    default:
      return CupertinoColors.systemGrey;
  }
}

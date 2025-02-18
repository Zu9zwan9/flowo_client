import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/task.dart';
import '../models/scheduled_task.dart';
import '../blocs/calendar/calendar_cubit.dart';
import '../blocs/calendar/calendar_state.dart';
import 'widgets/task_card.dart';
import '../utils/logger.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    logInfo('Building CalendarScreen');
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Calendar'),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 12.0, right: 12.0),
        child: BlocBuilder<CalendarCubit, CalendarState>(
          builder: (context, state) {
            logDebug('CalendarState updated: ${state.status}');
            return Column(
              children: [
                _buildHeader(context, state),
                const SizedBox(height: 20),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.lightBackgroundGray,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: SfCalendar(
                      view: CalendarView.month,
                      dataSource: TaskDataSource(state.tasks),
                      headerHeight: 0,
                      onTap: (details) {
                        if (details.appointments != null &&
                            details.appointments!.isNotEmpty) {
                          final task = details.appointments!.first as Task;
                          logDebug('Tapped on task: ${task.title}');
                        }
                      },
                      onSelectionChanged: (details) {
                        if (details.date != null) {
                          context.read<CalendarCubit>().selectDate(details.date!);
                          logDebug('Date selected: ${details.date}');
                        }
                      },
                      monthViewSettings: const MonthViewSettings(
                        appointmentDisplayMode:
                        MonthAppointmentDisplayMode.indicator,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  flex: 1,
                  child: _buildTasksList(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CalendarState state) {
    final selectedDate = state.selectedDate;
    final monthYear = "${_getMonthName(selectedDate.month)} ${selectedDate.year}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: CupertinoColors.extraLightBackgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              final newDate = _changeMonth(selectedDate, -1);
              context.read<CalendarCubit>().selectDate(newDate);
              logDebug('Previous month selected: $newDate');
            },
            child: const Icon(CupertinoIcons.left_chevron, size: 28),
          ),
          Text(
            monthYear,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              final newDate = _changeMonth(selectedDate, 1);
              context.read<CalendarCubit>().selectDate(newDate);
              logDebug('Next month selected: $newDate');
            },
            child: const Icon(CupertinoIcons.right_chevron, size: 28),
          ),
        ],
      ),
    );
  }

  // Adjusts the month considering year changes and day overflow.
  DateTime _changeMonth(DateTime date, int delta) {
    int newYear = date.year;
    int newMonth = date.month + delta;

    if (newMonth < 1) {
      newYear -= 1;
      newMonth = 12;
    } else if (newMonth > 12) {
      newYear += 1;
      newMonth = 1;
    }
    // Calculate last day of the new month
    int lastDay = DateTime(newYear, newMonth + 1, 0).day;
    int newDay = date.day > lastDay ? lastDay : date.day;
    return DateTime(newYear, newMonth, newDay);
  }

  Widget _buildTasksList(BuildContext context, CalendarState state) {
    return FutureBuilder<List<ScheduledTask>>(
      future: context.read<CalendarCubit>().getTasksForSelectedDate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (snapshot.hasError) {
          logError('Error loading tasks: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No tasks found',
              style: TextStyle(fontSize: 20, color: CupertinoColors.inactiveGray),
            ),
          );
        } else {
          final tasks = snapshot.data!;
          logDebug('Loaded ${tasks.length} tasks');
          return ListView.separated(
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: CupertinoColors.systemGrey,
            ),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: TaskCard(task: task.parentTask),
              );
            },
          );
        }
      },
    );
  }

  // Helper to get month name from month number
  String _getMonthName(int month) {
    const List<String> monthNames = [
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
    return monthNames[month - 1];
  }
}

class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Task> tasks) {
    appointments = tasks;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startDate;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endDate;
  }

  @override
  String getSubject(int index) {
    return appointments![index].title;
  }

  @override
  Color getColor(int index) {
    switch (appointments![index].category.name) {
      case 'Brainstorm':
        return Colors.blue;
      case 'Design':
        return Colors.green;
      case 'Workout':
        return Colors.red;
      case 'Meeting':
        return Colors.orange;
      case 'Presentation':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flowo_client/blocs/calendar/calendar_cubit.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/date_time_formatter.dart';
import '../blocs/calendar/calendar_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  bool _showTaskList = true; // Toggle for task list visibility

  void _onDateSelected(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
    });
    context.read<CalendarCubit>().selectDate(newDate);
  }

  void _toggleTaskList() {
    setState(() {
      _showTaskList = !_showTaskList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _toggleTaskList,
          child: Text(_showTaskList ? 'Agenda' : 'List',
              style: const TextStyle(fontSize: 16)),
        ),
      ),
      child: SafeArea(
        child: _showTaskList ? _buildSplitView() : _buildAgendaView(),
      ),
    );
  }

  Widget _buildSplitView() {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: _buildCalendar(showAgenda: false),
        ),
        Expanded(
          child: _buildTaskList(),
        ),
      ],
    );
  }

  Widget _buildAgendaView() {
    return _buildCalendar(showAgenda: true);
  }

  Widget _buildCalendar({required bool showAgenda}) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        return SfCalendar(
          view: CalendarView.month,
          showNavigationArrow: true,
          showDatePickerButton: true,
          dataSource: TaskDataSource(state.tasks),
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
            shape: BoxShape.circle,
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
          appointmentTextStyle:
              const TextStyle(fontSize: 14), // Ensure valid font size
        );
      },
    );
  }

  Widget _buildTaskList() {
    return FutureBuilder<List<Task>>(
      future: context.read<CalendarCubit>().getTasksForDay(selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No events',
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
          );
        } else {
          final tasks = snapshot.data!;
          return CupertinoScrollbar(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
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
                              task.title,
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateTimeFormatter.formatTime(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      task.deadline)),
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    fontSize: 14,
                                    color: CupertinoColors.systemGrey,
                                  ),
                            ),
                          ],
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
    switch (category) {
      case 'Brainstorm':
        return CupertinoColors.systemBlue;
      case 'Design':
        return CupertinoColors.systemGreen;
      case 'Workout':
        return CupertinoColors.systemRed;
      case 'Meeting':
        return CupertinoColors.systemOrange;
      case 'Presentation':
        return CupertinoColors.systemPurple;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}

class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Task> tasks) {
    appointments = tasks;
  }

  @override
  DateTime getStartTime(int index) {
    return DateTime.fromMillisecondsSinceEpoch(appointments![index].deadline);
  }

  @override
  DateTime getEndTime(int index) {
    final task = appointments![index];
    return DateTime.fromMillisecondsSinceEpoch(
        task.deadline + task.estimatedTime);
  }

  @override
  String getSubject(int index) {
    return appointments![index].title.isNotEmpty
        ? appointments![index].title
        : 'Untitled';
  }
}

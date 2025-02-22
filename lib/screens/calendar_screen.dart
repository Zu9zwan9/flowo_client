import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flowo_client/blocs/calendar/calendar_cubit.dart';
import 'package:flowo_client/models/task.dart';
import '../blocs/calendar/calendar_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();

  void _onDateSelected(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
    });
    context.read<CalendarCubit>().selectDate(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),
      child: SafeArea(
        child: _buildCalendar(),
      ),
    );
  }

  Widget _buildCalendar() {
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
          monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            showAgenda: true, // Display tasks in the agenda view
            agendaStyle: AgendaStyle(
              appointmentTextStyle:
                  TextStyle(fontSize: 14, color: CupertinoColors.black),
              dateTextStyle:
                  TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
              dayTextStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label),
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

  @override
  Color getColor(int index) {
    return _getCategoryColor(appointments![index].category.name);
  }
}

// Helper method to avoid duplication in CalendarScreen and TaskDataSource
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

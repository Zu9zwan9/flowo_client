import 'dart:io';

import 'package:flowo_client/utils/formatter/date_time_formatter.dart';
import 'package:flutter/cupertino.dart';

import '../../design/cupertino_form_theme.dart';
import '../../models/task.dart';
import 'event_form_screen.dart';

// Interface for navigation to ensure dependency inversion (SOLID: DIP)
abstract class EventNavigator {
  void navigateToEditScreen(BuildContext context);
}

// Concrete implementation of EventNavigator
class EventNavigatorImpl implements EventNavigator {
  const EventNavigatorImpl();
  @override
  void navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => EventFormScreen()),
    );
  }
}

// Main EventScreen widget
class EventScreen extends StatelessWidget {
  final Task event;
  final EventNavigator navigator;

  EventScreen({
    super.key,
    required this.event,
    this.navigator = const EventNavigatorImpl(),
  });

  @override
  Widget build(BuildContext context) {
    return EventScreenContent(
      event: event,
      navigator: navigator,
      theme: CupertinoFormTheme(context),
    );
  }
}

// Separated content widget for better testability and SRP (SOLID)
class EventScreenContent extends StatelessWidget {
  final Task event;
  final EventNavigator navigator;
  final CupertinoFormTheme theme;

  const EventScreenContent({
    super.key,
    required this.event,
    required this.navigator,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scheduledTask =
        event.scheduledTasks.isNotEmpty ? event.scheduledTasks.first : null;

    return CupertinoPageScaffold(
      navigationBar: _buildNavigationBar(context),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(CupertinoFormTheme.horizontalSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Event Details'),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                label: 'Title',
                value: event.title,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (scheduledTask != null) ...[
                _buildDetailRow(
                  context,
                  label: 'Start',
                  value: DateTimeFormatter.formatDateTime(
                    scheduledTask.startTime,
                  ),
                  labelColor: CupertinoColors.systemGreen,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  label: 'End',
                  value: DateTimeFormatter.formatDateTime(
                    scheduledTask.endTime,
                  ),
                  labelColor: CupertinoColors.systemOrange,
                ),
                const SizedBox(height: 12),
              ],
              if (event.location != null &&
                  event.location!.toString().isNotEmpty)
                _buildDetailRow(
                  context,
                  label: 'Location',
                  value: event.location?.toString() ?? '',
                ),
              if (event.location != null &&
                  event.location!.toString().isNotEmpty)
                const SizedBox(height: 12),
              if (event.notes != null && event.notes!.isNotEmpty)
                _buildDetailRow(context, label: 'Notes', value: event.notes!),
              if (event.notes != null && event.notes!.isNotEmpty)
                const SizedBox(height: 12),
              if (event.color != null) ...[
                _buildColorSection(context),
                const SizedBox(height: 12),
              ],
              if (scheduledTask != null && scheduledTask.travelingTime > 0)
                _buildDetailRow(
                  context,
                  label: 'Traveling Time',
                  value:
                      '${scheduledTask.travelingTime ~/ 3600000}h ${(scheduledTask.travelingTime % 3600000) ~/ 60000}m',
                ),
              if (scheduledTask != null && scheduledTask.travelingTime > 0)
                const SizedBox(height: 12),
              if (event.image != null) _buildImageSection(),
            ],
          ),
        ),
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar(BuildContext context) {
    return CupertinoNavigationBar(
      middle: const Text('Event Details'),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => navigator.navigateToEditScreen(context),
        child: const Text(
          'Edit',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.label,
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? labelColor,
    TextStyle? style,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 16,
            color: labelColor ?? CupertinoColors.systemBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style:
                style ??
                CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color:',
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.systemBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(event.color!),
            border: Border.all(color: CupertinoColors.systemGrey, width: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        event.image as File,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: CupertinoColors.systemGrey6,
            child: const Center(
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.systemRed,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }
}

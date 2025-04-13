import 'package:flowo_client/screens/widgets/cupertino_task_form.dart';
import 'package:flowo_client/services/notification/notification_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final NotiService _notiService = NotiService();
  DateTime _selectedDateTime = DateTime.now();
  final _titleController = TextEditingController(text: "Test Notification");
  final _bodyController = TextEditingController(
    text: "This is a test notification",
  );
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _notiService.initNotification();
    _selectedDateTime = DateTime.now().add(const Duration(minutes: 5));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    final now = DateTime.now();
    final initialDateTime =
        _selectedDateTime.isBefore(now) ? now : _selectedDateTime;

    final pickedDateTime = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed:
                          () => Navigator.pop(context, _selectedDateTime),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: initialDateTime,
                    minimumDate: DateTime.now().subtract(
                      const Duration(hours: 12),
                    ),
                    maximumDate: DateTime.now().add(const Duration(days: 365)),
                    onDateTimeChanged: (dateTime) {
                      setState(() {
                        _selectedDateTime = dateTime;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
    );

    if (pickedDateTime != null && mounted) {
      setState(() {
        _selectedDateTime = pickedDateTime;
      });
    }
  }

  void _scheduleNotification() {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      _notiService
          .scheduleNotification(
            id: _nextId++,
            title: _titleController.text,
            body: _bodyController.text,
            year: _selectedDateTime.year,
            month: _selectedDateTime.month,
            day: _selectedDateTime.day,
            hour: _selectedDateTime.hour,
            minute: _selectedDateTime.minute,
          )
          .then((error) {
            setState(() {});
            showCupertinoDialog(
              context: context,
              builder:
                  (context) => CupertinoAlertDialog(
                    title: Text(error == null ? 'Success' : 'Error'),
                    content: Text(
                      error ??
                          'Notification scheduled for ${_selectedDateTime.toString().substring(0, 16)}',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
            );
          });
    }
  }

  void _sendNow() {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      _notiService
          .showNotification(
            id: _nextId++,
            title: _titleController.text,
            body: _bodyController.text,
          )
          .then((_) {
            setState(() {});
            showCupertinoDialog(
              context: context,
              builder:
                  (context) => CupertinoAlertDialog(
                    title: const Text('Success'),
                    content: const Text('Notification sent immediately'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
            );
          });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return CupertinoColors.systemYellow;
      case 'delivered':
        return CupertinoColors.systemGreen;
      case 'failed':
        return CupertinoColors.systemRed;
      case 'cancelled':
        return CupertinoColors.systemGrey;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = CupertinoTaskForm(context);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: CupertinoTaskForm.horizontalSpacing,
            vertical: CupertinoTaskForm.verticalSpacing,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              form.sectionTitle('Schedule New Notification'),
              Form(
                key: _formKey,
                child: form.formGroup(
                  children: [
                    form.textField(
                      controller: _titleController,
                      placeholder: 'Notification Title *',
                      validator:
                          (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: CupertinoTaskForm.elementSpacing),
                    form.textField(
                      controller: _bodyController,
                      placeholder: 'Notification Body',
                      maxLines: 3,
                    ),
                    const SizedBox(height: CupertinoTaskForm.elementSpacing),
                    form.selectionButton(
                      label: 'Date & Time',
                      value: _selectedDateTime.toString().substring(0, 16),
                      onTap: () => _showDateTimePicker(context),
                      icon: CupertinoIcons.calendar,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CupertinoTaskForm.sectionSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  form.primaryButton(text: 'Send Now', onPressed: _sendNow),
                  const SizedBox(width: 16),
                  form.primaryButton(
                    text: 'Schedule',
                    onPressed: _scheduleNotification,
                  ),
                ],
              ),
              const SizedBox(height: CupertinoTaskForm.sectionSpacing * 2),
              form.sectionTitle('Scheduled Notifications'),
              if (_notiService.notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'No notifications scheduled yet',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                )
              else
                form.formGroup(
                  children:
                      _notiService.notifications
                          .map(
                            (noti) => Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            noti.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            noti.scheduledTime
                                                .toString()
                                                .substring(0, 16),
                                            style: TextStyle(
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              noti.status,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            noti.status,
                                            style: TextStyle(
                                              color: _getStatusColor(
                                                noti.status,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (noti.status == 'pending')
                                          CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            child: const Icon(
                                              CupertinoIcons.xmark_circle,
                                            ),
                                            onPressed: () {
                                              _notiService.cancelNotification(
                                                noti.id,
                                              );
                                              setState(() {});
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          )
                          .toList(),
                ),
              const SizedBox(height: CupertinoTaskForm.verticalSpacing),
            ],
          ),
        ),
      ),
    );
  }
}

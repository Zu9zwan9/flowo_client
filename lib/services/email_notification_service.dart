import 'package:flowo_client/interfaces/notification_service.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailNotificationService implements IEmailNotificationService {
  bool _isInitialized = false;
  String _senderEmail = 'flowo.planning@gmail.com';
  String _recipientEmail = '';

  // This would typically be stored securely, not hardcoded
  // For a production app, use environment variables or a secure storage solution
  final String _password =
      'app_password_here'; // Replace with actual app password

  late SmtpServer _smtpServer;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up the SMTP server for Gmail
      _smtpServer = gmail(_senderEmail, _password);

      _isInitialized = true;
      logInfo('Email notification service initialized');
    } catch (e) {
      logError('Failed to initialize email notification service: $e');
      rethrow;
    }
  }

  @override
  void setSenderEmail(String email) {
    if (isValidEmail(email)) {
      _senderEmail = email;
      _isInitialized = false; // Require re-initialization with new email
      logInfo('Sender email updated to: $email');
    } else {
      logError('Invalid sender email: $email');
      throw ArgumentError('Invalid email format');
    }
  }

  @override
  void setRecipientEmail(String email) {
    if (isValidEmail(email)) {
      _recipientEmail = email;
      logInfo('Recipient email updated to: $email');
    } else {
      logError('Invalid recipient email: $email');
      throw ArgumentError('Invalid email format');
    }
  }

  @override
  bool isValidEmail(String email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  @override
  Future<void> notifyTaskStart(Task task, ScheduledTask scheduledTask) async {
    if (!_isInitialized) await initialize();
    if (_recipientEmail.isEmpty) {
      logWarning('No recipient email set, cannot send task start notification');
      return;
    }

    try {
      final message =
          Message()
            ..from = Address(_senderEmail, 'Flowo Planning')
            ..recipients.add(_recipientEmail)
            ..subject = 'Task Started: ${task.title}'
            ..html = '''
          <h1>Task Started</h1>
          <p>Your task "${task.title}" has started.</p>
          <p><strong>Details:</strong></p>
          <ul>
            <li>Priority: ${task.priority}</li>
            <li>Category: ${task.category.name}</li>
            <li>Estimated Time: ${_formatDuration(task.estimatedTime)}</li>
            ${task.notes != null && task.notes!.isNotEmpty ? '<li>Notes: ${task.notes}</li>' : ''}
          </ul>
          <p>Open the Flowo app to view more details.</p>
        ''';

      final sendReport = await send(message, _smtpServer);
      logInfo('Task start email notification sent: ${sendReport.toString()}');
    } catch (e) {
      logError('Failed to send task start email notification: $e');
    }
  }

  @override
  Future<void> notifyTaskReminder(
    Task task,
    ScheduledTask scheduledTask,
    Duration timeBeforeStart,
  ) async {
    if (!_isInitialized) await initialize();
    if (_recipientEmail.isEmpty) {
      logWarning(
        'No recipient email set, cannot send task reminder notification',
      );
      return;
    }

    try {
      // Calculate minutes before start
      final minutes = timeBeforeStart.inMinutes;
      final reminderText =
          minutes > 0 ? 'Starting in $minutes minutes' : 'Starting now';

      final message =
          Message()
            ..from = Address(_senderEmail, 'Flowo Planning')
            ..recipients.add(_recipientEmail)
            ..subject = 'Reminder: ${task.title}'
            ..html = '''
          <h1>Task Reminder</h1>
          <p>Your task "${task.title}" is $reminderText.</p>
          <p><strong>Details:</strong></p>
          <ul>
            <li>Priority: ${task.priority}</li>
            <li>Category: ${task.category.name}</li>
            <li>Estimated Time: ${_formatDuration(task.estimatedTime)}</li>
            ${task.notes != null && task.notes!.isNotEmpty ? '<li>Notes: ${task.notes}</li>' : ''}
          </ul>
          <p>Open the Flowo app to view more details.</p>
        ''';

      final sendReport = await send(message, _smtpServer);
      logInfo(
        'Task reminder email notification sent: ${sendReport.toString()}',
      );
    } catch (e) {
      logError('Failed to send task reminder email notification: $e');
    }
  }

  @override
  Future<void> cancelNotification(String taskId) async {
    // Email notifications cannot be "cancelled" once sent
    // This method is implemented for interface compliance
    logInfo(
      'Email notifications for task $taskId cannot be cancelled once sent',
    );
  }

  @override
  Future<void> cancelAllNotifications() async {
    // Email notifications cannot be "cancelled" once sent
    // This method is implemented for interface compliance
    logInfo('Email notifications cannot be cancelled once sent');
  }

  String _formatDuration(int milliseconds) {
    final minutes = (milliseconds / (1000 * 60)).round();
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '$hours hours${remainingMinutes > 0 ? ' $remainingMinutes minutes' : ''}';
    }
  }
}

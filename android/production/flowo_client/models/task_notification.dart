import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_notification.g.dart';

/// Types of notifications that can be scheduled for tasks
@HiveType(typeId: 8)
enum TaskNotificationType {
  @HiveField(0)
  start, // Notification at the start of a task
  
  @HiveField(1)
  end, // Notification at the end of a task
  
  @HiveField(2)
  reminder, // Reminder before the task starts
  
  @HiveField(3)
  custom, // Custom notification at a specific time
}

/// Status of a notification
@HiveType(typeId: 9)
enum NotificationStatus {
  @HiveField(0)
  pending, // Notification is scheduled but not yet delivered
  
  @HiveField(1)
  delivered, // Notification has been delivered
  
  @HiveField(2)
  cancelled, // Notification has been cancelled
  
  @HiveField(3)
  failed, // Notification failed to deliver
}

/// Model for task notifications
@HiveType(typeId: 10)
class TaskNotification extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String body;
  
  @HiveField(3)
  DateTime scheduledTime;
  
  @HiveField(4)
  NotificationStatus status;
  
  @HiveField(5)
  TaskNotificationType type;
  
  @HiveField(6)
  String? parentId; // ID of the parent task, event, or habit
  
  @HiveField(7)
  int? minutesBefore; // For reminder type, minutes before the task starts
  
  @HiveField(8)
  int? notificationId; // ID used by the local notifications plugin
  
  TaskNotification({
    String? id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.status = NotificationStatus.pending,
    required this.type,
    this.parentId,
    this.minutesBefore,
    this.notificationId,
  }) : id = id ?? const Uuid().v4();
  
  /// Create a notification for the start of a task
  factory TaskNotification.start({
    required String title,
    required String body,
    required DateTime startTime,
    required String parentId,
    int? notificationId,
  }) {
    return TaskNotification(
      title: title,
      body: body,
      scheduledTime: startTime,
      type: TaskNotificationType.start,
      parentId: parentId,
      notificationId: notificationId,
    );
  }
  
  /// Create a notification for the end of a task
  factory TaskNotification.end({
    required String title,
    required String body,
    required DateTime endTime,
    required String parentId,
    int? notificationId,
  }) {
    return TaskNotification(
      title: title,
      body: body,
      scheduledTime: endTime,
      type: TaskNotificationType.end,
      parentId: parentId,
      notificationId: notificationId,
    );
  }
  
  /// Create a reminder notification before a task starts
  factory TaskNotification.reminder({
    required String title,
    required String body,
    required DateTime startTime,
    required int minutesBefore,
    required String parentId,
    int? notificationId,
  }) {
    return TaskNotification(
      title: title,
      body: body,
      scheduledTime: startTime.subtract(Duration(minutes: minutesBefore)),
      type: TaskNotificationType.reminder,
      parentId: parentId,
      minutesBefore: minutesBefore,
      notificationId: notificationId,
    );
  }
  
  /// Create a custom notification at a specific time
  factory TaskNotification.custom({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? parentId,
    int? notificationId,
  }) {
    return TaskNotification(
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      type: TaskNotificationType.custom,
      parentId: parentId,
      notificationId: notificationId,
    );
  }
  
  /// Convert to a map for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'scheduledTime': scheduledTime.toIso8601String(),
    'status': status.toString(),
    'type': type.toString(),
    'parentId': parentId,
    'minutesBefore': minutesBefore,
    'notificationId': notificationId,
  };
  
  /// Create from a map
  factory TaskNotification.fromJson(Map<String, dynamic> json) => TaskNotification(
    id: json['id'],
    title: json['title'],
    body: json['body'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    status: NotificationStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => NotificationStatus.pending,
    ),
    type: TaskNotificationType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => TaskNotificationType.custom,
    ),
    parentId: json['parentId'],
    minutesBefore: json['minutesBefore'],
    notificationId: json['notificationId'],
  );
}
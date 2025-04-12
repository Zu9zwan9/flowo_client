// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskNotificationAdapter extends TypeAdapter<TaskNotification> {
  @override
  final int typeId = 10;

  @override
  TaskNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskNotification(
      id: fields[0] as String?,
      title: fields[1] as String,
      body: fields[2] as String,
      scheduledTime: fields[3] as DateTime,
      status: fields[4] as NotificationStatus,
      type: fields[5] as TaskNotificationType,
      parentId: fields[6] as String?,
      minutesBefore: fields[7] as int?,
      notificationId: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskNotification obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.scheduledTime)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.parentId)
      ..writeByte(7)
      ..write(obj.minutesBefore)
      ..writeByte(8)
      ..write(obj.notificationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskNotificationTypeAdapter extends TypeAdapter<TaskNotificationType> {
  @override
  final int typeId = 8;

  @override
  TaskNotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskNotificationType.start;
      case 1:
        return TaskNotificationType.end;
      case 2:
        return TaskNotificationType.reminder;
      case 3:
        return TaskNotificationType.custom;
      default:
        return TaskNotificationType.start;
    }
  }

  @override
  void write(BinaryWriter writer, TaskNotificationType obj) {
    switch (obj) {
      case TaskNotificationType.start:
        writer.writeByte(0);
        break;
      case TaskNotificationType.end:
        writer.writeByte(1);
        break;
      case TaskNotificationType.reminder:
        writer.writeByte(2);
        break;
      case TaskNotificationType.custom:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskNotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationStatusAdapter extends TypeAdapter<NotificationStatus> {
  @override
  final int typeId = 9;

  @override
  NotificationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationStatus.pending;
      case 1:
        return NotificationStatus.delivered;
      case 2:
        return NotificationStatus.cancelled;
      case 3:
        return NotificationStatus.failed;
      default:
        return NotificationStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationStatus obj) {
    switch (obj) {
      case NotificationStatus.pending:
        writer.writeByte(0);
        break;
      case NotificationStatus.delivered:
        writer.writeByte(1);
        break;
      case NotificationStatus.cancelled:
        writer.writeByte(2);
        break;
      case NotificationStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

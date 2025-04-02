// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationPreferencesAdapter
    extends TypeAdapter<NotificationPreferences> {
  @override
  final int typeId = 12;

  @override
  NotificationPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationPreferences(
      enableTaskStartNotifications: fields[0] as bool,
      enableTaskReminderNotifications: fields[1] as bool,
      enableTaskCompletionNotifications: fields[2] as bool,
      reminderTimeMinutes: fields[3] as int,
      notificationSound: fields[4] as String?,
      vibrationPattern: fields[5] as String,
      useSystemColor: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationPreferences obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.enableTaskStartNotifications)
      ..writeByte(1)
      ..write(obj.enableTaskReminderNotifications)
      ..writeByte(2)
      ..write(obj.enableTaskCompletionNotifications)
      ..writeByte(3)
      ..write(obj.reminderTimeMinutes)
      ..writeByte(4)
      ..write(obj.notificationSound)
      ..writeByte(5)
      ..write(obj.vibrationPattern)
      ..writeByte(6)
      ..write(obj.useSystemColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 11;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      name: fields[0] as String,
      minSession: fields[1] as int,
      breakTime: fields[2] as int?,
      mealBreaks: (fields[3] as List).cast<TimeFrame>(),
      sleepTime: (fields[4] as List).cast<TimeFrame>(),
      freeTime: (fields[5] as List).cast<TimeFrame>(),
      activeDays: (fields[6] as Map?)?.cast<String, bool>(),
      defaultNotificationType: fields[7] as NotificationType,
      dateFormat: fields[8] as String,
      monthFormat: fields[9] as String,
      is24HourFormat: fields[10] as bool,
      notificationPreferences: fields[11] as NotificationPreferences?,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.minSession)
      ..writeByte(2)
      ..write(obj.breakTime)
      ..writeByte(3)
      ..write(obj.mealBreaks)
      ..writeByte(4)
      ..write(obj.sleepTime)
      ..writeByte(5)
      ..write(obj.freeTime)
      ..writeByte(6)
      ..write(obj.activeDays)
      ..writeByte(7)
      ..write(obj.defaultNotificationType)
      ..writeByte(8)
      ..write(obj.dateFormat)
      ..writeByte(9)
      ..write(obj.monthFormat)
      ..writeByte(10)
      ..write(obj.is24HourFormat)
      ..writeByte(11)
      ..write(obj.notificationPreferences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

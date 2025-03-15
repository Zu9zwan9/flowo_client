// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      defaultNotificationType:
          fields[7] as NotificationType? ?? NotificationType.sound,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.activeDays);
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

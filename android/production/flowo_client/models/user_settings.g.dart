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
      mealBreaks: (fields[2] as List).cast<TimeFrame>(),
      sleepTime: (fields[3] as List).cast<TimeFrame>(),
      freeTime: (fields[4] as List).cast<TimeFrame>(),
      activeDays: (fields[5] as Map?)?.cast<String, bool>(),
      daySchedules: (fields[6] as Map?)?.cast<String, DaySchedule>(),
      defaultNotificationType: fields[7] as NotificationType,
      dateFormat: fields[8] as String,
      monthFormat: fields[9] as String,
      is24HourFormat: fields[10] as bool,
      themeMode: fields[11] as AppTheme,
      customColorValue: fields[12] as int,
      colorIntensity: fields[13] as double,
      noiseLevel: fields[14] as double,
      useGradient: fields[15] as bool,
      secondaryColorValue: fields[16] as int?,
      useDynamicColors: fields[17] as bool,
      textSizeAdjustment: fields[18] as double?,
      reduceMotion: fields[19] as bool?,
      highContrastMode: fields[20] as bool?,
      gradientStartAlignment: fields[21] as String?,
      gradientEndAlignment: fields[22] as String?,
      usePertMethod: fields[23] as bool,
      schedules: (fields[24] as List?)?.cast<DaySchedule>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.minSession)
      ..writeByte(2)
      ..write(obj.mealBreaks)
      ..writeByte(3)
      ..write(obj.sleepTime)
      ..writeByte(4)
      ..write(obj.freeTime)
      ..writeByte(5)
      ..write(obj.activeDays)
      ..writeByte(6)
      ..write(obj.daySchedules)
      ..writeByte(7)
      ..write(obj.defaultNotificationType)
      ..writeByte(8)
      ..write(obj.dateFormat)
      ..writeByte(9)
      ..write(obj.monthFormat)
      ..writeByte(10)
      ..write(obj.is24HourFormat)
      ..writeByte(11)
      ..write(obj.themeMode)
      ..writeByte(12)
      ..write(obj.customColorValue)
      ..writeByte(13)
      ..write(obj.colorIntensity)
      ..writeByte(14)
      ..write(obj.noiseLevel)
      ..writeByte(15)
      ..write(obj.useGradient)
      ..writeByte(16)
      ..write(obj.secondaryColorValue)
      ..writeByte(17)
      ..write(obj.useDynamicColors)
      ..writeByte(18)
      ..write(obj.textSizeAdjustment)
      ..writeByte(19)
      ..write(obj.reduceMotion)
      ..writeByte(20)
      ..write(obj.highContrastMode)
      ..writeByte(21)
      ..write(obj.gradientStartAlignment)
      ..writeByte(22)
      ..write(obj.gradientEndAlignment)
      ..writeByte(23)
      ..write(obj.usePertMethod)
      ..writeByte(24)
      ..write(obj.schedules);
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

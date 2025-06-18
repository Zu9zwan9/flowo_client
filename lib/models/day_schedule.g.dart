// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DayScheduleAdapter extends TypeAdapter<DaySchedule> {
  @override
  final int typeId = 22;

  @override
  DaySchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Handle the case where day field might be a bool (old format) or List (new format)
    List<String> dayValue;
    if (fields[1] is bool) {
      // Convert old bool format to a list with a single day
      // This is a migration fix for existing data
      dayValue = ['Default'];
    } else if (fields[1] is List) {
      dayValue = (fields[1] as List).cast<String>();
    } else {
      // Fallback to a default value if the field is neither bool nor List
      dayValue = ['Default'];
    }
    // Migrate mealBreaks field (old format might be bool)
    List<TimeFrame> mealBreaksValue;
    if (fields[4] is bool) {
      mealBreaksValue = [];
    } else if (fields[4] is List) {
      mealBreaksValue = (fields[4] as List).cast<TimeFrame>();
    } else {
      mealBreaksValue = [];
    }
    // Migrate freeTimes field (old format might be bool)
    List<TimeFrame> freeTimesValue;
    if (fields[5] is bool) {
      freeTimesValue = [];
    } else if (fields[5] is List) {
      freeTimesValue = (fields[5] as List).cast<TimeFrame>();
    } else {
      freeTimesValue = [];
    }

    // Use migration values for mealBreaks and freeTimes
    return DaySchedule(
      name: fields[0] as String,
      day: dayValue,
      isActive: fields[2] as bool,
      sleepTime: fields[3] as TimeFrame,
      mealBreaks: mealBreaksValue,
      freeTimes: freeTimesValue,
    );
  }

  @override
  void write(BinaryWriter writer, DaySchedule obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.day)
      ..writeByte(2)
      ..write(obj.isActive)
      ..writeByte(3)
      ..write(obj.sleepTime)
      ..writeByte(4)
      ..write(obj.mealBreaks)
      ..writeByte(5)
      ..write(obj.freeTimes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

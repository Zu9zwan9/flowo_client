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

    // Handle the case where fields[1] is a boolean instead of a List
    List<String> dayList;
    if (fields[1] is List) {
      dayList = (fields[1] as List).cast<String>();
    } else if (fields[1] is bool) {
      // Convert boolean to a default list with a single day
      dayList = ['Monday']; // Default to Monday if it's a boolean
    } else {
      // Fallback for any other unexpected type
      dayList = [];
    }

    // Handle the case where fields[3] is a bool instead of a TimeFrame
    TimeFrame sleepTimeValue;
    if (fields[3] is TimeFrame) {
      sleepTimeValue = fields[3] as TimeFrame;
    } else {
      // Create a default TimeFrame if the field is not of the expected type
      sleepTimeValue = TimeFrame(
        startTime: TimeOfDay(hour: 22, minute: 0),
        endTime: TimeOfDay(hour: 7, minute: 0),
      );
    }

    return DaySchedule(
      name: fields[0] as String,
      day: dayList,
      isActive: fields[2] as bool,
      sleepTime: sleepTimeValue,
      mealBreaks: (fields[4] as List?)?.cast<TimeFrame>(),
      freeTimes: (fields[5] as List?)?.cast<TimeFrame>(),
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

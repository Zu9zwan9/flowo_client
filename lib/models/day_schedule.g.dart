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
    return DaySchedule(
      name: fields[0] as String,
      day: (fields[1] as List).cast<String>(),
      isActive: fields[2] as bool,
      sleepTime: fields[3] as TimeFrame,
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

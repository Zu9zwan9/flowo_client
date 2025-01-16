// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitTaskAdapter extends TypeAdapter<HabitTask> {
  @override
  final int typeId = 10;

  @override
  HabitTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitTask(
      title: fields[0] as String,
      startDate: fields[1] as DateTime,
      endDate: fields[2] as DateTime?,
      exceptions: (fields[3] as List).cast<DateTime>(),
      completedDates: (fields[4] as List).cast<DateTime>(),
      repeatRule: fields[5] as RepeatRule,
    );
  }

  @override
  void write(BinaryWriter writer, HabitTask obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.exceptions)
      ..writeByte(4)
      ..write(obj.completedDates)
      ..writeByte(5)
      ..write(obj.repeatRule);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

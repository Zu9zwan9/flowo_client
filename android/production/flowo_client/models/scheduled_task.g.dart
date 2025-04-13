// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduledTaskAdapter extends TypeAdapter<ScheduledTask> {
  @override
  final int typeId = 5;

  @override
  ScheduledTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduledTask(
      scheduledTaskId: fields[0] as String,
      parentTaskId: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime,
      urgency: fields[4] as double?,
      type: fields[5] as ScheduledTaskType,
      travelingTime: fields[6] as int,
      breakTime: fields[7] as int,
      notificationIds: (fields[8] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledTask obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.scheduledTaskId)
      ..writeByte(1)
      ..write(obj.parentTaskId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.urgency)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.travelingTime)
      ..writeByte(7)
      ..write(obj.breakTime)
      ..writeByte(8)
      ..write(obj.notificationIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

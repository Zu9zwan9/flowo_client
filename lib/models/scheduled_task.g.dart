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
      parentTask: fields[0] as Task,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      urgency: fields[3] as double?,
      type: fields[4] as ScheduledTaskType,
      travelingTime: fields[5] as int,
      breakTime: fields[6] as int,
      notification: fields[7] as NotificationType,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledTask obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.parentTask)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.urgency)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.travelingTime)
      ..writeByte(6)
      ..write(obj.breakTime)
      ..writeByte(7)
      ..write(obj.notification);
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskSessionAdapter extends TypeAdapter<TaskSession> {
  @override
  final int typeId = 21;

  @override
  TaskSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskSession(
      id: fields[0] as String,
      taskId: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

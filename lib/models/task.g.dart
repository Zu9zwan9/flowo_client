// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      title: fields[0] as String,
      priority: fields[1] as int,
      deadline: fields[2] as int,
      estimatedTime: fields[3] as int,
      category: fields[4] as Category,
      notes: fields[5] as String?,
      location: fields[6] as Coordinates?,
      image: fields[7] as String?,
      frequency: (fields[8] as List?)?.cast<Days>(),
      subtasks: (fields[9] as List).cast<Task>(),
      scheduledTask: (fields[10] as List).cast<ScheduledTask>(),
      isDone: fields[11] as bool,
      order: fields[12] as int,
      overdue: fields[13] as bool,
      urgency: fields[14] as double,
      minSession: fields[15] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.priority)
      ..writeByte(2)
      ..write(obj.deadline)
      ..writeByte(3)
      ..write(obj.estimatedTime)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.image)
      ..writeByte(8)
      ..write(obj.frequency)
      ..writeByte(9)
      ..write(obj.subtasks)
      ..writeByte(10)
      ..write(obj.scheduledTask)
      ..writeByte(11)
      ..write(obj.isDone)
      ..writeByte(12)
      ..write(obj.order)
      ..writeByte(13)
      ..write(obj.overdue)
      ..writeByte(14)
      ..write(obj.urgency)
      ..writeByte(15)
      ..write(obj.minSession);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

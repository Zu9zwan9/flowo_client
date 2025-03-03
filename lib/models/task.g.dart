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
      id: fields[0] as String,
      title: fields[1] as String,
      priority: fields[2] as int,
      deadline: fields[3] as int,
      estimatedTime: fields[4] as int,
      category: fields[5] as Category,
      parentTask: fields[11] as Task?,
      notes: fields[6] as String?,
      location: fields[7] as Coordinates?,
      image: fields[8] as String?,
      frequency: fields[9] as RepeatRule?,
      subtasks: (fields[10] as List).cast<Task>(),
      scheduledTasks: (fields[12] as List?)?.cast<ScheduledTask>(),
      isDone: fields[13] as bool,
      order: fields[14] as int?,
      overdue: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.priority)
      ..writeByte(3)
      ..write(obj.deadline)
      ..writeByte(4)
      ..write(obj.estimatedTime)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.image)
      ..writeByte(9)
      ..write(obj.frequency)
      ..writeByte(10)
      ..write(obj.subtasks)
      ..writeByte(11)
      ..write(obj.parentTask)
      ..writeByte(12)
      ..write(obj.scheduledTasks)
      ..writeByte(13)
      ..write(obj.isDone)
      ..writeByte(14)
      ..write(obj.order)
      ..writeByte(15)
      ..write(obj.overdue);
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

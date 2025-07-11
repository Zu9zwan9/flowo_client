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
      notes: fields[6] as String?,
      location: fields[7] as Coordinates?,
      image: fields[8] as String?,
      frequency: fields[9] as RepeatRule?,
      subtaskIds: (fields[10] as List?)?.cast<String>(),
      scheduledTasks: (fields[12] as List?)?.cast<ScheduledTask>(),
      isDone: fields[13] as bool,
      order: fields[14] as int?,
      overdue: fields[15] as bool,
      color: fields[16] as int?,
      optimisticTime: fields[17] as int?,
      realisticTime: fields[18] as int?,
      pessimisticTime: fields[19] as int?,
      firstNotification: fields[20] as int?,
      secondNotification: fields[21] as int?,
      status: fields[22] as String,
      totalDuration: fields[23] as int,
      sessions: (fields[24] as List?)?.cast<TaskSession>(),
    )
      ..parentTaskId = fields[11] as String?
      ..pausedSession = fields[25] as TaskSession?;
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(26)
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
      ..writeByte(17)
      ..write(obj.optimisticTime)
      ..writeByte(18)
      ..write(obj.realisticTime)
      ..writeByte(19)
      ..write(obj.pessimisticTime)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.image)
      ..writeByte(9)
      ..write(obj.frequency)
      ..writeByte(10)
      ..write(obj.subtaskIds)
      ..writeByte(11)
      ..write(obj.parentTaskId)
      ..writeByte(12)
      ..write(obj.scheduledTasks)
      ..writeByte(13)
      ..write(obj.isDone)
      ..writeByte(14)
      ..write(obj.order)
      ..writeByte(15)
      ..write(obj.overdue)
      ..writeByte(16)
      ..write(obj.color)
      ..writeByte(20)
      ..write(obj.firstNotification)
      ..writeByte(21)
      ..write(obj.secondNotification)
      ..writeByte(22)
      ..write(obj.status)
      ..writeByte(23)
      ..write(obj.totalDuration)
      ..writeByte(24)
      ..write(obj.sessions)
      ..writeByte(25)
      ..write(obj.pausedSession);
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

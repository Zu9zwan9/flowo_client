// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_task_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduledTaskTypeAdapter extends TypeAdapter<ScheduledTaskType> {
  @override
  final int typeId = 6;

  @override
  ScheduledTaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduledTaskType.defaultType;
      case 1:
        return ScheduledTaskType.timeSensitive;
      case 2:
        return ScheduledTaskType.rest;
      case 3:
        return ScheduledTaskType.mealBreak;
      case 4:
        return ScheduledTaskType.sleep;
      case 6:
        return ScheduledTaskType.freeTime;
      case 5:
        return ScheduledTaskType.work;
      default:
        return ScheduledTaskType.defaultType;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduledTaskType obj) {
    switch (obj) {
      case ScheduledTaskType.defaultType:
        writer.writeByte(0);
        break;
      case ScheduledTaskType.timeSensitive:
        writer.writeByte(1);
        break;
      case ScheduledTaskType.rest:
        writer.writeByte(2);
        break;
      case ScheduledTaskType.mealBreak:
        writer.writeByte(3);
        break;
      case ScheduledTaskType.sleep:
        writer.writeByte(4);
        break;
      case ScheduledTaskType.freeTime:
        writer.writeByte(6);
        break;
      case ScheduledTaskType.work:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledTaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroSessionAdapter extends TypeAdapter<PomodoroSession> {
  @override
  final int typeId = 15;

  @override
  PomodoroSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroSession(
        id: fields[0] as String,
        taskId: fields[1] as String?,
        totalDuration: fields[2] as int,
        breakDuration: fields[4] as int,
        completedPomodoros: fields[6] as int,
        targetPomodoros: fields[7] as int,
        startTime: fields[8] as DateTime?,
      )
      ..remainingDuration = fields[3] as int
      ..remainingBreakDuration = fields[5] as int
      ..endTime = fields[9] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, PomodoroSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.totalDuration)
      ..writeByte(3)
      ..write(obj.remainingDuration)
      ..writeByte(4)
      ..write(obj.breakDuration)
      ..writeByte(5)
      ..write(obj.remainingBreakDuration)
      ..writeByte(6)
      ..write(obj.completedPomodoros)
      ..writeByte(7)
      ..write(obj.targetPomodoros)
      ..writeByte(8)
      ..write(obj.startTime)
      ..writeByte(9)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PomodoroStateAdapter extends TypeAdapter<PomodoroState> {
  @override
  final int typeId = 14;

  @override
  PomodoroState read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PomodoroState.initial;
      case 1:
        return PomodoroState.running;
      case 2:
        return PomodoroState.paused;
      case 3:
        return PomodoroState.breakTime;
      case 4:
        return PomodoroState.completed;
      default:
        return PomodoroState.initial;
    }
  }

  @override
  void write(BinaryWriter writer, PomodoroState obj) {
    switch (obj) {
      case PomodoroState.initial:
        writer.writeByte(0);
        break;
      case PomodoroState.running:
        writer.writeByte(1);
        break;
      case PomodoroState.paused:
        writer.writeByte(2);
        break;
      case PomodoroState.breakTime:
        writer.writeByte(3);
        break;
      case PomodoroState.completed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

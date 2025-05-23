// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_statistics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroStatisticsAdapter extends TypeAdapter<PomodoroStatistics> {
  @override
  final int typeId = 18;

  @override
  PomodoroStatistics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroStatistics()
      .._totalSessions = fields[0] as int
      .._totalFocusTime = fields[1] as int
      .._dailySessions = (fields[2] as Map).cast<String, int>()
      .._dailyFocusTime = (fields[3] as Map).cast<String, int>()
      .._longestStreak = fields[4] as int
      .._currentStreak = fields[5] as int
      .._lastSessionDate = fields[6] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, PomodoroStatistics obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj._totalSessions)
      ..writeByte(1)
      ..write(obj._totalFocusTime)
      ..writeByte(2)
      ..write(obj._dailySessions)
      ..writeByte(3)
      ..write(obj._dailyFocusTime)
      ..writeByte(4)
      ..write(obj._longestStreak)
      ..writeByte(5)
      ..write(obj._currentStreak)
      ..writeByte(6)
      ..write(obj._lastSessionDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroStatisticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

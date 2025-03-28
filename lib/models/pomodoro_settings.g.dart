// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroSettingsAdapter extends TypeAdapter<PomodoroSettings> {
  @override
  final int typeId = 16;

  @override
  PomodoroSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroSettings(
      focusDuration: fields[0] as int,
      shortBreakDuration: fields[1] as int,
      longBreakDuration: fields[2] as int,
      sessionsBeforeLongBreak: fields[3] as int,
      autoStartBreaks: fields[4] as bool,
      autoStartNextSession: fields[5] as bool,
      soundEnabled: fields[6] as bool,
      vibrationEnabled: fields[7] as bool,
      notificationsEnabled: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj._focusDuration)
      ..writeByte(1)
      ..write(obj._shortBreakDuration)
      ..writeByte(2)
      ..write(obj._longBreakDuration)
      ..writeByte(3)
      ..write(obj._sessionsBeforeLongBreak)
      ..writeByte(4)
      ..write(obj._autoStartBreaks)
      ..writeByte(5)
      ..write(obj._autoStartNextSession)
      ..writeByte(6)
      ..write(obj._soundEnabled)
      ..writeByte(7)
      ..write(obj._vibrationEnabled)
      ..writeByte(8)
      ..write(obj._notificationsEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

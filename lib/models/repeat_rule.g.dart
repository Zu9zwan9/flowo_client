// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repeat_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepeatRuleAdapter extends TypeAdapter<RepeatRule> {
  @override
  final int typeId = 9;

  @override
  RepeatRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RepeatRule(
      frequency: fields[0] as String,
      interval: fields[1] as int,
      daysOfWeek: (fields[2] as List?)?.cast<int>(),
      daysOfMonth: (fields[3] as List?)?.cast<int>(),
      weekOfMonth: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RepeatRule obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.frequency)
      ..writeByte(1)
      ..write(obj.interval)
      ..writeByte(2)
      ..write(obj.daysOfWeek)
      ..writeByte(3)
      ..write(obj.daysOfMonth)
      ..writeByte(4)
      ..write(obj.weekOfMonth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

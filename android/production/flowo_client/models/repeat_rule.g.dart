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
      type: fields[0] as String,
      interval: fields[1] as int,
      count: fields[2] as int?,
      startRepeat: fields[3] as DateTime,
      endRepeat: fields[4] as DateTime?,
      byDay: (fields[5] as List?)?.cast<RepeatRuleInstance>(),
      byMonthDay: (fields[6] as List?)?.cast<RepeatRuleInstance>(),
      byMonth: (fields[7] as List?)?.cast<RepeatRuleInstance>(),
      bySetPos: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RepeatRule obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.interval)
      ..writeByte(2)
      ..write(obj.count)
      ..writeByte(3)
      ..write(obj.startRepeat)
      ..writeByte(4)
      ..write(obj.endRepeat)
      ..writeByte(5)
      ..write(obj.byDay)
      ..writeByte(6)
      ..write(obj.byMonthDay)
      ..writeByte(7)
      ..write(obj.byMonth)
      ..writeByte(8)
      ..write(obj.bySetPos);
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

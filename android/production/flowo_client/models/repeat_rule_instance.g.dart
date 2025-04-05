// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repeat_rule_instance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepeatRuleInstanceAdapter extends TypeAdapter<RepeatRuleInstance> {
  @override
  final int typeId = 17;

  @override
  RepeatRuleInstance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RepeatRuleInstance(
      selectedDay: fields[0] as String,
      name: fields[1] as String,
      start: fields[2] as TimeOfDay,
      end: fields[3] as TimeOfDay,
    );
  }

  @override
  void write(BinaryWriter writer, RepeatRuleInstance obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.selectedDay)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.start)
      ..writeByte(3)
      ..write(obj.end);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatRuleInstanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

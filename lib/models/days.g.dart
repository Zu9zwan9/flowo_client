// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'days.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DaysAdapter extends TypeAdapter<Days> {
  @override
  final int typeId = 4;

  @override
  Days read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Days(
      day: fields[0] as String,
      timeRanges: (fields[1] as List).cast<TimeRange>(),
    );
  }

  @override
  void write(BinaryWriter writer, Days obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.timeRanges);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DaysAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimeRangeAdapter extends TypeAdapter<TimeRange> {
  @override
  final int typeId = 8;

  @override
  TimeRange read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeRange(
      start: fields[0] as DateTime,
      end: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TimeRange obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.start)
      ..writeByte(1)
      ..write(obj.end);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

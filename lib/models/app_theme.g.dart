// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppThemeAdapter extends TypeAdapter<AppTheme> {
  @override
  final int typeId = 20;

  @override
  AppTheme read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppTheme.system;
      case 1:
        return AppTheme.light;
      case 2:
        return AppTheme.dark;
      case 3:
        return AppTheme.adhd;
      case 4:
        return AppTheme.custom;
      default:
        return AppTheme.system;
    }
  }

  @override
  void write(BinaryWriter writer, AppTheme obj) {
    switch (obj) {
      case AppTheme.system:
        writer.writeByte(0);
        break;
      case AppTheme.light:
        writer.writeByte(1);
        break;
      case AppTheme.dark:
        writer.writeByte(2);
        break;
      case AppTheme.adhd:
        writer.writeByte(3);
        break;
      case AppTheme.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

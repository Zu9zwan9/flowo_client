// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 7;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.none;
      case 1:
        return NotificationType.vibration;
      case 2:
        return NotificationType.sound;
      case 3:
        return NotificationType.both;
      case 4:
        return NotificationType.push;
      case 5:
        return NotificationType.email;
      case 6:
        return NotificationType.pushAndEmail;
      case 7:
        return NotificationType.disabled;
      default:
        return NotificationType.none;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.none:
        writer.writeByte(0);
        break;
      case NotificationType.vibration:
        writer.writeByte(1);
        break;
      case NotificationType.sound:
        writer.writeByte(2);
        break;
      case NotificationType.both:
        writer.writeByte(3);
        break;
      case NotificationType.push:
        writer.writeByte(4);
        break;
      case NotificationType.email:
        writer.writeByte(5);
        break;
      case NotificationType.pushAndEmail:
        writer.writeByte(6);
        break;
      case NotificationType.disabled:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

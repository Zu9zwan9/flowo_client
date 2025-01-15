import 'package:hive/hive.dart';

part 'notification_type.g.dart';

@HiveType(typeId: 7) // Unique ID for the NotificationType enum
enum NotificationType {
  @HiveField(0)
  none,

  @HiveField(1)
  vibration,

  @HiveField(2)
  sound,

  @HiveField(3)
  both,
}

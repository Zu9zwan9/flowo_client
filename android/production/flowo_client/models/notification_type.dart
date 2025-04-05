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
  @HiveField(4)
  push,
  @HiveField(5)
  email,
  @HiveField(6)
  pushAndEmail,
  @HiveField(7)
  disabled,
}

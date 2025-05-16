import 'package:hive/hive.dart';

part 'notification_type.g.dart';

@HiveType(typeId: 7)
enum NotificationType {
  @HiveField(0)
  disabled,
  @HiveField(4)
  push,
}

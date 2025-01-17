import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 11) // Unique ID for the Category class
class UserSettings extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int minSession;

  // Constructor
  UserSettings({
    required this.name,
    required this.minSession,
  });
}
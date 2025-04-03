import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 13)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  String? avatarPath;

  @HiveField(3)
  String? goal;

  @HiveField(4)
  bool onboardingCompleted;

  UserProfile({
    required this.name,
    required this.email,
    this.avatarPath,
    this.goal,
    this.onboardingCompleted = false,
  });
}

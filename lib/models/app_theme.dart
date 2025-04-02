import 'package:hive/hive.dart';

part 'app_theme.g.dart';

@HiveType(typeId: 20)
enum AppTheme {
  @HiveField(0)
  system,

  @HiveField(1)
  light,

  @HiveField(2)
  dark,

  @HiveField(3)
  adhd,

  @HiveField(4)
  custom
}

import 'package:hive/hive.dart';

part 'repeat_rule.g.dart';

@HiveType(typeId: 9)
class RepeatRule {
  @HiveField(0)
  String frequency;

  @HiveField(1)
  int interval;

  @HiveField(2)
  List<int>? daysOfWeek;

  @HiveField(3)
  List<int>? daysOfMonth;

  @HiveField(4)
  int? weekOfMonth;

  RepeatRule({
    required this.frequency,
    required this.interval,
    this.daysOfWeek,
    this.daysOfMonth,
    this.weekOfMonth,
  });
}

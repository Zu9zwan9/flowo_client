import 'package:hive/hive.dart';

part 'repeat_rule.g.dart';

@HiveType(typeId: 9)
class RepeatRule {
  @HiveField(0)
  String frequency;

  @HiveField(1)
  int interval;

  @HiveField(2)
  int? count;

  @HiveField(3)
  DateTime? until;

  @HiveField(4)
  List<int>? byDay; // monday - 1, tuesday - 2, ..., sunday - 7

  @HiveField(5)
  List<int>? byMonthDay;

  @HiveField(6)
  List<int>? byMonth;

  @HiveField(7)
  int? bySetPos;

  RepeatRule(
      {required this.frequency,
      required this.interval,
      this.count,
      this.until,
      this.byDay,
      this.byMonthDay,
      this.byMonth,
      this.bySetPos});
}

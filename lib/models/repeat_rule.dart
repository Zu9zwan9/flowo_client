import 'package:flowo_client/models/repeat_rule_instance.dart';
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
  List<RepeatRuleInstance>? byDay; // monday - 1, tuesday - 2, ..., sunday - 7

  @HiveField(5)
  List<RepeatRuleInstance>? byMonthDay;

  @HiveField(6)
  List<RepeatRuleInstance>? byMonth;

  @HiveField(7)
  int? bySetPos;

  RepeatRule({
    required this.frequency,
    required this.interval,
    this.count,
    this.until,
    this.byDay,
    this.byMonthDay,
    this.byMonth,
    this.bySetPos,
  });
}

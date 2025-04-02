import 'package:flowo_client/models/repeat_rule_instance.dart';
import 'package:hive/hive.dart';

part 'repeat_rule.g.dart';

@HiveType(typeId: 9)
class RepeatRule {
  @HiveField(0)
  String type; // DAILY, WEEKLY, MONTHLY, YEARLY

  @HiveField(1)
  int interval;

  @HiveField(2)
  int? count;

  @HiveField(3)
  DateTime startRepeat;

  @HiveField(4)
  DateTime? endRepeat;

  @HiveField(5)
  List<RepeatRuleInstance>? byDay; // monday - 1, tuesday - 2, ..., sunday - 7

  @HiveField(6)
  List<RepeatRuleInstance>? byMonthDay;

  @HiveField(7)
  List<RepeatRuleInstance>? byMonth;

  @HiveField(8)
  int? bySetPos;

  @override
  String toString() {
    if (type.toUpperCase() == 'MONTHLY') {
      var instanceString = '';
      if (byMonthDay != null) {
        for (var instance in byMonthDay!) {
          instanceString += '$instance';
        }
      }
      return 'RepeatRule: {frequency: $type,'
          ' interval: $interval,'
          ' startRepeat: $startRepeat,'
          ' endRepeat: $endRepeat,'
          ' bySetPos: $bySetPos,'
          ' byMonthDay: $instanceString}';
    } else {
      var instanceString = '';
      if (byDay != null) {
        for (var instance in byDay!) {
          instanceString += '$instance';
        }
      }
      return 'RepeatRule: {frequency: $type,'
          ' interval: $interval,'
          'startRepeat: $startRepeat,'
          ' endRepeat: $endRepeat,'
          ' bySetPos: $bySetPos,'
          ' byDay: $instanceString}';
    }
  }

  RepeatRule({
    required this.type,
    required this.interval,
    this.count,
    required this.startRepeat,
    this.endRepeat,
    this.byDay,
    this.byMonthDay,
    this.byMonth,
    this.bySetPos,
  });
}

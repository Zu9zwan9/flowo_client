import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'repeat_rule_instance.g.dart';

@HiveType(typeId: 17)
class RepeatRuleInstance {
  @HiveField(0)
  String selectedDay;

  @HiveField(1)
  String name;

  @HiveField(2)
  TimeOfDay start;

  @HiveField(3)
  TimeOfDay end;

  RepeatRuleInstance({
    required this.selectedDay,
    required this.name,
    required this.start,
    required this.end,
  });
}

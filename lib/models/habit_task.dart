import 'package:hive/hive.dart';
import 'repeat_rule.dart';

part 'habit_task.g.dart';

@HiveType(typeId: 10)
class HabitTask extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime startDate;

  @HiveField(2)
  DateTime? endDate;

  @HiveField(3)
  List<DateTime> exceptions;

  @HiveField(4)
  List<DateTime> completedDates;

  @HiveField(5)
  RepeatRule repeatRule;

  HabitTask({
    required this.title,
    required this.startDate,
    this.endDate,
    this.exceptions = const [],
    this.completedDates = const [],
    required this.repeatRule,
  });
}

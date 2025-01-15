import 'package:hive/hive.dart';

part 'days.g.dart';

@HiveType(typeId: 4) // Unique ID for the Days class
class Days extends HiveObject {
  @HiveField(0)
  String day;

  @HiveField(1)
  List<TimeRange> timeRanges;

  // Constructor
  Days({required this.day, required this.timeRanges});
}

@HiveType(typeId: 8) // Unique ID for the TimeRange class
class TimeRange extends HiveObject {
  @HiveField(0)
  DateTime start;

  @HiveField(1)
  DateTime end;

  // Constructor
  TimeRange({required this.start, required this.end});
}

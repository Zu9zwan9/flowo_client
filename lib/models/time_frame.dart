import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'time_frame.g.dart';

@HiveType(typeId: 12)
class TimeFrame {
  @HiveField(0)
  TimeOfDay startTime;

  @HiveField(1)
  TimeOfDay endTime;

  TimeFrame({required this.startTime, required this.endTime});
}

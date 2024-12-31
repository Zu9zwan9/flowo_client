import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'event_model.g.dart';

@HiveType(typeId: 0)
class Event {
  @HiveField(0)
  late String title;

  @HiveField(1)
  String? description;

  @HiveField(2)
  late DateTime startTime;

  @HiveField(3)
  late DateTime endTime;

  @HiveField(4)
  late String category;

  @HiveField(5)
  late String id;

  Event({
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.category,
  }) : id = Uuid().v4();
}

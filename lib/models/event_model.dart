import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'event_model.g.dart';

@Collection()
class Event {
  Id id = Isar.autoIncrement;

  late String title;
  String? description;
  late DateTime startTime;
  late DateTime endTime;
  late String category; // Add this line

  Event({
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.category, // Add this line
  });
}

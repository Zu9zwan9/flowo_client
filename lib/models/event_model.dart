import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'event_model.g.dart'; // Генерация кода Hive для модели

@HiveType(typeId: 0) // Указываем уникальный идентификатор типа данных
class Event {
  @HiveField(0) // Указываем номер поля
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
  late String id; // Уникальный идентификатор

  Event({
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.category,
  }) : id = Uuid().v4(); // Генерация уникального ID через UUID
}

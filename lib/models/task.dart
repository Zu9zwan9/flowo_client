import 'package:flowo_client/models/scheduled_task.dart';
import 'package:hive/hive.dart';

// Подключение кастомных типов, если они используются
part 'task.g.dart';

@HiveType(typeId: 0) // Уникальный ID для класса Task
class Task extends HiveObject {
  // Required fields
  @HiveField(0)
  String title;

  @HiveField(1)
  int priority;

  @HiveField(2)
  int deadline; // В миллисекундах с начала эпохи (Unix time)

  @HiveField(3)
  int estimatedTime; // Ожидаемое время выполнения в миллисекундах

  @HiveField(4)
  Category category;

  // Optional fields
  @HiveField(5)
  String? notes;

  @HiveField(6)
  Coordinates? location;

  @HiveField(7)
  String? image; // Сохраняем путь к изображению

  @HiveField(8)
  List<DaySchedule>? frequency;

  // System fields
  @HiveField(9)
  List<Task> subtasks;

  @HiveField(10)
  List<ScheduledTask> scheduledTask;

  @HiveField(11)
  bool isDone;

  @HiveField(12)
  int order;

  @HiveField(13)
  bool overdue;

  // Constructor
  Task({
    required this.title,
    required this.priority,
    required this.deadline,
    required this.estimatedTime,
    required this.category,
    this.notes,
    this.location,
    this.image,
    this.frequency,
    this.subtasks = const [],
    this.scheduledTask = const [],
    this.isDone = false,
    this.order = 0,
    this.overdue = false,
  });
}

// Category class
@HiveType(typeId: 1) // Уникальный ID для категории
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String color; // HEX-код цвета

  Category({required this.name, required this.color});
}

// Coordinates class
@HiveType(typeId: 2) // Уникальный ID для координат
class Coordinates extends HiveObject {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  Coordinates({required this.latitude, required this.longitude});
}

// DaySchedule class (для расписания по дням недели)
@HiveType(typeId: 3)
class DaySchedule extends HiveObject {
  @HiveField(0)
  String day; // День недели (например, "Monday")

  @HiveField(1)
  List<int> timeRange; // Список [start, end] в миллисекундах

  DaySchedule({required this.day, required this.timeRange});
}

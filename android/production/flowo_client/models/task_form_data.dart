class TaskFormData {
  DateTime selectedDate;
  DateTime selectedTime;
  String category;
  int priority;
  int estimatedTime;
  int? color;

  TaskFormData({
    required this.selectedDate,
    required this.selectedTime,
    required this.category,
    required this.priority,
    required this.estimatedTime,
    this.color,
  });
}

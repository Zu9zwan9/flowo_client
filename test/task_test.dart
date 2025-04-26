import 'package:flutter_test/flutter_test.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/category.dart';

void main() {
  group('Task', () {
    test('should create a task with correct properties', () {
      // Arrange
      final task = Task(
        id: '1',
        title: 'Test Task',
        priority: 1,
        deadline: DateTime.now().millisecondsSinceEpoch,
        estimatedTime: 60, // 60 minutes
        category: Category(name: 'Test Category'),
        subtasks: [],
        scheduledTasks: [],
        isDone: false,
        overdue: false,
      );

      // Assert
      expect(task.id, '1');
      expect(task.title, 'Test Task');
      expect(task.priority, 1);
      expect(task.estimatedTime, 60);
      expect(task.category.name, 'Test Category');
      expect(task.isDone, false);
      expect(task.overdue, false);
      expect(task.subtasks, isEmpty);
      expect(task.scheduledTasks, isEmpty);
    });

    test('isInProgress should return correct value', () {
      // Arrange
      final task = Task(
        id: '1',
        title: 'Test Task',
        priority: 1,
        deadline: DateTime.now().millisecondsSinceEpoch,
        estimatedTime: 60,
        category: Category(name: 'Test Category'),
        subtasks: [],
        scheduledTasks: [],
        isDone: false,
        overdue: false,
        status: 'in_progress',
      );

      // Assert
      expect(task.isInProgress, true);

      // Act
      task.status = 'paused';

      // Assert
      expect(task.isInProgress, false);
    });
  });
}

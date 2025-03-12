import 'package:flutter_test/flutter_test.dart';
import 'package:flowo_client/utils/scheduler.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/time_frame.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/coordinates.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class TestBox<T> extends Box<T> {
  final Map<dynamic, T> _data = {};
  final String _name;

  TestBox(this._name);

  @override
  T? get(dynamic key, {T? defaultValue}) => _data[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, T value) async {
    _data[key] = value;
  }

  @override
  bool containsKey(dynamic key) => _data.containsKey(key);

  @override
  Iterable<T> get values => _data.values;

  @override
  String get name => _name;

  @override
  bool get isOpen => true;

  @override
  Future<void> close() async {}

  @override
  Future<void> deleteFromDisk() async {}

  @override
  Future<int> clear() async {
    final count = _data.length;
    _data.clear();
    return count;
  }

  @override
  Map<dynamic, T> toMap() => Map<dynamic, T>.from(_data);

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (var key in keys) {
      _data.remove(key);
    }
  }

  @override
  Future<void> putAll(Map<dynamic, T> entries) async {
    _data.addAll(entries);
  }

  @override
  Future<void> delete(dynamic key) async {
    _data.remove(key);
  }

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  int get length => _data.length;

  @override
  Iterable<dynamic> get keys => _data.keys;

  @override
  Future<int> add(T value) async {
    final key = _data.length;
    _data[key] = value;
    return key;
  }

  @override
  Future<Iterable<int>> addAll(Iterable<T> values) async {
    final keys = <int>[];
    for (var value in values) {
      keys.add(await add(value));
    }
    return keys;
  }

  @override
  Stream<BoxEvent> watch({dynamic key}) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> valuesBetween({dynamic startKey, dynamic endKey}) {
    throw UnimplementedError();
  }

  @override
  T? getAt(int index) {
    if (index < 0 || index >= length) return null;
    return _data[keys.elementAt(index)];
  }

  @override
  dynamic keyAt(int index) {
    if (index < 0 || index >= length) return null;
    return keys.elementAt(index);
  }

  @override
  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= length) return;
    await delete(keyAt(index));
  }

  @override
  Future<void> putAt(int index, T value) async {
    if (index < 0 || index >= length) return;
    await put(keyAt(index), value);
  }

  @override
  Future<void> compact() async {}

  @override
  Future<void> flush() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      if (invocation.memberName == #lazy) return false;
      if (invocation.memberName == #path) return null;
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('Scheduler Tests', () {
    late Scheduler scheduler;
    late TestBox<Day> daysDB;
    late TestBox<Task> tasksDB;

    setUp(() {
      daysDB = TestBox<Day>('days');
      tasksDB = TestBox<Task>('tasks');
      final userSettings = UserSettings(
        name: 'Test User',
        minSession: 30,
        activeDays: {
          'Monday': true,
          'Tuesday': true,
          'Wednesday': true,
          'Thursday': true,
          'Friday': true,
          'Saturday': true,
          'Sunday': true
        },
        sleepTime: [],
        mealBreaks: [],
        freeTime: [],
        breakTime: 5 * 60 * 1000,
      );
      scheduler = Scheduler(daysDB, tasksDB, userSettings);
    });

    test('Regular task scheduling within same day', () {
      final task = Task(
        id: 'test_task',
        title: 'Test Task',
        estimatedTime: 2 * 60 * 60 * 1000, // 2 hours
        deadline: DateTime(2024, 1, 1, 23, 59).millisecondsSinceEpoch,
        priority: 1,
        category: Category(name: 'Test'),
        scheduledTasks: [],
      );

      // Add a free time slot
      final freeTime = TimeFrame(
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
      );
      scheduler.userSettings.freeTime = [freeTime];

      final scheduledTask = scheduler.scheduleTask(
        task,
        30 * 60 * 1000, // 30 minutes minimum session
        availableDates: ['20240101'],
      );

      expect(scheduledTask, isNotNull);
      expect(scheduledTask!.startTime.hour, 10);
      expect(scheduledTask.endTime.hour, 12);
      expect(scheduledTask.type, ScheduledTaskType.defaultType);
    });

    test('Overnight task scheduling splits into two tasks', () {
      final task = Task(
        id: 'overnight_task',
        title: 'Overnight Task',
        estimatedTime: 4 * 60 * 60 * 1000, // 4 hours
        deadline: DateTime(2024, 1, 2, 23, 59).millisecondsSinceEpoch,
        priority: 1,
        category: Category(name: 'Test'),
        scheduledTasks: [],
      );

      // Add an overnight free time slot
      final overnightFreeTime = TimeFrame(
        startTime: const TimeOfDay(hour: 22, minute: 0),
        endTime: const TimeOfDay(hour: 2, minute: 0),
      );
      scheduler.userSettings.freeTime = [overnightFreeTime];

      final scheduledTask = scheduler.scheduleTask(
        task,
        30 * 60 * 1000, // 30 minutes minimum session
        availableDates: ['20240101', '20240102'],
      );

      expect(scheduledTask, isNotNull);

      // Check first day's task
      final day1 = daysDB.get('20240101');
      expect(day1?.scheduledTasks.length, 1);
      final firstTask = day1?.scheduledTasks.first;
      expect(firstTask?.startTime.hour, 22);
      expect(firstTask?.endTime.hour, 23);
      expect(firstTask?.endTime.minute, 59);

      // Check second day's task
      final day2 = daysDB.get('20240102');
      expect(day2?.scheduledTasks.length, 1);
      final secondTask = day2?.scheduledTasks.first;
      expect(secondTask?.startTime.hour, 0);
      expect(secondTask?.endTime.hour, 2);
    });
  });
}

import 'package:flowo_client/main.dart';
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Register the adapter for the Task model
  Hive.registerAdapter(TaskAdapter());

  // Open the box for tasks
  final tasksDB = await Hive.openBox<Task>('tasks');
  final daysDB = await Hive.openBox<Day>('scheduled_tasks');

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(tasksDB: tasksDB, daysDB: daysDB));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

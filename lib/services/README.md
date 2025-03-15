# Task Time Estimator

This service automatically calculates estimated time for each subtask based on content, parent task's estimated time, and deadline using AI.

## Overview

The Task Time Estimator uses the Hugging Face API to estimate how much time each subtask will take, ensuring that the total estimated time is approximately equal to the parent task's estimated time. This helps users plan their time more effectively by providing realistic time estimates for each subtask.

## Implementation

The implementation follows SOLID principles:

1. **Single Responsibility Principle**: Each class has a single responsibility
   - `TimeEstimationStrategy`: Interface for time estimation strategies
   - `AITimeEstimationStrategy`: Implementation that uses AI for time estimation
   - `TaskTimeEstimator`: Service that uses a strategy to estimate time for subtasks

2. **Open/Closed Principle**: The system is open for extension but closed for modification
   - New estimation strategies can be added without modifying existing code

3. **Liskov Substitution Principle**: Different strategies can be substituted without affecting behavior

4. **Interface Segregation Principle**: The interface is focused on time estimation

5. **Dependency Inversion Principle**: The service depends on abstractions, not concrete implementations

## Usage

### Basic Usage

```dart
// Create an AI time estimation strategy
final strategy = AITimeEstimationStrategy(
  apiKey: 'your_huggingface_api_key',
);

// Create a task time estimator with the AI strategy
final estimator = TaskTimeEstimator(strategy);

// Estimate time for subtasks
final subtaskTitles = [
  'Research the topic',
  'Create an outline',
  'Draft the content',
  'Review and revise',
  'Finalize the work',
];

final estimates = await estimator.estimateSubtaskTimes(
  subtaskTitles,
  120, // Parent task estimated time (minutes)
  deadline, // Parent task deadline (milliseconds since epoch)
);

// Apply the estimates to subtasks
estimator.applyEstimates(subtasks, estimates);
```

### Integration with TaskManager

The `EnhancedTaskManager` class extends the original `TaskManager` and adds AI-based time estimation for subtasks:

```dart
// Create an enhanced task manager
final taskManager = EnhancedTaskManager(
  daysDB: daysBox,
  tasksDB: tasksBox,
  userSettings: userSettings,
  huggingFaceApiKey: 'your_huggingface_api_key',
);

// Break down a task into subtasks and estimate time for each subtask
final subtasks = await taskManager.breakdownAndScheduleTask(task);
```

## Test Scripts

Two test scripts are provided to demonstrate the functionality:

1. `task_time_estimator_test_script.dart`: Tests the TaskTimeEstimator with different sets of subtasks, parent task estimated times, and deadlines.

2. `enhanced_task_manager_test_script.dart`: Tests the EnhancedTaskManager by breaking down a task into subtasks and estimating time for each subtask.

## Error Handling

The implementation includes robust error handling:

- If the AI service fails, it falls back to proportional distribution of time
- If the AI returns invalid estimates, it falls back to proportional distribution
- If the total estimated time differs significantly from the parent task's estimated time, it adjusts the estimates

## Customization

You can create your own time estimation strategies by implementing the `TimeEstimationStrategy` interface:

```dart
class CustomTimeEstimationStrategy implements TimeEstimationStrategy {
  @override
  Future<List<int>> estimateTime(
    List<String> subtaskTitles,
    int parentEstimatedTime,
    int parentDeadline,
  ) async {
    // Your custom time estimation logic here
    return List.generate(subtaskTitles.length, (index) => ...);
  }
}
```

Then use it with the TaskTimeEstimator:

```dart
final estimator = TaskTimeEstimator(CustomTimeEstimationStrategy());
```

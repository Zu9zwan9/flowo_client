# Flowo Client Improvement Tasks

## 1. Notification System Improvements
- [ ] Fix notifications for subtasks
  - [ ] Modify the `breakdownAndScheduleTask` method in `TaskManager` to ensure subtasks are properly scheduled with notifications
  - [ ] Update the `scheduleSubtasks` method to pass notification settings from parent tasks to subtasks
  - [ ] Add notification handling for manually created subtasks

## 2. UI/UX Improvements
- [ ] Fix greeting update issue
  - [ ] Implement real-time greeting updates without requiring page switching
  - [ ] Add a state listener to update the greeting when tasks are completed

## 3. Subtask Management
- [ ] Fix manually created subtasks not being added or scheduled
  - [ ] Update the `_addSubtask` method in `TaskPageScreen` to schedule subtasks after creation
  - [ ] Ensure manually created subtasks appear in the task list immediately
  - [ ] Implement proper parent-child relationship for manually created subtasks

## 4. Break Management
- [ ] Implement feature for scheduling and managing breaks
  - [ ] Create a Break model class with appropriate fields
  - [ ] Add UI components for configuring break duration and frequency
  - [ ] Implement break scheduling logic in the Scheduler class
  - [ ] Add notifications for breaks
  - [ ] Create a break timer feature with pause/resume functionality

## 5. Session Duration Management
- [ ] Enforce minimum session duration for tasks/subtasks
  - [ ] Add validation to prevent tasks/subtasks with duration less than minimum
  - [ ] Update the UI to indicate minimum duration requirements
  - [ ] Implement warning dialogs when users try to create sessions below minimum duration

## 6. Drag-and-Drop Functionality
- [ ] Enable drag-and-drop for reordering subtasks
  - [ ] Implement a reorderable list for subtasks in the `SubtasksList` widget
  - [ ] Add state management for tracking subtask order changes
  - [ ] Create a method to save the new order to Hive database
  - [ ] Add visual feedback during drag operations

## 7. Subtask Display Improvements
- [ ] Enhance subtask display in task list
  - [ ] Update the UI to show subtasks as nested items under parent tasks
  - [ ] Add checkboxes for marking subtasks as complete
  - [ ] Implement proper indentation for subtask hierarchy
  - [ ] Ensure consistent styling between tasks and subtasks

## 8. Performance Optimizations
- [ ] Optimize database operations
  - [ ] Reduce redundant Hive operations
  - [ ] Implement batch updates for related tasks/subtasks
  - [ ] Add caching for frequently accessed data

## 9. Error Handling
- [ ] Improve error handling and recovery
  - [ ] Add try/catch blocks around critical operations
  - [ ] Implement user-friendly error messages
  - [ ] Add logging for debugging purposes
  - [ ] Create recovery mechanisms for common failure scenarios

## 10. Testing
- [ ] Enhance test coverage
  - [ ] Add unit tests for new functionality
  - [ ] Create integration tests for critical user flows
  - [ ] Implement UI tests for new components
  - [ ] Add performance tests for database operations

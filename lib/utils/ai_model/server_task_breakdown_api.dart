import 'package:flowo_client/services/server_api_client.dart';
import 'package:flowo_client/utils/logger.dart';

/// A service that uses the server API to break down tasks into subtasks
class ServerTaskBreakdownAPI {
  final ServerApiClient _apiClient;

  /// Creates a new ServerTaskBreakdownAPI with the given API client
  ServerTaskBreakdownAPI(this._apiClient);

  /// Makes a request to the server API to break down a task into subtasks
  ///
  /// Returns the raw API response or null if the request failed
  Future<List<Map<String, dynamic>>?> makeRequest(
    String task,
    String totalTime,
  ) async {
    // If task is empty, return a mock response for testing
    if (task.isEmpty) {
      logWarning('Empty task provided, returning mock response');
      return [
        {'title': 'First subtask', 'estimatedTime': 30 * 60 * 1000},
        {'title': 'Second subtask', 'estimatedTime': 45 * 60 * 1000},
        {'title': 'Third subtask', 'estimatedTime': 30 * 60 * 1000},
      ];
    }

    // Convert totalTime from string to int (milliseconds)
    final totalTimeMs = int.tryParse(totalTime.trim()) ?? 0;
    if (totalTimeMs <= 0) {
      logWarning('Invalid total time provided: $totalTime');
      return null;
    }

    // Make the request to the server API
    return await _apiClient.breakdownTask(task, totalTimeMs);
  }

  /// Breaks down a task into subtasks using the server API
  ///
  /// Returns a list of subtasks or default subtasks if the request failed
  Future<List<Map<String, dynamic>>> breakdownTask(
    String task,
    String totalTime,
  ) async {
    if (task.trim().isEmpty) {
      logWarning('Empty task provided');
      return [];
    }

    final subtasks = await makeRequest(task, totalTime);
    return subtasks ?? [];
  }
}

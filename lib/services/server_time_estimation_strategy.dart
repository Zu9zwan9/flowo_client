import 'package:flowo_client/services/server_api_client.dart';
import 'package:flowo_client/services/task_time_estimator.dart';
import 'package:flowo_client/utils/logger.dart';

/// A strategy that uses the server API to estimate time for subtasks
class ServerTimeEstimationStrategy implements TimeEstimationStrategy {
  final ServerApiClient _apiClient;

  /// Creates a new ServerTimeEstimationStrategy with the given API client
  ServerTimeEstimationStrategy(this._apiClient);

  @override
  Future<List<int>> estimateTime(
    List<String> subtaskTitles,
    int parentEstimatedTime,
    int parentDeadline,
  ) async {
    if (subtaskTitles.isEmpty) {
      logWarning('No subtasks provided for time estimation');
      return [];
    }

    logInfo('Estimating time for ${subtaskTitles.length} subtasks using server API');

    try {
      // Use the API client to estimate time for subtasks
      final estimates = await _apiClient.estimateSubtaskTimes(
        subtaskTitles,
        parentEstimatedTime,
        parentDeadline,
      );

      if (estimates != null) {
        logInfo('Successfully received time estimates from server: $estimates');
        return estimates;
      }

      // Fallback to proportional distribution
      logWarning('Failed to get estimates from server, using proportional distribution');
      return _distributeProportionally(
        subtaskTitles.length,
        parentEstimatedTime,
      );
    } catch (e) {
      logError('Error estimating time for subtasks: $e');

      // Fallback to proportional distribution
      return _distributeProportionally(
        subtaskTitles.length,
        parentEstimatedTime,
      );
    }
  }

  /// Distributes time proportionally among subtasks (fallback method)
  List<int> _distributeProportionally(int subtaskCount, int totalTime) {
    logInfo('Using proportional distribution for time estimates');
    final baseTime = totalTime ~/ subtaskCount;
    final remainder = totalTime % subtaskCount;

    return List.generate(
      subtaskCount,
      (index) => index < remainder ? baseTime + 1 : baseTime,
    );
  }
}

import 'dart:convert';

import 'package:flowo_client/utils/logger.dart';
import 'package:http/http.dart' as http;

/// Client for communicating with the task breakdown server
class ServerApiClient {
  final String baseUrl;
  final String apiKey;

  /// Creates a new ServerApiClient with the given base URL and API key
  ServerApiClient({required this.baseUrl, required this.apiKey});

  /// Makes a request to the server API
  ///
  /// Returns the response body as a Map<String, dynamic> or null if the request failed
  Future<Map<String, dynamic>?> _makeRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl/api$endpoint');
    final headers = {'Content-Type': 'application/json', 'X-API-Key': apiKey};

    try {
      logInfo('Making request to server API: $endpoint');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        logInfo('Received successful response from server API');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        logError(
          'Error from server API: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      logError('Exception making request to server API: $e');
      return null;
    }
  }

  /// Breaks down a task into subtasks with time estimates
  ///
  /// Returns a list of subtasks with titles and estimated times, or null if the request failed
  Future<List<Map<String, dynamic>>?> breakdownTask(
    String task,
    int totalTimeMs,
  ) async {
    // Convert milliseconds to minutes for the API
    final totalTimeMinutes = totalTimeMs ~/ (60 * 1000);

    final requestBody = {'task': task, 'total_time': totalTimeMinutes};

    final response = await _makeRequest('/breakdown', requestBody);
    if (response == null) {
      return null;
    }

    try {
      final subtasks = response['subtasks'] as List<dynamic>;
      return subtasks.map((subtask) {
        // Convert minutes back to milliseconds for the app
        final estimatedTimeMinutes = subtask['estimated_time'] as int;
        final estimatedTimeMs = estimatedTimeMinutes * 60 * 1000;

        return {
          'title': subtask['title'] as String,
          'estimatedTime': estimatedTimeMs,
        };
      }).toList();
    } catch (e) {
      logError('Error parsing subtasks from response: $e');
      return null;
    }
  }

  /// Estimates time for a list of subtasks
  ///
  /// Returns a list of estimated times for each subtask in milliseconds, or null if the request failed
  Future<List<int>?> estimateSubtaskTimes(
    List<String> subtaskTitles,
    int parentEstimatedTimeMs,
    int? parentDeadline,
  ) async {
    // Convert milliseconds to minutes for the API
    final parentEstimatedTimeMinutes = parentEstimatedTimeMs ~/ (60 * 1000);

    final requestBody = {
      'subtask_titles': subtaskTitles,
      'parent_estimated_time': parentEstimatedTimeMinutes,
      if (parentDeadline != null) 'parent_deadline': parentDeadline,
    };

    final response = await _makeRequest('/estimate', requestBody);
    if (response == null) {
      return null;
    }

    try {
      final estimates = response['estimates'] as List<dynamic>;
      // Convert minutes back to milliseconds for the app
      return estimates
          .map((estimate) => (estimate as int) * 60 * 1000)
          .toList();
    } catch (e) {
      logError('Error parsing estimates from response: $e');
      return null;
    }
  }
}

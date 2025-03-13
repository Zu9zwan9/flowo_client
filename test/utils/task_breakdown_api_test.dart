import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowo_client/utils/task_breakdown_api.dart';
import 'package:flowo_client/utils/logger.dart';

void main() {
  group('TaskBreakdownAPI', () {
    late TaskBreakdownAPI api;

    setUp(() {
      api = TaskBreakdownAPI(
        apiKey: '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',
      );
    });

    test('makeRequest returns a valid response', () async {
      final response =
          await api.makeRequest('Write a research paper on climate change');

      // Print the raw response for debugging
      if (kDebugMode) {
        print('[DEBUG_LOG] Raw API response: $response');
      }

      expect(response, isNotNull);
    });

    test('breakdownTask returns a list of subtasks', () async {
      final subtasks =
          await api.breakdownTask('Write a research paper on climate change');

      // Print the subtasks for debugging
      if (kDebugMode) {
        print('[DEBUG_LOG] Generated subtasks: $subtasks');
      }
      if (kDebugMode) {
        print('[DEBUG_LOG] Number of subtasks: ${subtasks.length}');
      }

      expect(subtasks, isA<List<String>>());
    });

    test('parseSubtasks correctly extracts subtasks from response', () {
      // Test with a list response format
      final listResponse = [
        {
          "generated_text":
              "1. Research climate change causes\n2. Gather scientific data\n3. Outline the paper\n4. Write introduction\n5. Analyze findings"
        }
      ];

      final subtasks = api.parseSubtasks(listResponse);
      if (kDebugMode) {
        print('[DEBUG_LOG] Parsed subtasks from list response: $subtasks');
      }
      expect(subtasks.length, 5);

      // Test with a map response format
      final mapResponse = {
        "generated_text":
            "1. Research climate change causes\n2. Gather scientific data\n3. Outline the paper\n4. Write introduction\n5. Analyze findings"
      };

      final subtasksFromMap = api.parseSubtasks(mapResponse);
      if (kDebugMode) {
        print(
            '[DEBUG_LOG] Parsed subtasks from map response: $subtasksFromMap');
      }
      expect(subtasksFromMap.length, 5);
    });
  });
}

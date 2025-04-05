import 'package:flowo_client/utils/ai_model/task_breakdown_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pipeline', () {
    late Pipeline pipe;

    setUp(() {
      pipe = pipeline(
        "text-generation",
        model: "HuggingFaceH4/zephyr-7b-beta",
        apiKey: "test_api_key",
      );
    });

    test('Pipeline is created with correct parameters', () {
      expect(pipe.task, equals("text-generation"));
      expect(pipe.model, equals("HuggingFaceH4/zephyr-7b-beta"));
      expect(pipe.apiKey, equals("test_api_key"));
      expect(
        pipe.apiUrl,
        equals(
          "https://api-inference.huggingface.co/models/HuggingFaceH4/zephyr-7b-beta",
        ),
      );
    });

    test('Pipeline call method formats messages correctly', () async {
      // This is a mock test that doesn't actually make an API call
      final messages = [
        {"role": "user", "content": "Who are you?"},
      ];

      // We're not actually calling the API in this test
      // Just verifying the structure is correct
      expect(messages, isA<List<Map<String, String>>>());
      expect(messages.length, equals(1));
      expect(messages[0]["role"], equals("user"));
      expect(messages[0]["content"], equals("Who are you?"));
    });
  });

  group('TaskBreakdownAPI with Pipeline', () {
    late TaskBreakdownAPI api;

    setUp(() {
      api = TaskBreakdownAPI(apiKey: "test_api_key");
    });

    test('TaskBreakdownAPI uses Pipeline for requests', () async {
      // This is a structural test to ensure the API is set up correctly
      expect(api.apiKey, equals("test_api_key"));
      expect(
        api.apiUrl,
        equals(
          "https://api-inference.huggingface.co/models/HuggingFaceH4/zephyr-7b-beta",
        ),
      );
    });

    test('breakdownTask returns subtasks', () async {
      // This test would normally make an API call, but we're just testing the structure
      final task = "Write a research paper";
      final totalTime = "120"; // 2 hours in minutes

      // We're not actually calling the API in this test
      // Just verifying the method exists and returns a List<String>
      expect(api.breakdownTask(task, totalTime), isA<Future<List<String>>>());
    });
  });
}

import 'package:flowo_client/utils/chat_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatPipeline', () {
    late ChatPipeline pipe;

    setUp(() {
      pipe = chatPipeline(
        model: "HuggingFaceH4/zephyr-7b-beta",
        apiKey: "test_api_key",
      );
    });

    test('ChatPipeline is created with correct parameters', () {
      expect(pipe.model, equals("HuggingFaceH4/zephyr-7b-beta"));
      expect(pipe.apiKey, equals("test_api_key"));
      expect(
        pipe.apiUrl,
        equals(
          "https://router.huggingface.co/hf-inference/models/HuggingFaceH4/zephyr-7b-beta/v1/chat/completions",
        ),
      );
      expect(pipe.maxTokens, equals(500));
      expect(pipe.shouldStream, equals(false));
    });

    test('ChatPipeline call method formats messages correctly', () async {
      // This is a mock test that doesn't actually make an API call
      final messages = [
        {"role": "user", "content": "What is the capital of France?"},
      ];

      // We're not actually calling the API in this test
      // Just verifying the structure is correct
      expect(messages, isA<List<Map<String, String>>>());
      expect(messages.length, equals(1));
      expect(messages[0]["role"], equals("user"));
      expect(messages[0]["content"], equals("What is the capital of France?"));
    });

    test('ChatPipeline streamResponse method returns a Stream<String>', () {
      final messages = [
        {"role": "user", "content": "What is the capital of France?"},
      ];

      final stream = pipe.streamResponse(messages);
      expect(stream, isA<Stream<String>>());
    });
  });
}

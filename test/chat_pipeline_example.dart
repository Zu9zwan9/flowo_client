import 'package:flowo_client/utils/ai_model/chat_pipeline.dart';
import 'package:flutter/foundation.dart';

/// Example usage of the ChatPipeline class, similar to the curl example:
/// ```
/// curl 'https://router.huggingface.co/hf-inference/models/HuggingFaceH4/zephyr-7b-beta/v1/chat/completions' \
/// -H 'Authorization: Bearer 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' \
/// -H 'Content-Type: application/json' \
/// --data '{
///     "model": "HuggingFaceH4/zephyr-7b-beta",
///     "messages": [
///         {
///             "role": "user",
///             "content": "What is the capital of France?"
///         }
///     ],
///     "max_tokens": 500,
///     "stream": true
/// }'
/// ```
void main() async {
  // Create a chat pipeline for the Zephyr model
  final pipe = chatPipeline(
    model: "HuggingFaceH4/zephyr-7b-beta",
    apiKey: "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",
    maxTokens: 500,
  );

  // Define messages
  final messages = [
    {"role": "user", "content": "What is the capital of France?"},
  ];

  // Example 1: Non-streaming request
  if (kDebugMode) {
    print('Making non-streaming request...');
  }
  final response = await pipe.call(messages);
  if (kDebugMode) {
    print('Response: ${response?["choices"][0]["message"]["content"]}');
  }

  // Example 2: Streaming request
  if (kDebugMode) {
    print('\nMaking streaming request...');
  }
  final streamingPipe = chatPipeline(
    model: "HuggingFaceH4/zephyr-7b-beta",
    apiKey: "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",
    maxTokens: 500,
    shouldStream: true,
  );

  // Buffer to collect the streamed response
  final buffer = StringBuffer();

  // Listen to the stream
  await for (final chunk in streamingPipe.streamResponse(messages)) {
    // Print each chunk as it arrives
    if (kDebugMode) {
      print('Chunk: $chunk');
    }
    buffer.write(chunk);
  }

  // Print the complete response
  if (kDebugMode) {
    print('\nComplete streamed response:');
  }
  if (kDebugMode) {
    print(buffer.toString());
  }
}

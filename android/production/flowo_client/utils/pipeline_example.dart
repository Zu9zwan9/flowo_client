import 'package:flowo_client/utils/task_breakdown_api.dart';
import 'package:flutter/foundation.dart';

/// Example usage of the Pipeline class, similar to the Python example:
/// ```python
/// from transformers import pipeline
///
/// messages = [
///     {"role": "user", "content": "Who are you?"},
/// ]
/// pipe = pipeline("text-generation", model="HuggingFaceH4/zephyr-7b-beta")
/// pipe(messages)
/// ```
void main() async {
  // Create a pipeline for text generation
  final pipe = pipeline(
    "text-generation",
    model: "HuggingFaceH4/zephyr-7b-beta",
    apiKey: "your_huggingface_api_key_here",
  );

  // Define messages
  final messages = [
    {"role": "user", "content": "Who are you?"},
  ];

  // Call the pipeline with the messages
  final response = await pipe.call(messages);

  // Print the response
  if (kDebugMode) {
    print('Generated text: ${response?["generated_text"]}');
  }
}

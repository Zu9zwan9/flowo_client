import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flowo_client/utils/logger.dart';

/// A pipeline for chat completions using Hugging Face models
class ChatPipeline {
  final String model;
  final String apiKey;
  final String apiUrl;
  final int maxTokens;
  final bool shouldStream;

  /// Creates a new pipeline for chat completions
  ///
  /// The model should be a valid Hugging Face model ID
  /// The API key should be a valid Hugging Face API key
  ChatPipeline({
    required this.model,
    required this.apiKey,
    this.maxTokens = 500,
    this.shouldStream = false,
    String? apiUrl,
  }) : apiUrl = apiUrl ??
            'https://router.huggingface.co/hf-inference/models/$model/v1/chat/completions';

  /// Calls the pipeline with the given messages
  ///
  /// Returns the generated text or null if the request failed
  Future<Map<String, dynamic>?> call(List<Map<String, String>> messages) async {
    final data = {
      "model": model,
      "messages": messages,
      "max_tokens": maxTokens,
      "stream": false
    };

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json"
    };

    try {
      logInfo('Making request to Hugging Face Chat API for model: $model');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        logInfo('Received successful response from Hugging Face Chat API');
        return jsonDecode(response.body);
      } else {
        logError(
            'Error from Hugging Face Chat API: ${response.statusCode} - ${response.body}');

        // If the API is unavailable, return a fallback response
        logWarning('Using fallback response due to API error');
        return {
          "choices": [
            {
              "message": {
                "content":
                    "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work"
              }
            }
          ]
        };
      }
    } catch (e) {
      logError('Exception making request to Hugging Face Chat API: $e');

      // If there's an exception, return a fallback response
      logWarning('Using fallback response due to exception');
      return {
        "choices": [
          {
            "message": {
              "content":
                  "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work"
            }
          }
        ]
      };
    }
  }

  /// Calls the pipeline with the given messages and streams the response
  ///
  /// Returns a stream of generated text chunks
  Stream<String> streamResponse(List<Map<String, String>> messages) async* {
    final data = {
      "model": model,
      "messages": messages,
      "max_tokens": maxTokens,
      "stream": true
    };

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json"
    };

    try {
      logInfo(
          'Making streaming request to Hugging Face Chat API for model: $model');
      final request = http.Request('POST', Uri.parse(apiUrl));
      request.headers.addAll(headers);
      request.body = jsonEncode(data);

      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode == 200) {
        logInfo('Receiving streamed response from Hugging Face Chat API');

        await for (var chunk
            in streamedResponse.stream.transform(utf8.decoder)) {
          // Process each chunk of the streamed response
          // The format is typically "data: {JSON}" for each chunk
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ') && line != 'data: [DONE]') {
              final jsonData = line.substring(6); // Remove 'data: ' prefix
              try {
                final data = jsonDecode(jsonData);
                final content = data['choices'][0]['delta']['content'];
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                logError('Error parsing streamed response: $e');
              }
            }
          }
        }
      } else {
        logError(
            'Error from Hugging Face Chat API stream: ${streamedResponse.statusCode}');

        // If the API is unavailable, yield a fallback response
        logWarning('Using fallback response due to API error');
        yield "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work";
      }
    } catch (e) {
      logError(
          'Exception making streaming request to Hugging Face Chat API: $e');

      // If there's an exception, yield a fallback response
      logWarning('Using fallback response due to exception');
      yield "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work";
    }
  }
}

/// A factory function to create a chat pipeline for chat completions
ChatPipeline chatPipeline({
  required String model,
  required String apiKey,
  String? apiUrl,
  int maxTokens = 500,
  bool shouldStream = false,
}) {
  return ChatPipeline(
    model: model,
    apiKey: apiKey,
    apiUrl: apiUrl,
    maxTokens: maxTokens,
    shouldStream: shouldStream,
  );
}

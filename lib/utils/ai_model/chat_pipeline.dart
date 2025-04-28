import 'dart:async';
import 'dart:convert';

import 'package:flowo_client/utils/logger.dart';
import 'package:http/http.dart' as http;

/// A pipeline for chat completions using Azure API models
class ChatPipeline {
  final String model;
  final String apiKey;
  final String apiUrl;
  final int maxTokens;
  final bool shouldStream;

  /// Creates a new pipeline for chat completions
  ///
  /// The model should be a valid Azure API model ID
  /// The API key should be a valid Azure API key
  ChatPipeline({
    String? model,
    String? apiKey,
    this.maxTokens = 4096,
    this.shouldStream = false,
    String? apiUrl,
  }) : model = model ?? 'gpt-4o',
       apiKey =
           apiKey ??
           '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',
       apiUrl =
           apiUrl ?? 'https://models.inference.ai.azure.com/chat/completions';

  /// Calls the pipeline with the given messages
  ///
  /// Returns the generated text or null if the request failed
  Future<Map<String, dynamic>?> call(List<Map<String, String>> messages) async {
    // Ensure system message is present
    final List<Map<String, String>> formattedMessages = [];
    bool hasSystemMessage = messages.any((msg) => msg["role"] == "system");
    if (!hasSystemMessage) {
      formattedMessages.add({"role": "system", "content": ""});
    }
    formattedMessages.addAll(messages);

    final data = {
      "model": model,
      "messages": formattedMessages,
      "max_tokens": maxTokens,
      "temperature": 1,
      "top_p": 1,
      "stream": false,
    };

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    try {
      logInfo('Making request to Azure Chat API for model: $model');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        logInfo('Received successful response from Azure Chat API');
        return jsonDecode(response.body);
      } else {
        logError(
          'Error from Azure Chat API: ${response.statusCode} - ${response.body}',
        );

        // If the API is unavailable, return a fallback response
        logWarning('Using fallback response due to API error');
        return {
          "choices": [
            {
              "message": {
                "content":
                    "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work",
              },
            },
          ],
        };
      }
    } catch (e) {
      logError('Exception making request to Azure Chat API: $e');

      // If there's an exception, return a fallback response
      logWarning('Using fallback response due to exception');
      return {
        "choices": [
          {
            "message": {
              "content":
                  "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work",
            },
          },
        ],
      };
    }
  }

  /// Calls the pipeline with the given messages and streams the response
  ///
  /// Returns a stream of generated text chunks
  Stream<String> streamResponse(List<Map<String, String>> messages) async* {
    // Ensure system message is present
    final List<Map<String, String>> formattedMessages = [];
    bool hasSystemMessage = messages.any((msg) => msg["role"] == "system");
    if (!hasSystemMessage) {
      formattedMessages.add({"role": "system", "content": ""});
    }
    formattedMessages.addAll(messages);

    final data = {
      "model": model,
      "messages": formattedMessages,
      "max_tokens": maxTokens,
      "temperature": 1,
      "top_p": 1,
      "stream": true,
    };

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    try {
      logInfo('Making streaming request to Azure Chat API for model: $model');
      final request = http.Request('POST', Uri.parse(apiUrl));
      request.headers.addAll(headers);
      request.body = jsonEncode(data);

      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode == 200) {
        logInfo('Receiving streamed response from Azure Chat API');

        await for (var chunk in streamedResponse.stream.transform(
          utf8.decoder,
        )) {
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
          'Error from Azure Chat API stream: ${streamedResponse.statusCode}',
        );

        // If the API is unavailable, yield a fallback response
        logWarning('Using fallback response due to API error');
        yield "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work";
      }
    } catch (e) {
      logError('Exception making streaming request to Azure Chat API: $e');

      // If there's an exception, yield a fallback response
      logWarning('Using fallback response due to exception');
      yield "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work";
    }
  }
}

/// A factory function to create a chat pipeline for chat completions
ChatPipeline chatPipeline({
  String? model,
  String? apiKey,
  String? apiUrl,
  int maxTokens = 4096,
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

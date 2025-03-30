// API key should be stored on the server, not in the client
final api = (
  apiKey: const String.fromEnvironment('SERVER_API_KEY', defaultValue: ''),
);

import 'dart:convert';

/// Class representing information about a downloaded model
class ModelInfo {
  /// Unique identifier for the model
  final String id;

  /// Human-readable name for the model
  final String name;

  /// Version of the model (optional)
  final String? version;

  /// Size of the model in bytes
  final int size;

  /// Date when the model was downloaded
  final DateTime downloadDate;

  /// Path to the model file
  final String filePath;

  ModelInfo({
    required this.id,
    required this.name,
    this.version,
    required this.size,
    required this.downloadDate,
    required this.filePath,
  });

  /// Create a ModelInfo object from a JSON string
  factory ModelInfo.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return ModelInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String?,
      size: json['size'] as int,
      downloadDate: DateTime.parse(json['downloadDate'] as String),
      filePath: json['filePath'] as String,
    );
  }

  /// Convert the ModelInfo object to a JSON string
  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'version': version,
      'size': size,
      'downloadDate': downloadDate.toIso8601String(),
      'filePath': filePath,
    });
  }
}

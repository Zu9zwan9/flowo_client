import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'ambient_scene.g.dart';

/// Represents a type of ambient scene (e.g., Cafe, Forest, Beach)
@HiveType(typeId: 19)
class AmbientScene extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String videoAssetPath;

  @HiveField(4)
  final List<String> audioAssetPaths;

  @HiveField(5)
  final String thumbnailAssetPath;

  @HiveField(6)
  final String category;

  AmbientScene({
    required this.id,
    required this.name,
    required this.description,
    required this.videoAssetPath,
    required this.audioAssetPaths,
    required this.thumbnailAssetPath,
    required this.category,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    videoAssetPath,
    audioAssetPaths,
    thumbnailAssetPath,
    category,
  ];

  /// Creates a copy of this AmbientScene with the given fields replaced with the new values
  AmbientScene copyWith({
    String? id,
    String? name,
    String? description,
    String? videoAssetPath,
    List<String>? audioAssetPaths,
    String? thumbnailAssetPath,
    String? category,
  }) {
    return AmbientScene(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      videoAssetPath: videoAssetPath ?? this.videoAssetPath,
      audioAssetPaths: audioAssetPaths ?? this.audioAssetPaths,
      thumbnailAssetPath: thumbnailAssetPath ?? this.thumbnailAssetPath,
      category: category ?? this.category,
    );
  }

  /// Safely saves this object if it's in a box
  bool trySave() {
    try {
      if (isInBox) {
        save();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save AmbientScene: $e');
      }
      return false;
    }
  }
}

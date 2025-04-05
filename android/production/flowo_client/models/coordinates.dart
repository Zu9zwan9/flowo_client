import 'package:hive/hive.dart';

part 'coordinates.g.dart';

@HiveType(typeId: 3) // Unique ID for the Coordinates class
class Coordinates extends HiveObject {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  // Constructor
  Coordinates({required this.latitude, required this.longitude});
}

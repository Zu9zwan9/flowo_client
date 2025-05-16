import 'package:hive/hive.dart';

part 'coordinates.g.dart';

@HiveType(typeId: 3)
class Coordinates extends HiveObject {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  Coordinates({required this.latitude, required this.longitude});
}

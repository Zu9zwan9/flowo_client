import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 2) // Unique ID for the Category class
class Category extends HiveObject {
  @HiveField(0)
  String name;

  // Constructor
  Category({required this.name});
}

import 'package:hive_flutter/hive_flutter.dart';

class CategoryService {
  static const String _categoryBoxName = 'categories';
  static const String _categoriesKey = 'category_list';

  // Default categories if none exist
  static const List<String> _defaultCategories = [
    'Brainstorm',
    'Design',
    'Workout',
  ];

  Future<List<String>> getCategories() async {
    final box = await Hive.openBox(_categoryBoxName);
    List<String> categories = List<String>.from(
      box.get(_categoriesKey, defaultValue: _defaultCategories),
    );

    // Make sure 'Add' is not duplicated
    if (categories.contains('Add')) {
      categories.remove('Add');
    }

    return categories;
  }

  Future<void> addCategory(String category) async {
    if (category.isEmpty || category == 'Add') return;

    final box = await Hive.openBox(_categoryBoxName);
    List<String> categories = List<String>.from(
      box.get(_categoriesKey, defaultValue: _defaultCategories),
    );

    if (!categories.contains(category)) {
      categories.add(category);
      await box.put(_categoriesKey, categories);
    }
  }

  Future<void> updateCategory(String oldCategory, String newCategory) async {
    if (newCategory.isEmpty || newCategory == 'Add') return;

    final box = await Hive.openBox(_categoryBoxName);
    List<String> categories = List<String>.from(
      box.get(_categoriesKey, defaultValue: _defaultCategories),
    );

    final index = categories.indexOf(oldCategory);
    if (index >= 0) {
      categories[index] = newCategory;
      await box.put(_categoriesKey, categories);
    }
  }

  Future<void> deleteCategory(String category) async {
    final box = await Hive.openBox(_categoryBoxName);
    List<String> categories = List<String>.from(
      box.get(_categoriesKey, defaultValue: _defaultCategories),
    );

    categories.remove(category);
    await box.put(_categoriesKey, categories);
  }
}

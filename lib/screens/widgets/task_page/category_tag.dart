import 'package:flutter/cupertino.dart';
import '../../../utils/category_utils.dart';

class CategoryTag extends StatelessWidget {
  final String categoryName;

  const CategoryTag({required this.categoryName, super.key});

  @override
  Widget build(BuildContext context) {
    final color = CategoryUtils.getCategoryColor(categoryName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        categoryName,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
        overflow: TextOverflow.visible,
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowo_client/utils/category_utils.dart';

void main() {
  group('CategoryUtils', () {
    test('returns correct colors for different categories', () {
      expect(CategoryUtils.getCategoryColor('work'),
          equals(CupertinoColors.systemBlue));
      expect(CategoryUtils.getCategoryColor('brainstorm'),
          equals(CupertinoColors.systemBlue));

      expect(CategoryUtils.getCategoryColor('personal'),
          equals(CupertinoColors.systemGreen));
      expect(CategoryUtils.getCategoryColor('design'),
          equals(CupertinoColors.systemGreen));

      expect(CategoryUtils.getCategoryColor('shopping'),
          equals(CupertinoColors.systemOrange));
      expect(CategoryUtils.getCategoryColor('habit'),
          equals(CupertinoColors.systemOrange));

      expect(CategoryUtils.getCategoryColor('health'),
          equals(CupertinoColors.systemRed));
      expect(CategoryUtils.getCategoryColor('workout'),
          equals(CupertinoColors.systemRed));

      expect(CategoryUtils.getCategoryColor('education'),
          equals(CupertinoColors.systemPurple));
      expect(CategoryUtils.getCategoryColor('event'),
          equals(CupertinoColors.systemPurple));
    });

    test('returns grey for unknown categories', () {
      expect(CategoryUtils.getCategoryColor('unknown'),
          equals(CupertinoColors.systemGrey));
      expect(CategoryUtils.getCategoryColor(''),
          equals(CupertinoColors.systemGrey));
    });

    test('is case insensitive', () {
      expect(CategoryUtils.getCategoryColor('WORK'),
          equals(CupertinoColors.systemBlue));
      expect(CategoryUtils.getCategoryColor('Work'),
          equals(CupertinoColors.systemBlue));
      expect(CategoryUtils.getCategoryColor('work'),
          equals(CupertinoColors.systemBlue));
    });
  });
}

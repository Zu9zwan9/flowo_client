import 'package:flutter_test/flutter_test.dart';
import 'package:flowo_client/utils/formatter/date_time_formatter.dart';

void main() {
  group('DateTimeFormatter', () {
    final testDateTime = DateTime(2023, 5, 15, 14, 30); // May 15, 2023, 2:30 PM

    group('formatDate', () {
      test('formats date with numeric month in DD-MM-YYYY format', () {
        final result = DateTimeFormatter.formatDate(
          testDateTime,
          dateFormat: 'DD-MM-YYYY',
          monthFormat: 'numeric',
        );
        expect(result, '15-05-2023');
      });

      test('formats date with short month in DD-MM-YYYY format', () {
        final result = DateTimeFormatter.formatDate(
          testDateTime,
          dateFormat: 'DD-MM-YYYY',
          monthFormat: 'short',
        );
        expect(result, '15-May-2023');
      });

      test('formats date with full month in DD-MM-YYYY format', () {
        final result = DateTimeFormatter.formatDate(
          testDateTime,
          dateFormat: 'DD-MM-YYYY',
          monthFormat: 'full',
        );
        expect(result, '15-May-2023');
      });

      test('formats date with numeric month in MM-DD-YYYY format', () {
        final result = DateTimeFormatter.formatDate(
          testDateTime,
          dateFormat: 'MM-DD-YYYY',
          monthFormat: 'numeric',
        );
        expect(result, '05-15-2023');
      });
    });

    group('formatTime', () {
      test('formats time in 24-hour format', () {
        final result = DateTimeFormatter.formatTime(
          testDateTime,
          is24HourFormat: true,
        );
        expect(result, '14:30');
      });

      test('formats time in 12-hour format (PM)', () {
        final result = DateTimeFormatter.formatTime(
          testDateTime,
          is24HourFormat: false,
        );
        expect(result, '2:30 PM');
      });

      test('formats time in 12-hour format (AM)', () {
        final morningTime = DateTime(2023, 5, 15, 9, 5); // 9:05 AM
        final result = DateTimeFormatter.formatTime(
          morningTime,
          is24HourFormat: false,
        );
        expect(result, '9:05 AM');
      });

      test('formats midnight correctly in 12-hour format', () {
        final midnight = DateTime(2023, 5, 15, 0, 0); // 12:00 AM
        final result = DateTimeFormatter.formatTime(
          midnight,
          is24HourFormat: false,
        );
        expect(result, '12:00 AM');
      });
    });

    group('formatDateTime', () {
      test('formats date and time with numeric month in 24-hour format', () {
        final result = DateTimeFormatter.formatDateTime(
          testDateTime,
          dateFormat: 'DD-MM-YYYY',
          monthFormat: 'numeric',
          is24HourFormat: true,
        );
        expect(result, '15-05-2023 14:30');
      });

      test('formats date and time with short month in 12-hour format', () {
        final result = DateTimeFormatter.formatDateTime(
          testDateTime,
          dateFormat: 'MM-DD-YYYY',
          monthFormat: 'short',
          is24HourFormat: false,
        );
        expect(result, 'May-15-2023 2:30 PM');
      });
    });
  });
}

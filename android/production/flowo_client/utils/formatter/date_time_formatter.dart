class DateTimeFormatter {
  // List of month names for short format (e.g., "Jan", "Feb", etc.)
  static const _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // List of full month names (e.g., "January", "February", etc.)
  static const _fullMonthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Formats only the date part of a DateTime object based on user settings.
  /// [dateTime] - The DateTime object to format.
  /// [dateFormat] - The date format ("DD-MM-YYYY" or "MM-DD-YYYY").
  /// [monthFormat] - The month display style ("numeric", "short", or "full").
  /// Returns a string representing the formatted date.
  static String formatDate(
    DateTime dateTime, {
    required String dateFormat,
    required String monthFormat,
  }) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    String month;

    // Determine month format based on user settings
    switch (monthFormat) {
      case 'numeric':
        month = dateTime.month.toString().padLeft(2, '0');
        break;
      case 'short':
        month = _shortMonthNames[dateTime.month - 1];
        break;
      case 'full':
        month = _fullMonthNames[dateTime.month - 1];
        break;
      default:
        month = dateTime.month.toString().padLeft(
          2,
          '0',
        ); // Fallback to numeric
    }

    // Assemble the date string based on the specified date format
    switch (dateFormat) {
      case 'DD-MM-YYYY':
        return '$day-$month-$year';
      case 'MM-DD-YYYY':
        return '$month-$day-$year';
      default:
        return '$day-$month-$year'; // Default to DD-MM-YYYY if format is invalid
    }
  }

  /// Formats only the time part of a DateTime object based on user settings.
  /// [dateTime] - The DateTime object to format.
  /// [is24HourFormat] - Whether to use 24-hour (true) or 12-hour (false) format.
  /// Returns a string representing the formatted time.
  static String formatTime(DateTime dateTime, {required bool is24HourFormat}) {
    if (is24HourFormat) {
      // 24-hour format (e.g., "14:30")
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      // 12-hour format (e.g., "2:30 PM")
      final hour =
          dateTime.hour > 12
              ? (dateTime.hour - 12)
              : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour < 12 ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
  }

  /// Formats both date and time parts of a DateTime object based on user settings.
  /// [dateTime] - The DateTime object to format.
  /// [dateFormat] - The date format ("DD-MM-YYYY" or "MM-DD-YYYY").
  /// [monthFormat] - The month display style ("numeric", "short", or "full").
  /// [is24HourFormat] - Whether to use 24-hour (true) or 12-hour (false) format.
  /// Returns a string representing the formatted date and time.
  static String formatDateTime(
    DateTime dateTime, {
    required String dateFormat,
    required String monthFormat,
    required bool is24HourFormat,
  }) {
    final datePart = formatDate(
      dateTime,
      dateFormat: dateFormat,
      monthFormat: monthFormat,
    );
    final timePart = formatTime(dateTime, is24HourFormat: is24HourFormat);
    return '$datePart $timePart';
  }
}

import 'package:flutter/cupertino.dart';

import 'cupertino_form_theme.dart';

/// Reusable Cupertino form widgets following Apple's HIG.
class CupertinoFormWidgets {
  /// Creates a section title with consistent styling.
  static Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: CupertinoFormTheme.sectionTitleStyle),
    );
  }

  /// Creates a styled text field.
  static Widget textField({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: CupertinoFormTheme.inputPadding,
      decoration: CupertinoFormTheme.inputDecoration,
      style: CupertinoFormTheme.inputTextStyle,
      placeholderStyle: CupertinoFormTheme.placeholderStyle,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }

  /// Creates a styled button for date/time selection.
  static Widget selectionButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    Color color = CupertinoFormTheme.primaryColor,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: CupertinoFormTheme.inputPadding,
        decoration: CupertinoFormTheme.buttonDecoration(color),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: color,
                    size: CupertinoFormTheme.smallIconSize,
                  ),
                  SizedBox(width: CupertinoFormTheme.smallSpacing),
                ],
                Text(
                  label,
                  style: CupertinoFormTheme.labelTextStyle.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
            Text(value, style: CupertinoFormTheme.valueTextStyle),
          ],
        ),
      ),
    );
  }

  /// Creates a segmented control with consistent styling.
  static Widget segmentedControl<T extends Object>({
    required Map<T, Widget> children,
    required T? groupValue,
    required ValueChanged<T> onValueChanged,
    Color selectedColor = CupertinoFormTheme.primaryColor,
  }) {
    return CupertinoSegmentedControl<T>(
      children: children,
      groupValue: groupValue,
      onValueChanged: onValueChanged,
      borderColor: CupertinoColors.systemGrey4,
      selectedColor: selectedColor,
      unselectedColor: CupertinoColors.systemBackground,
      pressedColor: selectedColor.withOpacity(0.2),
    );
  }

  /// Creates a styled form group container.
  static Widget formGroup({
    required List<Widget> children,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(title),
        Container(
          decoration: CupertinoFormTheme.inputDecoration,
          padding: CupertinoFormTheme.inputPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// Creates a primary action button.
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        borderRadius: BorderRadius.circular(CupertinoFormTheme.borderRadius),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Creates a date picker with consistent styling.
  static Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
  }) async {
    DateTime? pickedDate;
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    onDateTimeChanged: (val) => pickedDate = val,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
    return pickedDate;
  }

  /// Creates a time picker with consistent styling.
  static Future<DateTime?> showTimePicker({
    required BuildContext context,
    required DateTime initialTime,
  }) async {
    DateTime? pickedTime;
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialTime,
                    onDateTimeChanged: (val) => pickedTime = val,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
    return pickedTime;
  }
}

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/logger.dart';
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
    DateTime? minimumDate,
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
                    minimumDate: minimumDate,
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
    DateTime? minimumDate,
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
                    minimumDate: minimumDate,
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

  /// Creates a duration picker for estimated or traveling time.
  static Future<int> showDurationPicker({
    required BuildContext context,
    int initialHours = 0,
    int initialMinutes = 0,
    int maxHours = 120,
    int minuteInterval = 15,
  }) async {
    int? pickedHours = initialHours;
    int? pickedMinutes = initialMinutes;
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
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (index) => pickedHours = index,
                          children: [
                            for (var i = 0; i <= maxHours; i++)
                              Text('$i hours'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged:
                              (index) => pickedMinutes = index * minuteInterval,
                          children: [
                            for (var i = 0; i < 60 ~/ minuteInterval; i++)
                              Text('${i * minuteInterval} minutes'),
                          ],
                        ),
                      ),
                    ],
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
    return (pickedHours ?? 0) * 3600000 + (pickedMinutes ?? 0) * 60000;
  }

  /// Creates a color picker.
  static Widget colorPicker({
    required List<Color> colors,
    required int? selectedColor,
    required ValueChanged<int?> onColorSelected,
  }) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 1, // +1 for "No color" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "No color" option
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onColorSelected(null),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.systemBackground,
                    border: Border.all(
                      color:
                          selectedColor == null
                              ? CupertinoFormTheme.primaryColor
                              : CupertinoColors.systemGrey4,
                      width: 2,
                    ),
                  ),
                  child:
                      selectedColor == null
                          ? const Icon(
                            CupertinoIcons.checkmark,
                            color: CupertinoFormTheme.primaryColor,
                            size: CupertinoFormTheme.smallIconSize,
                          )
                          : null,
                ),
              ),
            );
          }

          final color = colors[index - 1];
          final colorValue = color.value;
          final isSelected = selectedColor == colorValue;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onColorSelected(colorValue),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color:
                        isSelected
                            ? CupertinoFormTheme.primaryColor
                            : CupertinoColors.systemGrey4,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(
                          CupertinoIcons.checkmark,
                          color: CupertinoColors.white,
                          size: CupertinoFormTheme.smallIconSize,
                        )
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Creates a priority slider.
  static Widget prioritySlider({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return CupertinoSlider(
      min: 1,
      max: 10,
      divisions: 9,
      value: value.toDouble(),
      onChanged: (val) => onChanged(val.toInt()),
      activeColor: CupertinoFormTheme.getPriorityColor(value),
      thumbColor: CupertinoColors.white,
    );
  }

  /// Creates an image picker widget.
  static Widget imagePicker({
    required File? image,
    required VoidCallback onPickImage,
  }) {
    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        padding: CupertinoFormTheme.inputPadding,
        decoration: CupertinoFormTheme.inputDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Image', style: CupertinoFormTheme.labelTextStyle),
            image != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
                : const Icon(
                  CupertinoIcons.photo,
                  color: CupertinoColors.systemGrey,
                  size: CupertinoFormTheme.standardIconSize,
                ),
          ],
        ),
      ),
    );
  }

  /// Picks an image from the gallery.
  static Future<File?> pickImage(BuildContext context) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      logError('Failed to pick image: $e');
      if (context.mounted) {
        await showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: const Text('Failed to pick image.'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
      return null;
    }
  }
}

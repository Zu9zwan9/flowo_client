import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/logger.dart';
import 'cupertino_form_theme.dart';

class CupertinoFormWidgets {
  const CupertinoFormWidgets._(); // Private constructor for static-only class

  /// Creates a section title with consistent styling.
  static Widget sectionTitle(BuildContext context, String title) {
    final theme = CupertinoFormTheme(context);
    // Arrange
    final text = Text(title, style: theme.sectionTitleStyle);
    // Act & Assert
    return Padding(
      padding: EdgeInsets.only(bottom: CupertinoFormTheme.smallSpacing),
      child: text,
    );
  }

  /// Creates a styled text field.
  static Widget textField({
    required BuildContext context,
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    final theme = CupertinoFormTheme(context);
    // Arrange
    final textField = CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: CupertinoFormTheme.inputPadding,
      decoration: theme.inputDecoration,
      style: theme.inputTextStyle,
      placeholderStyle: theme.placeholderStyle,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
    // Act & Assert (validator handled by Form)
    return textField;
  }

  /// Creates a styled button for date/time selection.
  static Widget selectionButton({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
    double iconSize = 20.0,
  }) {
    final theme = CupertinoFormTheme(context);
    final effectiveColor = color ?? theme.primaryColor;
    // Arrange
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: effectiveColor,
                size: CupertinoFormTheme.smallIconSize,
              ),
              SizedBox(width: CupertinoFormTheme.smallSpacing),
            ],
            Text(
              label,
              style: theme.labelTextStyle.copyWith(color: effectiveColor),
            ),
          ],
        ),
        Text(value, style: theme.valueTextStyle),
      ],
    );
    // Act
    final button = Container(
      padding: CupertinoFormTheme.inputPadding,
      decoration: theme.buttonDecoration(effectiveColor),
      child: content,
    );
    // Assert
    return GestureDetector(onTap: onTap, child: button);
  }

  /// Creates a segmented control with consistent styling.
  static Widget segmentedControl<T extends Object>({
    required BuildContext context,
    required Map<T, Widget> children,
    required T? groupValue,
    required ValueChanged<T> onValueChanged,
    Color? selectedColor,
  }) {
    final theme = CupertinoFormTheme(context);
    final effectiveSelectedColor = selectedColor ?? theme.primaryColor;
    // Arrange & Act
    final control = CupertinoSegmentedControl<T>(
      children: children,
      groupValue: groupValue,
      onValueChanged: onValueChanged,
      borderColor: CupertinoColors.systemGrey4,
      selectedColor: effectiveSelectedColor,
      unselectedColor: theme.backgroundColor,
      pressedColor: effectiveSelectedColor.withOpacity(0.2),
    );
    // Assert (handled by Flutter's widget system)
    return control;
  }

  /// Creates a styled form group container.
  static Widget formGroup({
    required BuildContext context,
    required List<Widget> children,
    required String title,
  }) {
    final theme = CupertinoFormTheme(context);
    // Arrange
    final titleWidget = sectionTitle(context, title);
    final content = Container(
      decoration: theme.inputDecoration,
      padding: CupertinoFormTheme.inputPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
    // Act
    final group = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titleWidget, content],
    );
    // Assert
    return group;
  }

  /// Creates a primary action button.
  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    final theme = CupertinoFormTheme(context);
    // Arrange & Act
    final button = SizedBox(
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
    // Assert
    return button;
  }

  /// Creates a date picker with consistent styling.
  static Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? minimumDate,
  }) async {
    final theme = CupertinoFormTheme(context);
    DateTime? pickedDate;
    // Arrange & Act
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: theme.backgroundColor,
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
                _buildPickerActions(context, () => pickedDate),
              ],
            ),
          ),
    );
    // Assert
    return pickedDate;
  }

  /// Creates a time picker with consistent styling.
  static Future<DateTime?> showTimePicker({
    required BuildContext context,
    required DateTime initialTime,
    DateTime? minimumDate,
  }) async {
    final theme = CupertinoFormTheme(context);
    DateTime? pickedTime;
    // Arrange & Act
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: theme.backgroundColor,
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
                _buildPickerActions(context, () => pickedTime),
              ],
            ),
          ),
    );
    // Assert
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
    final theme = CupertinoFormTheme(context);
    int? pickedHours = initialHours;
    int? pickedMinutes = initialMinutes;
    // Arrange & Act
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: theme.backgroundColor,
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
                _buildPickerActions(
                  context,
                  () =>
                      (pickedHours ?? 0) * 3600000 +
                      (pickedMinutes ?? 0) * 60000,
                ),
              ],
            ),
          ),
    );
    // Assert
    return (pickedHours ?? 0) * 3600000 + (pickedMinutes ?? 0) * 60000;
  }

  /// Helper method for picker actions.
  static Widget _buildPickerActions(
    BuildContext context,
    ValueGetter<dynamic> onDone,
  ) {
    final theme = CupertinoFormTheme(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CupertinoButton(
          child: Text(
            'Cancel',
            style: theme.helperTextStyle.copyWith(fontSize: 17),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoButton(
          child: const Text(
            'Done',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// Creates a color picker.
  static Widget colorPicker({
    required BuildContext context,
    required List<Color> colors,
    required int? selectedColor,
    required ValueChanged<int?> onColorSelected,
  }) {
    final theme = CupertinoFormTheme(context);
    // Arrange & Act
    final picker = SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildColorOption(
              context,
              null,
              selectedColor == null,
              onColorSelected,
            );
          }
          final color = colors[index - 1];
          return _buildColorOption(
            context,
            color.value,
            selectedColor == color.value,
            onColorSelected,
          );
        },
      ),
    );
    // Assert
    return picker;
  }

  static Widget _buildColorOption(
    BuildContext context,
    int? colorValue,
    bool isSelected,
    ValueChanged<int?> onColorSelected,
  ) {
    final theme = CupertinoFormTheme(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onColorSelected(colorValue),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                colorValue != null ? Color(colorValue) : theme.backgroundColor,
            border: Border.all(
              color:
                  isSelected
                      ? theme.primaryColor
                      : CupertinoColors.systemBackground,
              width: 2,
            ),
          ),
          child:
              isSelected
                  ? Icon(
                    CupertinoIcons.checkmark,
                    color:
                        colorValue != null
                            ? CupertinoColors.white
                            : theme.primaryColor,
                    size: CupertinoFormTheme.smallIconSize,
                  )
                  : null,
        ),
      ),
    );
  }

  /// Creates a priority slider.
  static Widget prioritySlider({
    required BuildContext context,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final theme = CupertinoFormTheme(context);
    // Arrange & Act
    final slider = CupertinoSlider(
      min: 1,
      max: 10,
      divisions: 9,
      value: value.toDouble(),
      onChanged: (val) => onChanged(val.toInt()),
      activeColor: theme.getPriorityColor(value),
      thumbColor: CupertinoColors.white,
    );
    // Assert
    return slider;
  }

  /// Creates an image picker widget.
  static Widget imagePicker({
    required BuildContext context,
    required File? image,
    required VoidCallback onPickImage,
  }) {
    final theme = CupertinoFormTheme(context);
    // Arrange
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Image', style: theme.labelTextStyle),
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
            : Icon(
              CupertinoIcons.photo,
              color: theme.placeholderStyle.color,
              size: CupertinoFormTheme.standardIconSize,
            ),
      ],
    );
    // Act
    final picker = Container(
      padding: CupertinoFormTheme.inputPadding,
      decoration: theme.inputDecoration,
      child: content,
    );
    // Assert
    return GestureDetector(onTap: onPickImage, child: picker);
  }

  /// Picks an image from the gallery.
  static Future<File?> pickImage(BuildContext context) async {
    // Arrange
    final picker = ImagePicker();
    // Act
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) return File(pickedFile.path);
      return null;
    } catch (e) {
      logError('Failed to pick image: $e');
      // Assert
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

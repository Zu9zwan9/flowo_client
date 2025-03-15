import 'package:flutter/cupertino.dart';

/// A collection of reusable Cupertino form widgets for task forms
/// that follow Apple's Human Interface Guidelines.
class CupertinoTaskForm {
  // Typography
  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: CupertinoColors.label,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 17,
    color: CupertinoColors.label,
  );

  static const TextStyle placeholderStyle = TextStyle(
    fontSize: 17,
    color: CupertinoColors.systemGrey,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 15,
    color: CupertinoColors.systemBlue,
  );

  static const TextStyle valueTextStyle = TextStyle(
    fontSize: 17,
    color: CupertinoColors.label,
  );

  static const TextStyle helperTextStyle = TextStyle(
    fontSize: 13,
    color: CupertinoColors.systemGrey,
  );

  // Spacing
  static const double verticalSpacing = 16.0;
  static const double horizontalSpacing = 16.0;
  static const double sectionSpacing = 24.0;
  static const double elementSpacing = 12.0;

  // Colors
  static const Color primaryColor = CupertinoColors.systemBlue;
  static const Color secondaryColor = CupertinoColors.systemGreen;
  static const Color accentColor = CupertinoColors.systemOrange;
  static const Color backgroundColor = CupertinoColors.systemBackground;
  static const Color groupedBackgroundColor =
      CupertinoColors.systemGroupedBackground;

  // Decorations
  static BoxDecoration inputDecoration = BoxDecoration(
    color: CupertinoColors.systemBackground,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: CupertinoColors.systemGrey4),
  );

  static BoxDecoration buttonDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(10),
  );

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );

  /// Creates a section title with consistent styling
  static Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: sectionTitleStyle),
    );
  }

  /// Creates a styled text field with consistent appearance
  static Widget textField({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: inputPadding,
      decoration: inputDecoration,
      style: inputTextStyle,
      placeholderStyle: placeholderStyle,
      keyboardType: keyboardType,
      autofocus: autofocus,
    );
  }

  /// Creates a styled button for date/time selection
  static Widget selectionButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    Color color = primaryColor,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: buttonPadding,
        decoration: buttonDecoration(color),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label, style: labelTextStyle.copyWith(color: color)),
              ],
            ),
            Text(value, style: valueTextStyle),
          ],
        ),
      ),
    );
  }

  /// Creates a segmented control with consistent styling
  static Widget segmentedControl<T extends Object>({
    required Map<T, Widget> children,
    required T groupValue,
    required ValueChanged<T> onValueChanged,
    Color selectedColor = primaryColor,
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

  /// Creates a primary action button
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      borderRadius: BorderRadius.circular(10),
      onPressed: onPressed,
      child: Text(text, style: buttonTextStyle),
    );
  }

  /// Creates a color selector with consistent styling
  static Widget colorSelector({
    required List<Color> colors,
    required int? selectedColorValue,
    required Function(int?) onColorSelected,
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
                    color: CupertinoColors.white,
                    border: Border.all(
                      color:
                          selectedColorValue == null
                              ? primaryColor
                              : CupertinoColors.systemGrey,
                      width: 2,
                    ),
                  ),
                  child:
                      selectedColorValue == null
                          ? Icon(
                            CupertinoIcons.checkmark,
                            color: primaryColor,
                            size: 20,
                          )
                          : null,
                ),
              ),
            );
          }

          final color = colors[index - 1];
          final colorValue = color.value;
          final isSelected = selectedColorValue == colorValue;

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
                        isSelected ? primaryColor : CupertinoColors.systemGrey,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(
                          CupertinoIcons.checkmark,
                          color: CupertinoColors.white,
                          size: 20,
                        )
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Creates an improved priority slider with visual indicators
  static Widget prioritySlider({
    required double value,
    required ValueChanged<double> onChanged,
    required Color Function(int) getPriorityColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Low', style: helperTextStyle),
            Text('High', style: helperTextStyle),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: CupertinoSlider(
            min: 1,
            max: 10,
            divisions: 9,
            value: value,
            onChanged: onChanged,
            activeColor: getPriorityColor(value.toInt()),
            thumbColor: CupertinoColors.white,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final value = index * 2 + 1; // 1, 3, 5, 7, 9
            return Container(
              width: 2,
              height: 8,
              color: CupertinoColors.systemGrey4,
            );
          }),
        ),
      ],
    );
  }

  /// Creates a styled form group container
  static Widget formGroup({
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Creates a helper text with consistent styling
  static Widget helperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(text, style: helperTextStyle),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoTaskForm {
  const CupertinoTaskForm(this.context);

  final BuildContext context;

  // MARK: - Theme accessors
  Color get backgroundColor => _backgroundColor;
  Color get secondaryBackgroundColor => _secondaryBackgroundColor;

  /// Gets the current CupertinoTheme from the context
  CupertinoThemeData get _theme => CupertinoTheme.of(context);

  /// Gets appropriate text color based on current brightness
  Color get _textColor => _theme.textTheme.textStyle.color!;

  /// Gets appropriate label color based on current brightness
  Color get _labelColor => _theme.primaryColor;

  /// Gets appropriate background color based on current brightness
  Color get _backgroundColor =>
      CupertinoColors.systemBackground.resolveFrom(context);

  /// Gets appropriate secondary background color
  Color get _secondaryBackgroundColor =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);

  /// Gets a muted text color for placeholders and helper text
  Color get _mutedTextColor => CupertinoColors.systemGrey.resolveFrom(context);

  /// Gets border color appropriate for the current theme
  Color get _borderColor => CupertinoColors.systemGrey4.resolveFrom(context);

  // MARK: - Typography

  /// Section title style that adapts to the current theme
  TextStyle get sectionTitleStyle => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: _textColor,
  );

  /// Input text style that adapts to the current theme
  TextStyle get inputTextStyle => TextStyle(fontSize: 17, color: _textColor);

  /// Placeholder style that adapts to the current theme
  TextStyle get placeholderStyle =>
      TextStyle(fontSize: 17, color: _mutedTextColor);

  /// Button text style with appropriate weight
  TextStyle get buttonTextStyle =>
      const TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

  /// Label style that adapts to the current theme
  TextStyle labelTextStyle({Color? color}) =>
      TextStyle(fontSize: 15, color: color ?? _labelColor);

  /// Value text style that adapts to the current theme
  TextStyle get valueTextStyle => TextStyle(fontSize: 17, color: _textColor);

  /// Helper text style that adapts to the current theme
  TextStyle get helperTextStyle =>
      TextStyle(fontSize: 13, color: _mutedTextColor);

  // MARK: - Spacing Constants

  static const double verticalSpacing = 16.0;
  static const double horizontalSpacing = 16.0;
  static const double sectionSpacing = 24.0;
  static const double elementSpacing = 12.0;

  // MARK: - Decorations

  /// Adaptive input decoration that respects the current theme
  BoxDecoration get inputDecoration => BoxDecoration(
    // color: _backgroundColor,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: _borderColor),
  );

  /// Button decoration with adaptive coloring
  BoxDecoration buttonDecoration({Color? color}) => BoxDecoration(
    color: (color ?? _theme.primaryColor).withOpacity(0.1),
    borderRadius: BorderRadius.circular(10),
  );

  /// Standard padding for input fields
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );

  /// Standard padding for buttons
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );

  // MARK: - Widget Factories

  /// Creates a section title with consistent styling
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: sectionTitleStyle),
    );
  }

  /// Creates a styled text field with consistent appearance
  Widget textField({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
    FocusNode? focusNode,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onChanged,
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
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      onChanged: onChanged,
      cursorColor: _theme.primaryColor,
    );
  }

  /// Creates a styled button for date/time selection
  Widget selectionButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    final buttonColor = color ?? _theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: buttonPadding,
        decoration: buttonDecoration(color: buttonColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: buttonColor, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: labelTextStyle(color: buttonColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: valueTextStyle,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a segmented control with consistent styling
  Widget segmentedControl<T extends Object>({
    required Map<T, Widget> children,
    required T groupValue,
    required ValueChanged<T> onValueChanged,
    Color? selectedColor,
  }) {
    final themeColor = selectedColor ?? _theme.primaryColor;

    return CupertinoSegmentedControl<T>(
      children: children,
      groupValue: groupValue,
      onValueChanged: onValueChanged,
      borderColor: _borderColor,
      selectedColor: themeColor,
      unselectedColor: _backgroundColor,
      pressedColor: themeColor.withOpacity(0.2),
    );
  }

  /// Creates a primary action button
  Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive
            ? CupertinoColors.destructiveRed.resolveFrom(context)
            : null;

    return CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      borderRadius: BorderRadius.circular(10),
      onPressed: isLoading ? null : onPressed,
      disabledColor: CupertinoColors.systemGrey3.resolveFrom(context),
      child:
          isLoading
              ? const CupertinoActivityIndicator()
              : Text(text, style: buttonTextStyle),
    );
  }

  /// Creates a color selector with consistent styling
  Widget colorSelector({
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
            final isSelected = selectedColorValue == null;
            final borderColor = isSelected ? _theme.primaryColor : _borderColor;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onColorSelected(null),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _backgroundColor,
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child:
                      isSelected
                          ? Icon(
                            CupertinoIcons.checkmark,
                            color: _theme.primaryColor,
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
          final borderColor = isSelected ? _theme.primaryColor : _borderColor;

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
                  border: Border.all(color: borderColor, width: 2),
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
  Widget prioritySlider({
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
            thumbColor: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            return Container(width: 2, height: 8, color: _borderColor);
          }),
        ),
      ],
    );
  }

  /// Creates a styled form group container
  Widget formGroup({
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Creates a helper text with consistent styling
  Widget helperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(text, style: helperTextStyle),
    );
  }

  /// Creates a divider with appropriate styling for the current theme
  Widget divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(height: 0.5, color: _borderColor),
    );
  }

  /// Creates a secondary action button
  Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      borderRadius: BorderRadius.circular(10),
      color: CupertinoColors.systemGrey5.resolveFrom(context),
      onPressed: onPressed,
      child: Text(text, style: buttonTextStyle.copyWith(color: _textColor)),
    );
  }
}

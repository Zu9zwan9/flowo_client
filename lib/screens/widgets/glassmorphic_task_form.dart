import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../design/glassmorphic_container.dart';
import '../../design/glassmorphic_form_theme.dart';
import '../../design/glassmorphic_form_widgets.dart';
import '../../theme_notifier.dart';

/// A utility class that provides methods for creating consistently styled
/// glassmorphic form elements for task-related screens.
///
/// This class extends the functionality of CupertinoTaskForm with glassmorphic styling,
/// vibrant color accents, and unique design elements.
class GlassmorphicTaskForm {
  const GlassmorphicTaskForm(this.context);

  final BuildContext context;

  // MARK: - Theme accessors

  /// Gets the ThemeNotifier from the context
  ThemeNotifier get _themeNotifier => Provider.of<ThemeNotifier>(context);

  /// Gets the GlassmorphicTheme from the ThemeNotifier
  GlassmorphicTheme get _glassmorphicTheme => _themeNotifier.glassmorphicTheme;

  /// Gets the CupertinoTheme from the context
  CupertinoThemeData get _theme => CupertinoTheme.of(context);

  /// Gets the background color for the screen
  Color get backgroundColor => _themeNotifier.backgroundColor;

  /// Gets the secondary background color for the screen
  Color get secondaryBackgroundColor =>
      _themeNotifier.backgroundColor.withOpacity(0.8);

  /// Gets the primary color for accents
  Color get primaryColor => _themeNotifier.primaryColor;

  /// Gets the text color based on the current theme
  Color get textColor => _themeNotifier.textColor;

  /// Gets a muted text color for placeholders and helper text
  Color get mutedTextColor => CupertinoColors.systemGrey.resolveFrom(context);

  /// Gets the border color for glassmorphic containers
  Color get borderColor => _glassmorphicTheme.borderColor;

  /// Gets vibrant accent colors for various elements
  List<Color> get accentColors => [
    primaryColor,
    CupertinoColors.systemTeal,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemPurple,
  ];

  // MARK: - Typography

  /// Section title style that adapts to the current theme
  TextStyle get sectionTitleStyle => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: textColor,
  );

  /// Input text style that adapts to the current theme
  TextStyle get inputTextStyle => TextStyle(fontSize: 17, color: textColor);

  /// Placeholder style that adapts to the current theme
  TextStyle get placeholderStyle =>
      TextStyle(fontSize: 17, color: mutedTextColor);

  /// Button text style with appropriate weight
  TextStyle get buttonTextStyle => const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.white,
  );

  /// Label style that adapts to the current theme
  TextStyle labelTextStyle({Color? color}) =>
      TextStyle(fontSize: 15, color: color ?? primaryColor);

  /// Value text style that adapts to the current theme
  TextStyle get valueTextStyle => TextStyle(fontSize: 17, color: textColor);

  /// Helper text style that adapts to the current theme
  TextStyle get helperTextStyle =>
      TextStyle(fontSize: 13, color: mutedTextColor);

  // MARK: - Spacing Constants

  static const double verticalSpacing = 16.0;
  static const double horizontalSpacing = 16.0;
  static const double sectionSpacing = 24.0;
  static const double elementSpacing = 12.0;

  // MARK: - Decorations

  /// Glassmorphic input decoration
  BoxDecoration get inputDecoration => BoxDecoration(
    color: backgroundColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: borderColor),
  );

  /// Glassmorphic button decoration with adaptive coloring
  BoxDecoration buttonDecoration({Color? color}) {
    final effectiveColor = color ?? primaryColor;
    return BoxDecoration(
      color: effectiveColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: effectiveColor.withOpacity(0.3), width: 1.5),
    );
  }

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

  /// Creates a section title with glassmorphic styling
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        borderRadius: BorderRadius.circular(10.0),
        blur: _glassmorphicTheme.defaultBlur,
        opacity: _glassmorphicTheme.defaultOpacity,
        borderWidth: _glassmorphicTheme.defaultBorderWidth,
        borderColor: accentColors[0].withOpacity(0.3),
        backgroundColor: accentColors[1].withOpacity(0.1),
        child: Text(title, style: sectionTitleStyle),
      ),
    );
  }

  /// Creates a glassmorphic text field with consistent appearance
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
    return GlassmorphicFormWidgets.textField(
      context: context,
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }

  /// Creates a glassmorphic button for date/time selection
  Widget selectionButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    final buttonColor = color ?? primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        padding: buttonPadding,
        borderRadius: BorderRadius.circular(10.0),
        blur: _glassmorphicTheme.defaultBlur,
        opacity: _glassmorphicTheme.defaultOpacity,
        borderWidth: _glassmorphicTheme.defaultBorderWidth,
        borderColor: buttonColor.withOpacity(0.3),
        backgroundColor: buttonColor.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: buttonColor, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label, style: labelTextStyle(color: buttonColor)),
              ],
            ),
            Text(value, style: valueTextStyle),
          ],
        ),
      ),
    );
  }

  /// Creates a glassmorphic segmented control with consistent styling
  Widget segmentedControl<T extends Object>({
    required Map<T, Widget> children,
    required T groupValue,
    required ValueChanged<T> onValueChanged,
    Color? selectedColor,
  }) {
    return GlassmorphicFormWidgets.segmentedControl(
      context: context,
      children: children,
      groupValue: groupValue,
      onValueChanged: onValueChanged,
      selectedColor: selectedColor,
    );
  }

  /// Creates a glassmorphic primary action button
  Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive
            ? CupertinoColors.destructiveRed.resolveFrom(context)
            : primaryColor;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 50,
        borderRadius: BorderRadius.circular(10.0),
        blur: _glassmorphicTheme.defaultBlur,
        opacity: 0.2,
        borderWidth: _glassmorphicTheme.defaultBorderWidth,
        borderColor: color.withOpacity(0.6),
        backgroundColor: color.withOpacity(0.3),
        child: Center(
          child:
              isLoading
                  ? const CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                  )
                  : Text(text, style: buttonTextStyle),
        ),
      ),
    );
  }

  /// Creates a glassmorphic color selector with consistent styling
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

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onColorSelected(null),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: backgroundColor.withOpacity(0.3),
                    border: Border.all(
                      color: isSelected ? primaryColor : borderColor,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child:
                      isSelected
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
                  color: color.withOpacity(0.8),
                  border: Border.all(
                    color: isSelected ? primaryColor : borderColor,
                    width: isSelected ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
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

  /// Creates an improved glassmorphic priority slider with visual indicators
  Widget prioritySlider({
    required double value,
    required ValueChanged<double> onChanged,
    required Color Function(int) getPriorityColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _glassmorphicTheme.defaultBlur / 2,
          sigmaY: _glassmorphicTheme.defaultBlur / 2,
        ),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: _glassmorphicTheme.borderColor,
              width: _glassmorphicTheme.defaultBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Low', style: helperTextStyle),
                  Text('High', style: helperTextStyle),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final priorityValue = 1 + index * 2;
                  return Container(
                    width: 2,
                    height: 8,
                    color: getPriorityColor(priorityValue).withOpacity(0.5),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates a styled glassmorphic form group container
  Widget formGroup({
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return GlassmorphicContainer(
      width: double.infinity,
      padding: padding,
      borderRadius: BorderRadius.circular(10.0),
      blur: _glassmorphicTheme.defaultBlur,
      opacity: _glassmorphicTheme.defaultOpacity,
      borderWidth: _glassmorphicTheme.defaultBorderWidth,
      borderColor: _glassmorphicTheme.borderColor,
      backgroundColor: backgroundColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Creates a helper text with consistent styling
  Widget helperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: Text(text, style: helperTextStyle),
    );
  }

  /// Creates a divider with appropriate styling for the current theme
  Widget divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(height: 0.5, color: borderColor.withOpacity(0.5)),
    );
  }

  /// Creates a secondary action button with glassmorphic styling
  Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 50,
        borderRadius: BorderRadius.circular(10.0),
        blur: _glassmorphicTheme.defaultBlur,
        opacity: 0.15,
        borderWidth: _glassmorphicTheme.defaultBorderWidth,
        borderColor: borderColor,
        backgroundColor: backgroundColor.withOpacity(0.1),
        child: Center(
          child: Text(text, style: buttonTextStyle.copyWith(color: textColor)),
        ),
      ),
    );
  }

  /// Formats a date for display
  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Formats a time for display
  String formatTime(DateTime? time) {
    if (time == null) return 'Not set';

    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

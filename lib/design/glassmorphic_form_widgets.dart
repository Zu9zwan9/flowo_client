import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/logger.dart';
import 'cupertino_form_widgets.dart';
import 'glassmorphic_container.dart';
import 'glassmorphic_form_theme.dart';

/// A collection of glassmorphic form widgets adhering to Apple's HIG with dynamic theming.
/// This extends the CupertinoFormWidgets with glassmorphic styling.
class GlassmorphicFormWidgets {
  const GlassmorphicFormWidgets._(); // Private constructor for static-only class

  /// Creates a glassmorphic section title with consistent styling.
  static Widget sectionTitle(BuildContext context, String title) {
    final theme = GlassmorphicFormTheme(context);
    // Arrange
    final text = Text(title, style: theme.sectionTitleStyle);
    // Act & Assert
    return Padding(
      padding: EdgeInsets.only(bottom: GlassmorphicFormTheme.smallSpacing),
      child: text,
    );
  }

  /// Creates a glassmorphic text field.
  static Widget textField({
    required BuildContext context,
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    final theme = GlassmorphicFormTheme(context);
    // Arrange
    final textField = ClipRRect(
      borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: theme.defaultBlur,
          sigmaY: theme.defaultBlur,
        ),
        child: Container(
          decoration: theme.glassmorphicInputDecoration,
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            maxLines: maxLines,
            padding: GlassmorphicFormTheme.inputPadding,
            decoration: null, // Remove default decoration
            style: theme.inputTextStyle,
            placeholderStyle: theme.placeholderStyle,
            keyboardType: keyboardType,
            onChanged: onChanged,
          ),
        ),
      ),
    );
    // Act & Assert (validator handled by Form)
    return textField;
  }

  /// Creates a glassmorphic button for date/time selection.
  static Widget selectionButton({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    final theme = GlassmorphicFormTheme(context);
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
                size: GlassmorphicFormTheme.smallIconSize,
              ),
              SizedBox(width: GlassmorphicFormTheme.smallSpacing),
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
    final button = GlassmorphicContainer(
      padding: GlassmorphicFormTheme.inputPadding,
      borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
      blur: theme.defaultBlur,
      opacity: theme.defaultOpacity,
      borderWidth: theme.defaultBorderWidth,
      borderColor: effectiveColor.withOpacity(0.3),
      backgroundColor: effectiveColor.withOpacity(0.1),
      child: content,
    );
    // Assert
    return GestureDetector(onTap: onTap, child: button);
  }

  /// Creates a glassmorphic segmented control with consistent styling.
  static Widget segmentedControl<T extends Object>({
    required BuildContext context,
    required Map<T, Widget> children,
    required T? groupValue,
    required ValueChanged<T> onValueChanged,
    Color? selectedColor,
  }) {
    final theme = GlassmorphicFormTheme(context);
    final effectiveSelectedColor = selectedColor ?? theme.primaryColor;
    // Arrange & Act
    final control = ClipRRect(
      borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: theme.defaultBlur,
          sigmaY: theme.defaultBlur,
        ),
        child: CupertinoSegmentedControl<T>(
          children: children,
          groupValue: groupValue,
          onValueChanged: onValueChanged,
          borderColor: theme.borderColor,
          selectedColor: effectiveSelectedColor,
          unselectedColor: theme.backgroundGlassColor,
          pressedColor: effectiveSelectedColor.withOpacity(0.2),
        ),
      ),
    );
    // Assert (handled by Flutter's widget system)
    return control;
  }

  /// Creates a glassmorphic styled form group container.
  static Widget formGroup({
    required BuildContext context,
    required List<Widget> children,
    required String title,
  }) {
    final theme = GlassmorphicFormTheme(context);
    // Arrange
    final titleWidget = sectionTitle(context, title);
    final content = GlassmorphicContainer(
      borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
      blur: theme.defaultBlur,
      opacity: theme.defaultOpacity,
      borderWidth: theme.defaultBorderWidth,
      padding: GlassmorphicFormTheme.inputPadding,
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

  /// Creates a glassmorphic primary action button.
  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    final theme = GlassmorphicFormTheme(context);
    final effectiveColor = backgroundColor ?? theme.primaryColor;
    // Arrange & Act
    final button = SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onPressed,
        child: GlassmorphicContainer(
          height: 50,
          borderRadius: BorderRadius.circular(
            GlassmorphicFormTheme.borderRadius,
          ),
          blur: theme.defaultBlur,
          opacity: 0.3, // More opaque for button
          borderWidth: theme.defaultBorderWidth,
          borderColor: effectiveColor.withOpacity(0.5),
          backgroundColor: effectiveColor.withOpacity(0.3),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ),
    );
    // Assert
    return button;
  }

  /// Creates a glassmorphic date picker with consistent styling.
  static Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? minimumDate,
  }) async {
    return CupertinoFormWidgets.showDatePicker(
      context: context,
      initialDate: initialDate,
      minimumDate: minimumDate,
    );
  }

  /// Creates a glassmorphic time picker with consistent styling.
  static Future<DateTime?> showTimePicker({
    required BuildContext context,
    required DateTime initialTime,
    DateTime? minimumDate,
  }) async {
    return CupertinoFormWidgets.showTimePicker(
      context: context,
      initialTime: initialTime,
      minimumDate: minimumDate,
    );
  }

  /// Creates a glassmorphic duration picker for estimated or traveling time.
  static Future<int> showDurationPicker({
    required BuildContext context,
    int initialHours = 0,
    int initialMinutes = 0,
    int maxHours = 120,
    int minuteInterval = 15,
  }) async {
    return CupertinoFormWidgets.showDurationPicker(
      context: context,
      initialHours: initialHours,
      initialMinutes: initialMinutes,
      maxHours: maxHours,
      minuteInterval: minuteInterval,
    );
  }

  /// Creates a glassmorphic color picker.
  static Widget colorPicker({
    required BuildContext context,
    required List<Color> colors,
    required int? selectedColor,
    required ValueChanged<int?> onColorSelected,
  }) {
    final theme = GlassmorphicFormTheme(context);
    // Arrange & Act
    final picker = SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildGlassmorphicColorOption(
              context,
              null,
              selectedColor == null,
              onColorSelected,
            );
          }
          final color = colors[index - 1];
          return _buildGlassmorphicColorOption(
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

  static Widget _buildGlassmorphicColorOption(
    BuildContext context,
    int? colorValue,
    bool isSelected,
    ValueChanged<int?> onColorSelected,
  ) {
    final theme = GlassmorphicFormTheme(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onColorSelected(colorValue),
        child: Container(
          width: 40,
          height: 40,
          decoration: theme.glassmorphicColorOptionDecoration(
            colorValue != null ? Color(colorValue) : theme.backgroundColor,
            isSelected,
          ),
          child:
              isSelected
                  ? Icon(
                    CupertinoIcons.checkmark,
                    color:
                        colorValue != null
                            ? CupertinoColors.white
                            : theme.primaryColor,
                    size: GlassmorphicFormTheme.smallIconSize,
                  )
                  : null,
        ),
      ),
    );
  }

  /// Creates a glassmorphic priority slider.
  static Widget prioritySlider({
    required BuildContext context,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final theme = GlassmorphicFormTheme(context);
    // Arrange & Act
    final slider = ClipRRect(
      borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: theme.defaultBlur,
          sigmaY: theme.defaultBlur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.backgroundGlassColor,
            borderRadius: BorderRadius.circular(
              GlassmorphicFormTheme.borderRadius,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: CupertinoSlider(
            min: 1,
            max: 10,
            divisions: 9,
            value: value.toDouble(),
            onChanged: (val) => onChanged(val.toInt()),
            activeColor: theme.getPriorityColor(value),
            thumbColor: CupertinoColors.white,
          ),
        ),
      ),
    );
    // Assert
    return slider;
  }

  /// Creates a glassmorphic image picker widget.
  static Widget imagePicker({
    required BuildContext context,
    required File? image,
    required VoidCallback onPickImage,
  }) {
    final theme = GlassmorphicFormTheme(context);
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
              size: GlassmorphicFormTheme.standardIconSize,
            ),
      ],
    );
    // Act
    final picker = GlassmorphicContainer(
      borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
      blur: theme.defaultBlur,
      opacity: theme.defaultOpacity,
      borderWidth: theme.defaultBorderWidth,
      padding: GlassmorphicFormTheme.inputPadding,
      child: content,
    );
    // Assert
    return GestureDetector(onTap: onPickImage, child: picker);
  }

  /// Picks an image from the gallery.
  static Future<File?> pickImage(BuildContext context) async {
    return CupertinoFormWidgets.pickImage(context);
  }
}

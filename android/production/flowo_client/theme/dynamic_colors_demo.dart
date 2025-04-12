import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../theme_notifier.dart';
import 'app_colors.dart';
import 'dynamic_colors.dart';

/// A demo widget that showcases the dynamic colors in action.
/// This widget can be used to test the dynamic colors and as an example for how to use them.
class DynamicColorsDemo extends StatelessWidget {
  const DynamicColorsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Dynamic Colors Demo'),
        backgroundColor: DynamicColors.getBackgroundColor(context),
        border: Border(
          bottom: BorderSide(
            color: DynamicColors.getDividerColor(context),
            width: 0.5,
          ),
        ),
      ),
      backgroundColor: DynamicColors.getBackgroundColor(context),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Theme Controls'),
              _buildThemeControls(context),

              _buildSectionTitle(context, 'System Colors'),
              _buildColorRow(context, 'Primary', AppColors.primary),
              _buildColorRow(context, 'Secondary', AppColors.secondary),
              _buildColorRow(context, 'Accent', AppColors.accent),
              _buildColorRow(context, 'Destructive', AppColors.destructive),
              _buildColorRow(context, 'Gray', AppColors.gray),
              _buildColorRow(context, 'Light Gray', AppColors.lightGray),
              _buildColorRow(
                context,
                'Extra Light Gray',
                AppColors.extraLightGray,
              ),

              _buildSectionTitle(context, 'Semantic Colors'),
              _buildColorRow(context, 'Label', AppColors.label),
              _buildColorRow(
                context,
                'Secondary Label',
                AppColors.secondaryLabel,
              ),
              _buildColorRow(
                context,
                'Tertiary Label',
                AppColors.tertiaryLabel,
              ),
              _buildColorRow(
                context,
                'Quaternary Label',
                AppColors.quaternaryLabel,
              ),
              _buildColorRow(context, 'Fill', AppColors.fill),
              _buildColorRow(
                context,
                'Secondary Fill',
                AppColors.secondaryFill,
              ),
              _buildColorRow(context, 'Tertiary Fill', AppColors.tertiaryFill),
              _buildColorRow(
                context,
                'Quaternary Fill',
                AppColors.quaternaryFill,
              ),
              _buildColorRow(context, 'Background', AppColors.background),
              _buildColorRow(
                context,
                'Secondary Background',
                AppColors.secondaryBackground,
              ),
              _buildColorRow(
                context,
                'Grouped Background',
                AppColors.groupedBackground,
              ),
              _buildColorRow(
                context,
                'Secondary Grouped Background',
                AppColors.secondaryGroupedBackground,
              ),
              _buildColorRow(context, 'Separator', AppColors.separator),
              _buildColorRow(
                context,
                'Opaque Separator',
                AppColors.opaqueSeparator,
              ),

              _buildSectionTitle(context, 'Task Priority Colors'),
              _buildColorRow(context, 'Low Priority', AppColors.lowPriority),
              _buildColorRow(
                context,
                'Medium Priority',
                AppColors.mediumPriority,
              ),
              _buildColorRow(context, 'High Priority', AppColors.highPriority),

              _buildSectionTitle(context, 'Notification Colors'),
              _buildColorRow(
                context,
                'Notification Badge',
                AppColors.notificationBadge,
              ),

              _buildSectionTitle(context, 'Dynamic Colors Usage'),
              _buildUsageExample(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: DynamicColors.getTextColor(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeControls(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = DynamicColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: DynamicColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DynamicColors.getShadowColor(context),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dark Mode',
                style: TextStyle(
                  color: DynamicColors.getTextColor(context),
                  fontSize: 16,
                ),
              ),
              CupertinoSwitch(
                value: isDarkMode,
                onChanged: (value) {
                  themeNotifier.setBrightness(
                    value ? Brightness.dark : Brightness.light,
                  );
                },
                activeTrackColor: DynamicColors.getPrimaryColor(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(BuildContext context, String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DynamicColors.resolveColor(context, color),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DynamicColors.getDividerColor(context),
                width: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: DynamicColors.getTextColor(context),
                fontSize: 16,
              ),
            ),
          ),
          Text(
            _colorToHex(DynamicColors.resolveColor(context, color)),
            style: TextStyle(
              color: DynamicColors.getTextColor(context).withOpacity(0.6),
              fontSize: 14,
              fontFamily: 'Menlo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageExample(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: DynamicColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DynamicColors.getShadowColor(context),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Example',
            style: TextStyle(
              color: DynamicColors.getTextColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTaskExample(context, 'Low Priority Task', 2),
          const SizedBox(height: 8),
          _buildTaskExample(context, 'Medium Priority Task', 5),
          const SizedBox(height: 8),
          _buildTaskExample(context, 'High Priority Task', 9),
          const SizedBox(height: 16),
          Text(
            'Button Example',
            style: TextStyle(
              color: DynamicColors.getTextColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton(
                context,
                'Primary',
                DynamicColors.getPrimaryColor(context),
              ),
              _buildButton(
                context,
                'Success',
                DynamicColors.getSuccessColor(context),
              ),
              _buildButton(
                context,
                'Error',
                DynamicColors.getErrorColor(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskExample(BuildContext context, String title, int priority) {
    final priorityColor = DynamicColors.getPriorityColor(context, priority);
    final priorityLabel = DynamicColors.getPriorityLabel(priority);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: DynamicColors.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DynamicColors.getDividerColor(context),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: DynamicColors.getTextColor(context),
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              priorityLabel,
              style: TextStyle(
                color: priorityColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, Color color) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      borderRadius: BorderRadius.circular(8),
      onPressed: () {},
      child: Text(
        label,
        style: TextStyle(
          color: DynamicColors.getTextColorForBackground(color),
          fontSize: 14,
        ),
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

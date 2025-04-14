import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowo_client/models/app_theme.dart';
import 'package:flowo_client/theme/theme_notifier.dart';
import 'package:flowo_client/theme/app_colors.dart';
import 'package:flowo_client/screens/widgets/settings_widgets.dart';

/// A dedicated screen for theme configuration with comprehensive customization options
/// following Apple's Human Interface Guidelines.
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  // Noise level options
  final List<String> _noiseLevels = ['None', 'Low', 'Medium', 'High'];

  // Color source options
  final List<String> _colorSources = ['System', 'Custom', 'Dynamic'];

  // Selected color source
  String _selectedColorSource = 'System';

  // Selected noise level
  String _selectedNoiseLevel = 'None';

  // Font size adjustment for accessibility
  double _fontSizeAdjustment = 0.0;

  // High contrast mode for accessibility
  bool _highContrastMode = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    // Initialize color source based on current theme mode
    if (themeNotifier.themeMode == AppTheme.custom) {
      _selectedColorSource = 'Custom';
    } else if (themeNotifier.themeMode == AppTheme.system) {
      _selectedColorSource = 'System';
    } else {
      _selectedColorSource = 'System';
    }

    // Initialize noise level based on current noise level
    final noiseLevel = themeNotifier.noiseLevel;
    if (noiseLevel <= 0.0) {
      _selectedNoiseLevel = 'None';
    } else if (noiseLevel <= 0.33) {
      _selectedNoiseLevel = 'Low';
    } else if (noiseLevel <= 0.66) {
      _selectedNoiseLevel = 'Medium';
    } else {
      _selectedNoiseLevel = 'High';
    }
  }

  // Convert noise level string to double value
  double _getNoiseLevelValue(String level) {
    switch (level) {
      case 'None':
        return 0.0;
      case 'Low':
        return 0.33;
      case 'Medium':
        return 0.66;
      case 'High':
        return 1.0;
      default:
        return 0.0;
    }
  }

  // Apply theme settings
  void _applyThemeSettings() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    // Apply color source
    if (_selectedColorSource == 'System') {
      themeNotifier.setThemeMode(AppTheme.system);
    } else if (_selectedColorSource == 'Custom') {
      themeNotifier.setThemeMode(AppTheme.custom);
    } else if (_selectedColorSource == 'Dynamic') {
      // For dynamic, we use custom theme but with system-derived colors
      themeNotifier.setThemeMode(AppTheme.custom);
      // This would be enhanced in a real implementation to use system wallpaper colors
    }

    // Apply noise level
    themeNotifier.setNoiseLevel(_getNoiseLevelValue(_selectedNoiseLevel));

    // Show confirmation
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('Theme Updated'),
            content: const Text('Your theme settings have been applied.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  // Show color picker for custom theme
  void _showColorPicker(ThemeNotifier themeNotifier) {
    final iosColors = [
      const Color(0xFF007AFF), // Blue
      const Color(0xFF34C759), // Green
      const Color(0xFFFF9500), // Orange
      const Color(0xFFFF2D55), // Red
      const Color(0xFF5856D6), // Purple
      const Color(0xFFAF52DE), // Magenta
      const Color(0xFF5AC8FA), // Teal
      const Color(0xFFFFCC00), // Yellow
      const Color(0xFF8E8E93), // Gray
    ];

    Color selectedColor = themeNotifier.customColor;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemBackground,
                      context,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              'Choose Color',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('Done'),
                              onPressed: () {
                                themeNotifier.setCustomColor(selectedColor);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'iOS Colors',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              iosColors.map((color) {
                                final isSelected =
                                    selectedColor.value == color.value;
                                return GestureDetector(
                                  onTap:
                                      () =>
                                          setState(() => selectedColor = color),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? CupertinoColors.white
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CupertinoColors.systemGrey
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
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
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Custom Color',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Hue slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text('Hue', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value:
                                    HSVColor.fromColor(selectedColor).hue / 360,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withHue(value * 360).toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                        // Saturation slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Saturation',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value:
                                    HSVColor.fromColor(
                                      selectedColor,
                                    ).saturation,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor
                                            .withSaturation(value)
                                            .toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                        // Value slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Brightness',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value: HSVColor.fromColor(selectedColor).value,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withValue(value).toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                        // Contrast check
                        const SizedBox(height: 16),
                        const Text(
                          'Accessibility Check',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sample Text on Selected Color',
                                style: TextStyle(
                                  color: AppColors.appropriateTextColor(
                                    selectedColor,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This text shows contrast against your selected color.',
                                style: TextStyle(
                                  color: AppColors.appropriateTextColor(
                                    selectedColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    _isColorAccessible(selectedColor)
                                        ? CupertinoIcons.check_mark_circled
                                        : CupertinoIcons
                                            .exclamationmark_triangle,
                                    color: AppColors.appropriateTextColor(
                                      selectedColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isColorAccessible(selectedColor)
                                        ? 'Good contrast ratio'
                                        : 'Poor contrast ratio',
                                    style: TextStyle(
                                      color: AppColors.appropriateTextColor(
                                        selectedColor,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // Check if a color has good contrast for accessibility
  bool _isColorAccessible(Color color) {
    // Calculate contrast ratio with white and black text
    final luminance = color.computeLuminance();
    final contrastWithWhite = (luminance + 0.05) / 0.05;
    final contrastWithBlack = (1.05) / (luminance + 0.05);

    // WCAG 2.0 level AA requires a contrast ratio of at least 4.5:1 for normal text
    return contrastWithWhite >= 4.5 || contrastWithBlack >= 4.5;
  }

  // Show color source picker
  void _showColorSourcePicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 280,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32.0,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedColorSource = _colorSources[index];
                      });
                    },
                    children:
                        _colorSources
                            .map((source) => Center(child: Text(source)))
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Show noise level picker
  void _showNoiseLevelPicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 280,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32.0,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedNoiseLevel = _noiseLevels[index];
                      });
                    },
                    children:
                        _noiseLevels
                            .map((level) => Center(child: Text(level)))
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Theme Settings'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: [
            SettingsSection(
              title: 'Appearance',
              footerText: 'Choose how your app looks and feels.',
              children: [
                SettingsItem(
                  label: 'Color Source',
                  subtitle: 'Choose between system, custom, or dynamic colors',
                  trailing: Text(_selectedColorSource),
                  onTap: _showColorSourcePicker,
                ),
                if (_selectedColorSource == 'Custom') ...[
                  SettingsItem(
                    label: 'Theme Color',
                    subtitle: 'Choose your custom theme color',
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeNotifier.customColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CupertinoColors.systemGrey3,
                          width: 1,
                        ),
                      ),
                    ),
                    onTap: () => _showColorPicker(themeNotifier),
                  ),
                  SettingsSliderItem(
                    label: 'Color Intensity',
                    value: themeNotifier.colorIntensity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    valueLabel:
                        '${(themeNotifier.colorIntensity * 100).round()}%',
                    onChanged:
                        (value) => themeNotifier.setColorIntensity(value),
                    subtitle: 'Adjust the intensity of your custom color',
                  ),
                ],
                SettingsItem(
                  label: 'Noise Effect',
                  subtitle: 'Add texture to your theme background',
                  trailing: Text(_selectedNoiseLevel),
                  onTap: _showNoiseLevelPicker,
                ),
                SettingsToggleItem(
                  label: 'Use Gradient',
                  value: themeNotifier.useGradient,
                  onChanged: (value) => themeNotifier.setUseGradient(value),
                  subtitle: 'Apply gradient effect to the background',
                ),
                if (themeNotifier.useGradient)
                  SettingsItem(
                    label: 'Secondary Color',
                    subtitle: 'Choose the secondary color for gradient',
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeNotifier.secondaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CupertinoColors.systemGrey3,
                          width: 1,
                        ),
                      ),
                    ),
                    onTap: () => _showSecondaryColorPicker(themeNotifier),
                  ),
              ],
            ),
            SettingsSection(
              title: 'Accessibility',
              footerText: 'Make the app easier to use for everyone.',
              children: [
                SettingsSliderItem(
                  label: 'Text Size',
                  value: _fontSizeAdjustment,
                  min: -0.3,
                  max: 0.3,
                  divisions: 6,
                  valueLabel:
                      _fontSizeAdjustment == 0.0
                          ? 'Default'
                          : _fontSizeAdjustment > 0
                          ? '+${(_fontSizeAdjustment * 100).round()}%'
                          : '${(_fontSizeAdjustment * 100).round()}%',
                  onChanged: (value) {
                    setState(() {
                      _fontSizeAdjustment = value;
                    });
                    // In a real implementation, this would adjust text scaling
                  },
                  subtitle: 'Adjust the size of text throughout the app',
                ),
                SettingsToggleItem(
                  label: 'High Contrast',
                  value: _highContrastMode,
                  onChanged: (value) {
                    setState(() {
                      _highContrastMode = value;
                    });
                    // In a real implementation, this would adjust contrast
                  },
                  subtitle: 'Increase contrast for better readability',
                ),
                SettingsToggleItem(
                  label: 'Reduce Motion',
                  value: false,
                  onChanged: (value) {
                    // In a real implementation, this would adjust animations
                  },
                  subtitle: 'Minimize animations throughout the app',
                ),
              ],
            ),
            SettingsSection(
              title: 'Preview',
              footerText: 'See how your theme will look.',
              children: [
                Container(
                  height: 200,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeNotifier.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.device_phone_portrait,
                        size: 48,
                        color: themeNotifier.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Theme Preview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeNotifier.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is how your theme will look',
                        style: TextStyle(
                          fontSize: 16,
                          color: themeNotifier.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        color: themeNotifier.primaryColor,
                        child: const Text('Sample Button'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoButton.filled(
                child: const Text('Apply Theme Settings'),
                onPressed: _applyThemeSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show secondary color picker for gradient
  void _showSecondaryColorPicker(ThemeNotifier themeNotifier) {
    final iosColors = [
      const Color(0xFF34C759), // Green
      const Color(0xFFFF9500), // Orange
      const Color(0xFFFF2D55), // Red
      const Color(0xFF5856D6), // Purple
      const Color(0xFFAF52DE), // Magenta
      const Color(0xFF5AC8FA), // Teal
      const Color(0xFFFFCC00), // Yellow
      const Color(0xFF8E8E93), // Gray
      const Color(0xFF007AFF), // Blue
    ];

    Color selectedColor = themeNotifier.secondaryColor;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemBackground,
                      context,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              'Choose Secondary Color',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('Done'),
                              onPressed: () {
                                themeNotifier.setSecondaryColor(selectedColor);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Show a preview of the gradient
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeNotifier.customColor,
                                selectedColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Gradient Preview',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'iOS Colors',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              iosColors.map((color) {
                                final isSelected =
                                    selectedColor.value == color.value;
                                return GestureDetector(
                                  onTap:
                                      () =>
                                          setState(() => selectedColor = color),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? CupertinoColors.white
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CupertinoColors.systemGrey
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
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
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Custom Color',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Hue slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text('Hue', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value:
                                    HSVColor.fromColor(selectedColor).hue / 360,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withHue(value * 360).toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                        // Saturation slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Saturation',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value:
                                    HSVColor.fromColor(
                                      selectedColor,
                                    ).saturation,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor
                                            .withSaturation(value)
                                            .toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                        // Value slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Brightness',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value: HSVColor.fromColor(selectedColor).value,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withValue(value).toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }
}

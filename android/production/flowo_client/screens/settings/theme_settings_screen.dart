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
  const ThemeSettingsScreen({super.key});

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

  // Reduce motion for accessibility
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    // Initialize color source based on current theme mode and dynamic colors
    if (themeNotifier.themeMode == AppTheme.custom) {
      if (themeNotifier.useDynamicColors) {
        _selectedColorSource = 'Dynamic';
      } else {
        _selectedColorSource = 'Custom';
      }
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

    // Initialize accessibility settings
    _fontSizeAdjustment = themeNotifier.textSizeAdjustment;
    _highContrastMode = themeNotifier.highContrastMode;
    _reduceMotion = themeNotifier.reduceMotion;
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
      themeNotifier.setUseDynamicColors(true);
      themeNotifier.generateDynamicColorPalette(context);
    }

    // Apply noise level
    themeNotifier.setNoiseLevel(_getNoiseLevelValue(_selectedNoiseLevel));

    // Apply text size adjustment
    themeNotifier.setTextSizeAdjustment(_fontSizeAdjustment);

    // Apply reduce motion
    themeNotifier.setReduceMotion(_reduceMotion);

    // Apply high contrast mode
    themeNotifier.setHighContrastMode(_highContrastMode);

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

  // Show color picker for custom theme with improved iOS-style UI
  void _showColorPicker(ThemeNotifier themeNotifier) {
    // Standard iOS system colors following Apple's Human Interface Guidelines
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
      const Color(0xFF64D2FF), // Light Blue
      const Color(0xFFFF6482), // Light Red
      const Color(0xFFA2845E), // Brown
    ];

    Color selectedColor = themeNotifier.customColor;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: MediaQuery.of(context).size.height * 0.8,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // iOS-style navigation bar
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              'Choose Color',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
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
                      ),

                      // Color preview with haptic feedback
                      GestureDetector(
                        onTap: () {
                          // In a real implementation, this would trigger haptic feedback
                          // HapticFeedback.mediumImpact();
                        },
                        child: Container(
                          height: 80,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: selectedColor.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Preview',
                              style: TextStyle(
                                color: AppColors.appropriateTextColor(
                                  selectedColor,
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // iOS Colors section with improved layout
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'iOS System Colors',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Color grid with improved spacing and feedback
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        childAspectRatio: 1.0,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                  itemCount: iosColors.length,
                                  itemBuilder: (context, index) {
                                    final color = iosColors[index];
                                    final isSelected =
                                        selectedColor.value == color.value;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => selectedColor = color);
                                        // In a real implementation, this would trigger haptic feedback
                                        // HapticFeedback.selectionClick();
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? CupertinoColors.white
                                                    : Colors.transparent,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withOpacity(0.3),
                                              blurRadius: isSelected ? 8 : 4,
                                              spreadRadius: isSelected ? 2 : 0,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child:
                                              isSelected
                                                  ? const Icon(
                                                    CupertinoIcons.checkmark,
                                                    color:
                                                        CupertinoColors.white,
                                                    size: 24,
                                                  )
                                                  : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Custom Color section with improved sliders
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'Custom Color',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Color adjustment sliders with improved styling
                              _buildColorSlider(
                                context,
                                'Hue',
                                HSVColor.fromColor(selectedColor).hue / 360,
                                CupertinoColors.activeBlue,
                                (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withHue(value * 360).toColor();
                                  });
                                },
                              ),

                              _buildColorSlider(
                                context,
                                'Saturation',
                                HSVColor.fromColor(selectedColor).saturation,
                                CupertinoColors.activeOrange,
                                (value) {
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
                              ),

                              _buildColorSlider(
                                context,
                                'Brightness',
                                HSVColor.fromColor(selectedColor).value,
                                CupertinoColors.activeGreen,
                                (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withValue(value).toColor();
                                  });
                                },
                              ),

                              const SizedBox(height: 24),

                              // Accessibility section with improved UI
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'Accessibility Check',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  borderRadius: BorderRadius.circular(16),
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
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This text shows contrast against your selected color.',
                                      style: TextStyle(
                                        color: AppColors.appropriateTextColor(
                                          selectedColor,
                                        ),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _isColorAccessible(selectedColor)
                                                ? CupertinoColors.systemGreen
                                                    .withOpacity(0.2)
                                                : CupertinoColors.systemRed
                                                    .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isColorAccessible(selectedColor)
                                                ? CupertinoIcons
                                                    .check_mark_circled_solid
                                                : CupertinoIcons
                                                    .exclamationmark_triangle_fill,
                                            color:
                                                _isColorAccessible(
                                                      selectedColor,
                                                    )
                                                    ? CupertinoColors
                                                        .systemGreen
                                                    : CupertinoColors.systemRed,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isColorAccessible(selectedColor)
                                                ? 'Good contrast ratio'
                                                : 'Poor contrast ratio',
                                            style: TextStyle(
                                              color:
                                                  _isColorAccessible(
                                                        selectedColor,
                                                      )
                                                      ? CupertinoColors
                                                          .systemGreen
                                                      : CupertinoColors
                                                          .systemRed,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // Helper method to build consistent color sliders
  Widget _buildColorSlider(
    BuildContext context,
    String label,
    double value,
    Color activeColor,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              // Track background with gradient for hue slider
              if (label == 'Hue')
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: [
                        HSVColor.fromAHSV(1, 0, 1, 1).toColor(),
                        HSVColor.fromAHSV(1, 60, 1, 1).toColor(),
                        HSVColor.fromAHSV(1, 120, 1, 1).toColor(),
                        HSVColor.fromAHSV(1, 180, 1, 1).toColor(),
                        HSVColor.fromAHSV(1, 240, 1, 1).toColor(),
                        HSVColor.fromAHSV(1, 300, 1, 1).toColor(),
                        HSVColor.fromAHSV(1, 360, 1, 1).toColor(),
                      ],
                    ),
                  ),
                ),
              CupertinoSlider(
                value: value,
                onChanged: onChanged,
                activeColor: label == 'Hue' ? Colors.transparent : activeColor,
                thumbColor: CupertinoColors.white,
                divisions: 100,
              ),
            ],
          ),
          // Visual indicator for saturation and brightness
          if (label != 'Hue')
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors:
                        label == 'Saturation'
                            ? [
                              HSVColor.fromAHSV(
                                1,
                                HSVColor.fromColor(activeColor).hue,
                                0,
                                1,
                              ).toColor(),
                              HSVColor.fromAHSV(
                                1,
                                HSVColor.fromColor(activeColor).hue,
                                1,
                                1,
                              ).toColor(),
                            ]
                            : [
                              HSVColor.fromAHSV(
                                1,
                                HSVColor.fromColor(activeColor).hue,
                                HSVColor.fromColor(activeColor).saturation,
                                0,
                              ).toColor(),
                              HSVColor.fromAHSV(
                                1,
                                HSVColor.fromColor(activeColor).hue,
                                HSVColor.fromColor(activeColor).saturation,
                                1,
                              ).toColor(),
                            ],
                  ),
                ),
              ),
            ),
        ],
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

  // Show color source picker with visual examples
  void _showColorSourcePicker() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 400,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
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
                        Text(
                          'Color Source',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CupertinoButton(
                          child: const Text('Done'),
                          onPressed: () {
                            // Apply the selected color source immediately
                            if (_selectedColorSource == 'System') {
                              themeNotifier.setThemeMode(AppTheme.system);
                            } else if (_selectedColorSource == 'Custom') {
                              themeNotifier.setThemeMode(AppTheme.custom);
                              themeNotifier.setUseDynamicColors(false);
                            } else if (_selectedColorSource == 'Dynamic') {
                              themeNotifier.setThemeMode(AppTheme.custom);
                              themeNotifier.setUseDynamicColors(true);
                              themeNotifier.generateDynamicColorPalette(
                                context,
                              );
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Description text
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Choose where your app colors come from. System uses iOS standard colors, Custom lets you pick your own, and Dynamic creates a palette based on your selection.',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Visual examples of color sources
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children:
                          _colorSources.map((source) {
                            final isSelected = _selectedColorSource == source;

                            // Get appropriate icon and description for each source
                            IconData icon;
                            String description;
                            Color iconColor;

                            switch (source) {
                              case 'System':
                                icon = CupertinoIcons.device_phone_portrait;
                                description = 'Use standard iOS system colors';
                                iconColor = CupertinoColors.systemBlue;
                                break;
                              case 'Custom':
                                icon = CupertinoIcons.color_filter;
                                description = 'Choose your own custom colors';
                                iconColor = themeNotifier.customColor;
                                break;
                              case 'Dynamic':
                                icon = CupertinoIcons.wand_stars;
                                description =
                                    'Generate a palette from your selection';
                                iconColor = CupertinoColors.systemPurple;
                                break;
                              default:
                                icon = CupertinoIcons.circle;
                                description = '';
                                iconColor = CupertinoColors.systemGrey;
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColorSource = source;
                                });

                                // Apply the change immediately for preview
                                if (source == 'System') {
                                  themeNotifier.setThemeMode(AppTheme.system);
                                } else if (source == 'Custom') {
                                  themeNotifier.setThemeMode(AppTheme.custom);
                                  themeNotifier.setUseDynamicColors(false);
                                } else if (source == 'Dynamic') {
                                  themeNotifier.setThemeMode(AppTheme.custom);
                                  themeNotifier.setUseDynamicColors(true);
                                  themeNotifier.generateDynamicColorPalette(
                                    context,
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? themeNotifier.primaryColor
                                              .withOpacity(0.1)
                                          : CupertinoColors.systemGrey6
                                              .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? themeNotifier.primaryColor
                                            : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        icon,
                                        color: iconColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            source,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color:
                                                  isSelected
                                                      ? themeNotifier
                                                          .primaryColor
                                                      : CupertinoTheme.of(
                                                            context,
                                                          )
                                                          .textTheme
                                                          .textStyle
                                                          .color,
                                            ),
                                          ),
                                          Text(
                                            description,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: CupertinoColors
                                                  .secondaryLabel
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        CupertinoIcons.checkmark_circle_fill,
                                        color: themeNotifier.primaryColor,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Standard picker as fallback
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: _colorSources.indexOf(
                          _selectedColorSource,
                        ),
                      ),
                      itemExtent: 32.0,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedColorSource = _colorSources[index];
                        });

                        // Apply the change immediately for preview
                        final source = _colorSources[index];
                        if (source == 'System') {
                          themeNotifier.setThemeMode(AppTheme.system);
                        } else if (source == 'Custom') {
                          themeNotifier.setThemeMode(AppTheme.custom);
                          themeNotifier.setUseDynamicColors(false);
                        } else if (source == 'Dynamic') {
                          themeNotifier.setThemeMode(AppTheme.custom);
                          themeNotifier.setUseDynamicColors(true);
                          themeNotifier.generateDynamicColorPalette(context);
                        }
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
          ),
    );
  }

  // Show noise level picker with visual examples
  void _showNoiseLevelPicker() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 400,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
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
                        Text(
                          'Noise Effect',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
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

                  // Description text
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Noise adds a subtle grain texture to your theme colors, similar to film grain or paper texture.',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Visual examples of noise levels
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children:
                          _noiseLevels.map((level) {
                            final isSelected = _selectedNoiseLevel == level;
                            final noiseValue = _getNoiseLevelValue(level);

                            // Apply the noise effect to the primary color for preview
                            final Color previewColor =
                                noiseValue > 0
                                    ? themeNotifier.applyNoiseToColor(
                                      themeNotifier.customColor,
                                    )
                                    : themeNotifier.customColor;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedNoiseLevel = level;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      height: 60,
                                      margin: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: previewColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? themeNotifier.primaryColor
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: themeNotifier
                                                        .primaryColor
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      level,
                                      style: TextStyle(
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color:
                                            isSelected
                                                ? themeNotifier.primaryColor
                                                : CupertinoTheme.of(
                                                  context,
                                                ).textTheme.textStyle.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Divider
                  Divider(
                    height: 1,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),

                  // Standard picker as fallback
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: _noiseLevels.indexOf(_selectedNoiseLevel),
                      ),
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
                    // Apply the change immediately for preview
                    final themeNotifier = Provider.of<ThemeNotifier>(
                      context,
                      listen: false,
                    );
                    themeNotifier.setTextSizeAdjustment(value);
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
                    // Apply the change immediately for preview
                    final themeNotifier = Provider.of<ThemeNotifier>(
                      context,
                      listen: false,
                    );
                    themeNotifier.setHighContrastMode(value);
                  },
                  subtitle: 'Increase contrast for better readability',
                ),
                SettingsToggleItem(
                  label: 'Reduce Motion',
                  value: _reduceMotion,
                  onChanged: (value) {
                    setState(() {
                      _reduceMotion = value;
                    });
                    // Apply the change immediately for preview
                    final themeNotifier = Provider.of<ThemeNotifier>(
                      context,
                      listen: false,
                    );
                    themeNotifier.setReduceMotion(value);
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
                  height: 300,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeNotifier.backgroundColor,
                    gradient:
                        themeNotifier.useGradient
                            ? LinearGradient(
                              colors: [
                                themeNotifier.customColor,
                                themeNotifier.secondaryColor,
                              ],
                              begin: themeNotifier.gradientStartAlignment,
                              end: themeNotifier.gradientEndAlignment,
                            )
                            : null,
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Mock navigation bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: themeNotifier.backgroundColor.withOpacity(0.9),
                          gradient:
                              themeNotifier.useGradient
                                  ? LinearGradient(
                                    colors: [
                                      themeNotifier.customColor.withOpacity(
                                        0.9,
                                      ),
                                      themeNotifier.secondaryColor.withOpacity(
                                        0.9,
                                      ),
                                    ],
                                    begin: themeNotifier.gradientStartAlignment,
                                    end: themeNotifier.gradientEndAlignment,
                                  )
                                  : null,
                          border: Border(
                            bottom: BorderSide(
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Theme Preview',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    themeNotifier.highContrastMode
                                        ? FontWeight.w700
                                        : FontWeight.bold,
                                color: themeNotifier.textColor,
                              ),
                            ),
                            Icon(
                              CupertinoIcons.ellipsis_circle,
                              color: themeNotifier.primaryColor,
                            ),
                          ],
                        ),
                      ),

                      // Content area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // List item
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors
                                        .secondarySystemBackground
                                        .resolveFrom(context),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: themeNotifier.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          CupertinoIcons.check_mark,
                                          color: CupertinoColors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Task Item',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: themeNotifier.textColor,
                                              ),
                                            ),
                                            Text(
                                              'This is a sample task with your theme',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: CupertinoColors
                                                    .secondaryLabel
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Buttons row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      color: themeNotifier.primaryColor,
                                      child: const Text('Primary'),
                                      onPressed: () {},
                                    ),
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Secondary',
                                        style: TextStyle(
                                          color: themeNotifier.primaryColor,
                                        ),
                                      ),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Toggle
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Dark Mode',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: themeNotifier.textColor,
                                        fontWeight:
                                            themeNotifier.highContrastMode
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    CupertinoSwitch(
                                      value:
                                          themeNotifier.brightness ==
                                          Brightness.dark,
                                      activeTrackColor: themeNotifier.primaryColor,
                                      onChanged: (_) {},
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Text size adjustment demonstration
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey6
                                        .resolveFrom(context),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Text Size Adjustment',
                                        style: TextStyle(
                                          fontSize:
                                              16 *
                                              (1.0 +
                                                  themeNotifier
                                                      .textSizeAdjustment),
                                          fontWeight:
                                              themeNotifier.highContrastMode
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                          color: themeNotifier.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'This text demonstrates the current text size setting.',
                                        style: TextStyle(
                                          fontSize:
                                              14 *
                                              (1.0 +
                                                  themeNotifier
                                                      .textSizeAdjustment),
                                          color: themeNotifier.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Accessibility features: ${themeNotifier.highContrastMode ? "High Contrast, " : ""}${themeNotifier.reduceMotion ? "Reduced Motion" : ""}',
                                        style: TextStyle(
                                          fontSize:
                                              12 *
                                              (1.0 +
                                                  themeNotifier
                                                      .textSizeAdjustment),
                                          color: CupertinoColors.secondaryLabel
                                              .resolveFrom(context),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SafeArea(
                child: Column(
                  children: [
                    CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      borderRadius: BorderRadius.circular(10),
                      onPressed: _applyThemeSettings,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Apply Theme Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Changes will be applied to all screens',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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

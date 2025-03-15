import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay, Divider;

/// A collection of reusable widgets for the settings screen
/// following iOS design guidelines and best practices for Cupertino UI

/// Represents a section in the settings screen with a header and children
/// Follows iOS design guidelines for grouped tables
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool showDivider;
  final String? footerText;
  final Widget? customFooter;
  final bool useRoundedCorners;
  final double cornerRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const SettingsSection({
    Key? key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.only(top: 16.0, bottom: 8.0),
    this.showDivider = true,
    this.footerText,
    this.customFooter,
    this.useRoundedCorners = true,
    this.cornerRadius = 10.0,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ??
        CupertinoDynamicColor.resolve(
            CupertinoColors.systemBackground, context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: padding,
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGrey,
                letterSpacing: 0.1,
              ),
            ),
          ),

          // Section content with rounded corners if enabled
          ClipRRect(
            borderRadius: useRoundedCorners
                ? BorderRadius.circular(cornerRadius)
                : BorderRadius.zero,
            child: Container(
              decoration: BoxDecoration(
                color: effectiveBackgroundColor,
                boxShadow: useRoundedCorners
                    ? [
                        BoxShadow(
                          color: CupertinoColors.systemGrey5.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: children,
              ),
            ),
          ),

          // Optional footer text or custom footer
          if (footerText != null || customFooter != null)
            Padding(
              padding: const EdgeInsets.only(
                  top: 8.0, left: 16.0, right: 16.0, bottom: 16.0),
              child: customFooter ??
                  Text(
                    footerText!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                      height: 1.3,
                    ),
                  ),
            ),
        ],
      ),
    );
  }
}

/// A standard settings item with a label and a value
/// Enhanced with animations, accessibility features, and better styling
class SettingsItem extends StatefulWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDisclosure;
  final Widget? leading;
  final EdgeInsetsGeometry padding;
  final bool showDivider;
  final String? subtitle;
  final bool enabled;
  final Color? backgroundColor;
  final Color? activeBackgroundColor;
  final TextStyle? labelStyle;
  final TextStyle? subtitleStyle;
  final String? semanticsLabel;
  final bool useAnimatedTap;

  const SettingsItem({
    Key? key,
    required this.label,
    this.trailing,
    this.onTap,
    this.showDisclosure = true,
    this.leading,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.showDivider = true,
    this.subtitle,
    this.enabled = true,
    this.backgroundColor,
    this.activeBackgroundColor,
    this.labelStyle,
    this.subtitleStyle,
    this.semanticsLabel,
    this.useAnimatedTap = true,
  }) : super(key: key);

  @override
  State<SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem>
    with SingleTickerProviderStateMixin {
  bool _isTapped = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enabled && widget.useAnimatedTap) {
      setState(() => _isTapped = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.enabled && widget.useAnimatedTap) {
      setState(() => _isTapped = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && widget.enabled && widget.useAnimatedTap) {
      setState(() => _isTapped = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = widget.backgroundColor ??
        CupertinoDynamicColor.resolve(
            CupertinoColors.systemBackground, context);

    final effectiveActiveBackgroundColor = widget.activeBackgroundColor ??
        CupertinoDynamicColor.resolve(CupertinoColors.systemGrey6, context);

    final effectiveLabelStyle =
        widget.labelStyle ?? const TextStyle(fontSize: 16);

    final effectiveSubtitleStyle = widget.subtitleStyle ??
        const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey);

    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      button: widget.onTap != null,
      enabled: widget.enabled,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.useAnimatedTap ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: _isTapped
                  ? effectiveActiveBackgroundColor
                  : effectiveBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: widget.showDivider
                      ? CupertinoColors.systemGrey5
                      : CupertinoColors.systemBackground,
                  width: 0.5,
                ),
              ),
            ),
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: Padding(
                padding: widget.padding,
                child: Row(
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: effectiveLabelStyle,
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle!,
                              style: effectiveSubtitleStyle,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!,
                    if (widget.showDisclosure &&
                        widget.onTap != null &&
                        widget.enabled)
                      const Icon(
                        CupertinoIcons.chevron_right,
                        color: CupertinoColors.systemGrey2,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A settings item with a toggle switch
/// Enhanced with animations, accessibility features, and better styling
class SettingsToggleItem extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;
  final bool showDivider;
  final String? subtitle;
  final bool enabled;
  final Color? activeColor;
  final Color? trackColor;
  final TextStyle? labelStyle;
  final TextStyle? subtitleStyle;
  final String? semanticsLabel;
  final EdgeInsetsGeometry padding;

  const SettingsToggleItem({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.leading,
    this.showDivider = true,
    this.subtitle,
    this.enabled = true,
    this.activeColor,
    this.trackColor,
    this.labelStyle,
    this.subtitleStyle,
    this.semanticsLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  }) : super(key: key);

  @override
  State<SettingsToggleItem> createState() => _SettingsToggleItemState();
}

class _SettingsToggleItemState extends State<SettingsToggleItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _toggleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.value ? 1.0 : 0.0,
    );
    _toggleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(SettingsToggleItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enabled) {
      widget.onChanged(!widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor =
        widget.activeColor ?? CupertinoColors.activeBlue;

    return Semantics(
      toggled: widget.value,
      label: widget.semanticsLabel ??
          '${widget.label}, ${widget.value ? 'enabled' : 'disabled'}',
      child: SettingsItem(
        label: widget.label,
        subtitle: widget.subtitle,
        leading: widget.leading,
        showDisclosure: false,
        showDivider: widget.showDivider,
        enabled: widget.enabled,
        labelStyle: widget.labelStyle,
        subtitleStyle: widget.subtitleStyle,
        padding: widget.padding,
        trailing: CupertinoSwitch(
          value: widget.value,
          onChanged: widget.enabled ? widget.onChanged : null,
          activeColor: effectiveActiveColor,
          trackColor: widget.trackColor,
        ),
        onTap: _handleTap,
      ),
    );
  }
}

/// A settings item with a segmented control
/// Enhanced with animations, accessibility features, and better styling
class SettingsSegmentedItem extends StatefulWidget {
  final String label;
  final Map<String, Widget> children;
  final String groupValue;
  final ValueChanged<String> onValueChanged;
  final bool showDivider;
  final String? subtitle;
  final bool enabled;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? borderColor;
  final TextStyle? labelStyle;
  final TextStyle? subtitleStyle;
  final String? semanticsLabel;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry segmentPadding;

  const SettingsSegmentedItem({
    Key? key,
    required this.label,
    required this.children,
    required this.groupValue,
    required this.onValueChanged,
    this.showDivider = true,
    this.subtitle,
    this.enabled = true,
    this.backgroundColor,
    this.selectedColor,
    this.borderColor,
    this.labelStyle,
    this.subtitleStyle,
    this.semanticsLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.segmentPadding =
        const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
  }) : super(key: key);

  @override
  State<SettingsSegmentedItem> createState() => _SettingsSegmentedItemState();
}

class _SettingsSegmentedItemState extends State<SettingsSegmentedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.groupValue;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.value = 1.0; // Start fully visible
  }

  @override
  void didUpdateWidget(SettingsSegmentedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupValue != widget.groupValue) {
      _previousValue = oldWidget.groupValue;
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor =
        widget.selectedColor ?? CupertinoColors.activeBlue;
    final effectiveBorderColor =
        widget.borderColor ?? CupertinoColors.systemGrey4;

    // Create a map of children with proper semantics
    final Map<String, Widget> wrappedChildren = {};
    widget.children.forEach((key, child) {
      wrappedChildren[key] = Semantics(
        label: '$key ${key == widget.groupValue ? ', selected' : ''}',
        selected: key == widget.groupValue,
        button: true,
        enabled: widget.enabled,
        child: child,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with label and optional subtitle
        SettingsItem(
          label: widget.label,
          subtitle: widget.subtitle,
          showDisclosure: false,
          showDivider: false,
          enabled: widget.enabled,
          labelStyle: widget.labelStyle,
          subtitleStyle: widget.subtitleStyle,
          padding: widget.padding,
          onTap: null,
        ),

        // Segmented control with animation
        Padding(
          padding: widget.segmentPadding,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.5,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: CupertinoSegmentedControl<String>(
                groupValue: widget.groupValue,
                children: wrappedChildren,
                onValueChanged: widget.enabled ? widget.onValueChanged : (_) {},
              ),
            ),
          ),
        ),

        // Optional divider
        if (widget.showDivider)
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: CupertinoColors.systemGrey5,
          ),
      ],
    );
  }
}

/// A settings item with a slider
/// Enhanced with animations, accessibility features, and better styling
class SettingsSliderItem extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final bool showDivider;
  final String? valueLabel;
  final String? subtitle;
  final bool enabled;
  final Color? activeColor;
  final Color? thumbColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final TextStyle? subtitleStyle;
  final String? semanticsLabel;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry sliderPadding;
  final Widget Function(double)? valueBuilder;

  const SettingsSliderItem({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.showDivider = true,
    this.valueLabel,
    this.subtitle,
    this.enabled = true,
    this.activeColor,
    this.thumbColor,
    this.labelStyle,
    this.valueStyle,
    this.subtitleStyle,
    this.semanticsLabel,
    this.padding = const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
    this.sliderPadding =
        const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
    this.valueBuilder,
  }) : super(key: key);

  @override
  State<SettingsSliderItem> createState() => _SettingsSliderItemState();
}

class _SettingsSliderItemState extends State<SettingsSliderItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _valueAnimation;
  double _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _valueAnimation =
        Tween<double>(begin: widget.value, end: widget.value).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.addListener(() {
      setState(() {
        _displayValue = _valueAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(SettingsSliderItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _valueAnimation = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatValue() {
    if (widget.valueLabel != null) return widget.valueLabel!;

    // If divisions are provided, show integer values
    if (widget.divisions != null) {
      return _displayValue.round().toString();
    }

    // Otherwise, show with one decimal place
    return _displayValue.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor =
        widget.activeColor ?? CupertinoColors.activeBlue;
    final effectiveLabelStyle =
        widget.labelStyle ?? const TextStyle(fontSize: 16);
    final effectiveValueStyle = widget.valueStyle ??
        const TextStyle(fontSize: 16, color: CupertinoColors.systemGrey);
    final effectiveSubtitleStyle = widget.subtitleStyle ??
        const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey);

    return Semantics(
      slider: true,
      value: _formatValue(),
      label: widget.semanticsLabel ?? widget.label,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label, value, and optional subtitle
          Padding(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.label,
                      style: effectiveLabelStyle,
                    ),
                    widget.valueBuilder != null
                        ? widget.valueBuilder!(_displayValue)
                        : Text(
                            _formatValue(),
                            style: effectiveValueStyle,
                          ),
                  ],
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: effectiveSubtitleStyle,
                  ),
                ],
              ],
            ),
          ),

          // Slider with animation
          Padding(
            padding: widget.sliderPadding,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: CupertinoSlider(
                value: widget.value,
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                onChanged: widget.enabled ? widget.onChanged : null,
                activeColor: effectiveActiveColor,
                thumbColor: widget.thumbColor ?? CupertinoColors.white,
              ),
            ),
          ),

          // Optional divider
          if (widget.showDivider)
            const Divider(
              height: 0.5,
              thickness: 0.5,
              color: CupertinoColors.systemGrey5,
            ),
        ],
      ),
    );
  }
}

/// A button styled according to iOS guidelines
/// Enhanced with animations, accessibility features, and better styling
class SettingsButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isPrimary;
  final bool isDestructive;
  final IconData? icon;
  final bool enabled;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double minSize;
  final TextStyle? textStyle;
  final double? iconSize;
  final String? semanticsLabel;
  final bool useAnimatedPress;
  final Widget? trailing;
  final MainAxisAlignment alignment;
  final MainAxisSize mainAxisSize;

  const SettingsButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.color,
    this.isPrimary = false,
    this.isDestructive = false,
    this.icon,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.borderRadius,
    this.minSize = 44.0,
    this.textStyle,
    this.iconSize = 18.0,
    this.semanticsLabel,
    this.useAnimatedPress = true,
    this.trailing,
    this.alignment = MainAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
  }) : super(key: key);

  @override
  State<SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<SettingsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.useAnimatedPress) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && widget.useAnimatedPress) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && widget.useAnimatedPress) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ??
        (widget.isDestructive
            ? CupertinoColors.systemRed
            : widget.isPrimary
                ? CupertinoColors.systemBlue
                : CupertinoColors.systemGrey);

    final effectiveTextStyle = widget.textStyle ??
        TextStyle(
          color: widget.isPrimary ? CupertinoColors.white : buttonColor,
          fontSize: 16,
          fontWeight: widget.isPrimary ? FontWeight.w500 : FontWeight.normal,
        );

    final effectiveBorderRadius = widget.borderRadius ??
        BorderRadius.circular(widget.isPrimary ? 8.0 : 8.0);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel ?? widget.label,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.useAnimatedPress ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.5,
            child: CupertinoButton(
              padding: widget.padding,
              color: widget.isPrimary ? buttonColor : null,
              borderRadius: effectiveBorderRadius,
              minSize: widget.minSize,
              onPressed: widget.enabled ? widget.onPressed : null,
              child: Row(
                mainAxisSize: widget.mainAxisSize,
                mainAxisAlignment: widget.alignment,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.isPrimary
                          ? CupertinoColors.white
                          : buttonColor,
                      size: widget.iconSize,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: effectiveTextStyle,
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A time picker item for selecting time ranges
/// Enhanced with animations, accessibility features, and better styling
class SettingsTimePickerItem extends StatefulWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final bool showDivider;
  final String? subtitle;
  final bool enabled;
  final Color? textColor;
  final TextStyle? labelStyle;
  final TextStyle? timeStyle;
  final TextStyle? subtitleStyle;
  final String? semanticsLabel;
  final EdgeInsetsGeometry padding;
  final Widget? leading;
  final String? timeFormat;
  final bool use24HourFormat;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final int minuteInterval;

  const SettingsTimePickerItem({
    Key? key,
    required this.label,
    required this.time,
    required this.onTimeSelected,
    this.showDivider = true,
    this.subtitle,
    this.enabled = true,
    this.textColor,
    this.labelStyle,
    this.timeStyle,
    this.subtitleStyle,
    this.semanticsLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.leading,
    this.timeFormat,
    this.use24HourFormat = true,
    this.minimumDate,
    this.maximumDate,
    this.minuteInterval = 1,
  }) : super(key: key);

  @override
  State<SettingsTimePickerItem> createState() => _SettingsTimePickerItemState();
}

class _SettingsTimePickerItemState extends State<SettingsTimePickerItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    if (widget.timeFormat != null) {
      // Replace HH with hour and mm with minute in the format string
      String formatted = widget.timeFormat!;
      final hour = widget.use24HourFormat 
          ? time.hour.toString().padLeft(2, '0')
          : (time.hour > 12 ? (time.hour - 12) : (time.hour == 0 ? 12 : time.hour)).toString();
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour < 12 ? 'AM' : 'PM';

      formatted = formatted.replaceAll('HH', hour);
      formatted = formatted.replaceAll('mm', minute);
      formatted = formatted.replaceAll('a', period);

      return formatted;
    }

    final hour = widget.use24HourFormat 
        ? time.hour.toString().padLeft(2, '0')
        : (time.hour > 12 ? (time.hour - 12) : (time.hour == 0 ? 12 : time.hour)).toString();
    final minute = time.minute.toString().padLeft(2, '0');
    final period = !widget.use24HourFormat ? (time.hour < 12 ? ' AM' : ' PM') : '';

    return '$hour:$minute$period';
  }

  void _showTimePicker(BuildContext context) {
    if (!widget.enabled) return;

    setState(() => _isSelecting = true);
    _animationController.forward();

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: CupertinoDynamicColor.resolve(CupertinoColors.systemBackground, context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isSelecting = false);
                    _animationController.reverse();
                  },
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isSelecting = false);
                    _animationController.reverse();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  widget.time.hour,
                  widget.time.minute,
                ),
                minimumDate: widget.minimumDate,
                maximumDate: widget.maximumDate,
                minuteInterval: widget.minuteInterval,
                use24hFormat: widget.use24HourFormat,
                onDateTimeChanged: (dateTime) => widget.onTimeSelected(
                  TimeOfDay(
                    hour: dateTime.hour,
                    minute: dateTime.minute,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (_isSelecting) {
        setState(() => _isSelecting = false);
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTimeStyle = widget.timeStyle ?? 
        TextStyle(
          color: widget.textColor ?? CupertinoColors.systemGrey,
          fontSize: 16,
        );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel ?? '${widget.label}, current time: ${_formatTimeOfDay(widget.time)}',
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: SettingsItem(
          label: widget.label,
          subtitle: widget.subtitle,
          leading: widget.leading,
          enabled: widget.enabled,
          labelStyle: widget.labelStyle,
          subtitleStyle: widget.subtitleStyle,
          padding: widget.padding,
          trailing: Text(
            _formatTimeOfDay(widget.time),
            style: effectiveTimeStyle,
          ),
          showDivider: widget.showDivider,
          onTap: () => _showTimePicker(context),
          useAnimatedTap: false, // We're handling animation ourselves
        ),
      ),
    );
  }
}

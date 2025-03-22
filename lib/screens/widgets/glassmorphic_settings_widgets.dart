import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay, Divider;
import 'package:provider/provider.dart';

import '../../design/glassmorphic_container.dart';
import '../../theme_notifier.dart';

/// A glassmorphic version of the SettingsSection widget
class GlassmorphicSettingsSection extends StatelessWidget {
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

  const GlassmorphicSettingsSection({
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    final effectiveBackgroundColor =
        backgroundColor ?? themeNotifier.backgroundColor;

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

          // Section content with glassmorphic effect
          ClipRRect(
            borderRadius:
                useRoundedCorners
                    ? BorderRadius.circular(cornerRadius)
                    : BorderRadius.zero,
            child: GlassmorphicContainer(
              borderRadius:
                  useRoundedCorners
                      ? BorderRadius.circular(cornerRadius)
                      : null,
              blur: glassmorphicTheme.defaultBlur,
              opacity: glassmorphicTheme.defaultOpacity,
              borderWidth: glassmorphicTheme.defaultBorderWidth,
              borderColor: glassmorphicTheme.borderColor,
              backgroundColor: effectiveBackgroundColor.withOpacity(0.1),
              child: Column(children: children),
            ),
          ),

          // Optional footer text or custom footer
          if (footerText != null || customFooter != null)
            Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child:
                  customFooter ??
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

/// A glassmorphic version of the SettingsItem widget
class GlassmorphicSettingsItem extends StatefulWidget {
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

  const GlassmorphicSettingsItem({
    super.key,
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
  });

  @override
  State<GlassmorphicSettingsItem> createState() =>
      _GlassmorphicSettingsItemState();
}

class _GlassmorphicSettingsItemState extends State<GlassmorphicSettingsItem>
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    final effectiveBackgroundColor =
        widget.backgroundColor ??
        themeNotifier.backgroundColor.withOpacity(0.1);

    final effectiveActiveBackgroundColor =
        widget.activeBackgroundColor ??
        themeNotifier.primaryColor.withOpacity(0.2);

    final effectiveLabelStyle =
        widget.labelStyle ?? const TextStyle(fontSize: 16);

    final effectiveSubtitleStyle =
        widget.subtitleStyle ??
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
              color:
                  _isTapped
                      ? effectiveActiveBackgroundColor
                      : const Color(0x00000000),
              border: Border(
                bottom: BorderSide(
                  color:
                      widget.showDivider
                          ? glassmorphicTheme.borderColor.withOpacity(0.3)
                          : const Color(0x00000000),
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
                          Text(widget.label, style: effectiveLabelStyle),
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

/// A glassmorphic version of the SettingsSegmentedItem widget
class GlassmorphicSettingsSegmentedItem extends StatefulWidget {
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

  const GlassmorphicSettingsSegmentedItem({
    super.key,
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
    this.segmentPadding = const EdgeInsets.only(
      left: 16.0,
      right: 16.0,
      bottom: 16.0,
    ),
  });

  @override
  State<GlassmorphicSettingsSegmentedItem> createState() =>
      _GlassmorphicSettingsSegmentedItemState();
}

class _GlassmorphicSettingsSegmentedItemState
    extends State<GlassmorphicSettingsSegmentedItem>
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.value = 1.0; // Start fully visible
  }

  @override
  void didUpdateWidget(GlassmorphicSettingsSegmentedItem oldWidget) {
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    final effectiveSelectedColor =
        widget.selectedColor ?? themeNotifier.primaryColor;
    final effectiveBorderColor =
        widget.borderColor ?? glassmorphicTheme.borderColor;

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
        GlassmorphicSettingsItem(
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

        // Segmented control with glassmorphic effect and animation
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: glassmorphicTheme.defaultBlur,
                    sigmaY: glassmorphicTheme.defaultBlur,
                  ),
                  child: CupertinoSegmentedControl<String>(
                    groupValue: widget.groupValue,
                    children: wrappedChildren,
                    onValueChanged:
                        widget.enabled ? widget.onValueChanged : (_) {},
                    borderColor: effectiveBorderColor,
                    selectedColor: effectiveSelectedColor,
                    unselectedColor: themeNotifier.backgroundColor.withOpacity(
                      0.2,
                    ),
                    pressedColor: effectiveSelectedColor.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Optional divider
        if (widget.showDivider)
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: glassmorphicTheme.borderColor.withOpacity(0.3),
          ),
      ],
    );
  }
}

/// A glassmorphic version of the SettingsToggleItem widget
class GlassmorphicSettingsToggleItem extends StatefulWidget {
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

  const GlassmorphicSettingsToggleItem({
    super.key,
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
  });

  @override
  State<GlassmorphicSettingsToggleItem> createState() =>
      _GlassmorphicSettingsToggleItemState();
}

class _GlassmorphicSettingsToggleItemState
    extends State<GlassmorphicSettingsToggleItem>
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
  void didUpdateWidget(GlassmorphicSettingsToggleItem oldWidget) {
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    final effectiveActiveColor =
        widget.activeColor ?? themeNotifier.primaryColor;

    return Semantics(
      toggled: widget.value,
      label:
          widget.semanticsLabel ??
          '${widget.label}, ${widget.value ? 'enabled' : 'disabled'}',
      child: GlassmorphicSettingsItem(
        label: widget.label,
        subtitle: widget.subtitle,
        leading: widget.leading,
        showDisclosure: false,
        showDivider: widget.showDivider,
        enabled: widget.enabled,
        labelStyle: widget.labelStyle,
        subtitleStyle: widget.subtitleStyle,
        padding: widget.padding,
        trailing: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: glassmorphicTheme.defaultBlur / 2,
              sigmaY: glassmorphicTheme.defaultBlur / 2,
            ),
            child: CupertinoSwitch(
              value: widget.value,
              onChanged: widget.enabled ? widget.onChanged : null,
              activeColor: effectiveActiveColor,
              trackColor: widget.trackColor,
            ),
          ),
        ),
        onTap: _handleTap,
      ),
    );
  }
}

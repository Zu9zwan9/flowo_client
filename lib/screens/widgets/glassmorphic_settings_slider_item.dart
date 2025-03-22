import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:provider/provider.dart';

import '../../theme_notifier.dart';
import 'glassmorphic_settings_widgets.dart';

/// A glassmorphic version of the SettingsSliderItem widget
class GlassmorphicSettingsSliderItem extends StatefulWidget {
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

  const GlassmorphicSettingsSliderItem({
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
    this.sliderPadding = const EdgeInsets.only(
      left: 12.0,
      right: 12.0,
      bottom: 12.0,
    ),
    this.valueBuilder,
  }) : super(key: key);

  @override
  State<GlassmorphicSettingsSliderItem> createState() =>
      _GlassmorphicSettingsSliderItemState();
}

class _GlassmorphicSettingsSliderItemState
    extends State<GlassmorphicSettingsSliderItem>
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
    _valueAnimation = Tween<double>(
      begin: widget.value,
      end: widget.value,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.addListener(() {
      setState(() {
        _displayValue = _valueAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(GlassmorphicSettingsSliderItem oldWidget) {
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    final effectiveActiveColor =
        widget.activeColor ?? themeNotifier.primaryColor;
    final effectiveLabelStyle =
        widget.labelStyle ?? const TextStyle(fontSize: 16);
    final effectiveValueStyle =
        widget.valueStyle ??
        const TextStyle(fontSize: 16, color: CupertinoColors.systemGrey);
    final effectiveSubtitleStyle =
        widget.subtitleStyle ??
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
                    Text(widget.label, style: effectiveLabelStyle),
                    widget.valueBuilder != null
                        ? widget.valueBuilder!(_displayValue)
                        : Text(_formatValue(), style: effectiveValueStyle),
                  ],
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(widget.subtitle!, style: effectiveSubtitleStyle),
                ],
              ],
            ),
          ),

          // Slider with glassmorphic effect and animation
          Padding(
            padding: widget.sliderPadding,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: glassmorphicTheme.defaultBlur / 2,
                    sigmaY: glassmorphicTheme.defaultBlur / 2,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeNotifier.backgroundColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: glassmorphicTheme.borderColor.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
      ),
    );
  }
}

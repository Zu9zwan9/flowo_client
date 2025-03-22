import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:provider/provider.dart';

import '../../theme_notifier.dart';
import 'glassmorphic_settings_widgets.dart';

/// A glassmorphic version of the SettingsTimePickerItem widget
class GlassmorphicSettingsTimePickerItem extends StatefulWidget {
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

  const GlassmorphicSettingsTimePickerItem({
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
  State<GlassmorphicSettingsTimePickerItem> createState() =>
      _GlassmorphicSettingsTimePickerItemState();
}

class _GlassmorphicSettingsTimePickerItemState
    extends State<GlassmorphicSettingsTimePickerItem>
    with SingleTickerProviderStateMixin {
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
      final hour =
          widget.use24HourFormat
              ? time.hour.toString().padLeft(2, '0')
              : (time.hour > 12
                      ? (time.hour - 12)
                      : (time.hour == 0 ? 12 : time.hour))
                  .toString();
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour < 12 ? 'AM' : 'PM';

      formatted = formatted.replaceAll('HH', hour);
      formatted = formatted.replaceAll('mm', minute);
      formatted = formatted.replaceAll('a', period);

      return formatted;
    }

    final hour =
        widget.use24HourFormat
            ? time.hour.toString().padLeft(2, '0')
            : (time.hour > 12
                    ? (time.hour - 12)
                    : (time.hour == 0 ? 12 : time.hour))
                .toString();
    final minute = time.minute.toString().padLeft(2, '0');
    final period =
        !widget.use24HourFormat ? (time.hour < 12 ? ' AM' : ' PM') : '';

    return '$hour:$minute$period';
  }

  void _showTimePicker(BuildContext context) {
    if (!widget.enabled) return;

    setState(() => _isSelecting = true);
    _animationController.forward();

    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: glassmorphicTheme.defaultBlur,
                sigmaY: glassmorphicTheme.defaultBlur,
              ),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: themeNotifier.backgroundColor.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: glassmorphicTheme.borderColor,
                    width: glassmorphicTheme.defaultBorderWidth,
                  ),
                ),
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
                        onDateTimeChanged:
                            (dateTime) => widget.onTimeSelected(
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    final effectiveTimeStyle =
        widget.timeStyle ??
        TextStyle(
          color: widget.textColor ?? themeNotifier.primaryColor,
          fontSize: 16,
        );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label:
          widget.semanticsLabel ??
          '${widget.label}, current time: ${_formatTimeOfDay(widget.time)}',
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: GlassmorphicSettingsItem(
          label: widget.label,
          subtitle: widget.subtitle,
          leading: widget.leading,
          enabled: widget.enabled,
          labelStyle: widget.labelStyle,
          subtitleStyle: widget.subtitleStyle,
          padding: widget.padding,
          trailing: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: glassmorphicTheme.defaultBlur / 2,
                sigmaY: glassmorphicTheme.defaultBlur / 2,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeNotifier.backgroundColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: glassmorphicTheme.borderColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _formatTimeOfDay(widget.time),
                  style: effectiveTimeStyle,
                ),
              ),
            ),
          ),
          showDivider: widget.showDivider,
          onTap: () => _showTimePicker(context),
          useAnimatedTap: false, // We're handling animation ourselves
        ),
      ),
    );
  }
}

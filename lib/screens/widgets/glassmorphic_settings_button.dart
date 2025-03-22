import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../design/glassmorphic_container.dart';
import '../../theme_notifier.dart';

/// A glassmorphic version of the SettingsButton widget
class GlassmorphicSettingsButton extends StatefulWidget {
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

  const GlassmorphicSettingsButton({
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
  State<GlassmorphicSettingsButton> createState() =>
      _GlassmorphicSettingsButtonState();
}

class _GlassmorphicSettingsButtonState extends State<GlassmorphicSettingsButton>
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    final buttonColor =
        widget.color ??
        (widget.isDestructive
            ? CupertinoColors.systemRed
            : widget.isPrimary
            ? themeNotifier.primaryColor
            : CupertinoColors.systemGrey);

    final effectiveTextStyle =
        widget.textStyle ??
        TextStyle(
          color: widget.isPrimary ? CupertinoColors.white : buttonColor,
          fontSize: 16,
          fontWeight: widget.isPrimary ? FontWeight.w500 : FontWeight.normal,
        );

    final effectiveBorderRadius =
        widget.borderRadius ??
        BorderRadius.circular(widget.isPrimary ? 12.0 : 8.0);

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
          onTap: widget.enabled ? widget.onPressed : null,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.5,
            child: GlassmorphicContainer(
              padding: widget.padding,
              borderRadius: effectiveBorderRadius,
              blur: glassmorphicTheme.defaultBlur,
              opacity: widget.isPrimary ? 0.3 : 0.2,
              borderWidth: glassmorphicTheme.defaultBorderWidth,
              borderColor: buttonColor.withOpacity(0.3),
              backgroundColor:
                  widget.isPrimary
                      ? buttonColor.withOpacity(0.3)
                      : const Color(0x00000000),
              child: Container(
                constraints: BoxConstraints(minHeight: widget.minSize),
                child: Row(
                  mainAxisSize: widget.mainAxisSize,
                  mainAxisAlignment: widget.alignment,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color:
                            widget.isPrimary
                                ? CupertinoColors.white
                                : buttonColor,
                        size: widget.iconSize,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.label, style: effectiveTextStyle),
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
      ),
    );
  }
}

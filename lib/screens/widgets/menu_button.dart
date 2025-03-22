import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/glassmorphic_container.dart';
import '../../theme_notifier.dart';

class MenuButton extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const MenuButton({super.key, required this.isExpanded, required this.onTap});

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
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

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: GlassmorphicContainer(
        width: 40,
        height: 40,
        blur: glassmorphicTheme.defaultBlur,
        opacity: 0.25,
        borderRadius: BorderRadius.circular(12),
        borderWidth: 1.0,
        borderColor: glassmorphicTheme.accentColor.withOpacity(0.5),
        backgroundColor:
            isDarkMode
                ? CupertinoColors.darkBackgroundGray.withOpacity(0.5)
                : CupertinoColors.white.withOpacity(0.5),
        useGradient: true,
        gradientColors: [
          glassmorphicTheme.accentColor.withOpacity(0.2),
          glassmorphicTheme.secondaryAccentColor.withOpacity(0.1),
        ],
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159, // Radians
                child: Icon(
                  widget.isExpanded
                      ? CupertinoIcons.xmark
                      : CupertinoIcons.line_horizontal_3,
                  color:
                      isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                  size: 24,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

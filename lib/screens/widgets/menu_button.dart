import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// A reusable menu button widget with Cupertino styling and haptic feedback
///
/// Features:
/// - Consistent styling across the app
/// - Visual feedback on press
/// - Haptic feedback for better user experience
/// - Smooth animations
/// - Proper theming support
class MenuButton extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const MenuButton({super.key, required this.isExpanded, required this.onTap});

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.mediumImpact();
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  _isPressed
                      ? CupertinoColors.systemGrey5
                      : isDarkMode
                      ? CupertinoColors.darkBackgroundGray.withOpacity(0.8)
                      : CupertinoColors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                widget.isExpanded
                    ? CupertinoIcons.xmark
                    : CupertinoIcons.line_horizontal_3,
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

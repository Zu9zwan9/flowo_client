import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/glassmorphic_container.dart';
import '../../theme_notifier.dart';

class SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    final effectiveAccentColor =
        isSelected
            ? accentColor
            : isDarkMode
            ? CupertinoColors.systemGrey.withOpacity(0.7)
            : CupertinoColors.systemGrey.withOpacity(0.7);

    final effectiveTextColor =
        isDarkMode ? CupertinoColors.white : CupertinoColors.black;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(); // Ensure this triggers navigation
      },
      behavior: HitTestBehavior.opaque, // Expand tap area
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: GlassmorphicContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          blur: glassmorphicTheme.defaultBlur * 0.8,
          opacity: isSelected ? 0.2 : 0.1,
          borderRadius: BorderRadius.circular(12),
          borderWidth: isSelected ? 1.0 : 0.5,
          borderColor:
              isSelected ? accentColor.withOpacity(0.5) : Colors.transparent,
          backgroundColor:
              isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
          useGradient: isSelected,
          gradientColors: [
            accentColor.withOpacity(0.1),
            accentColor.withOpacity(0.05),
          ],
          child: Row(
            children: [
              Icon(icon, color: effectiveAccentColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isSelected
                            ? accentColor
                            : effectiveTextColor.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

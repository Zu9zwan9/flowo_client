import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A reusable sidebar menu item with Cupertino styling
class SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textColor;

  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
    this.textColor = const Color(0xFF1C1C1E),
  });

  @override
  Widget build(BuildContext context) {
    // Use CupertinoTheme instead of MediaQuery to get the appropriate brightness
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? accentColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? accentColor
                      : isDarkMode
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey,
              size: 24,
              semanticLabel: label,
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected
                          ? accentColor
                          : isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

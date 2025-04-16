import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../theme/app_colors.dart';

/// A floating aurora sphere button with a "+" icon inside, designed for adding tasks
/// Following Apple's Human Interface Guidelines with a glass-like appearance
class AddTaskAuroraSphereButton extends StatefulWidget {
  /// Callback when the button is pressed
  final VoidCallback onPressed;

  /// The size of the sphere
  final double size;

  /// Optional label to display below the sphere
  final String? label;

  const AddTaskAuroraSphereButton({
    super.key,
    required this.onPressed,
    this.size = 50.0,
    this.label,
  });

  @override
  State<AddTaskAuroraSphereButton> createState() =>
      _AddTaskAuroraSphereButtonState();
}

class _AddTaskAuroraSphereButtonState extends State<AddTaskAuroraSphereButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Use system blue color for the aurora effect
    final baseColor = AppColors.primary;

    // Secondary blue color with slightly different shade for gradient effect
    final secondaryColor = CupertinoColors.activeBlue;

    // Resolve colors based on brightness
    final resolvedBaseColor = CupertinoDynamicColor.resolve(baseColor, context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onPressed();
                },
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: resolvedBaseColor.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                    gradient: RadialGradient(
                      colors: [
                        resolvedBaseColor.withOpacity(0.9),
                        secondaryColor.withOpacity(0.7),
                        resolvedBaseColor.withOpacity(0.5),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      center: Alignment(
                        math.sin(_animationController.value * math.pi) * 0.2,
                        math.cos(_animationController.value * math.pi) * 0.2,
                      ),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Aurora effect
                      CustomPaint(
                        painter: AddTaskAuroraPainter(
                          color: resolvedBaseColor,
                          animationValue: _animationController.value,
                          isDarkMode: isDarkMode,
                        ),
                        size: Size(widget.size, widget.size),
                      ),
                      // Plus icon
                      Icon(
                        CupertinoIcons.add,
                        color: CupertinoColors.white,
                        size: widget.size * 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.label!,
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the aurora effect with glass-like appearance
class AddTaskAuroraPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final bool isDarkMode;

  AddTaskAuroraPainter({
    required this.color,
    required this.animationValue,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create a glass-like effect with inner highlight
    final glassGradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(isDarkMode ? 0.3 : 0.7),
        color.withOpacity(0.2),
        color.withOpacity(0.1),
      ],
      stops: const [0.0, 0.6, 1.0],
      center: const Alignment(-0.3, -0.3),
      radius: 0.8,
    );

    // Draw the glass sphere base
    final glassPaint =
        Paint()
          ..shader = glassGradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          );
    canvas.drawCircle(center, radius * 0.9, glassPaint);

    // Create a shimmer effect
    for (int i = 0; i < 3; i++) {
      final offset = i * 0.2;
      final adjustedValue = (animationValue + offset) % 1.0;

      final paint =
          Paint()
            ..color = color.withOpacity(0.3 - (i * 0.1))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 + (adjustedValue * 1.5);

      final waveRadius = radius * (0.7 + (adjustedValue * 0.3));

      canvas.drawCircle(center, waveRadius, paint);
    }

    // Add some random aurora-like patterns
    final random = math.Random(animationValue.toInt() * 10000);

    for (int i = 0; i < 5; i++) {
      final paint =
          Paint()
            ..color = color.withOpacity(0.1 + (random.nextDouble() * 0.2))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 + (random.nextDouble() * 1.5);

      final startAngle = random.nextDouble() * 2 * math.pi;
      final sweepAngle = (random.nextDouble() * math.pi / 2) + (math.pi / 4);

      final arcRadius = radius * (0.5 + (random.nextDouble() * 0.5));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Add highlight to create glass effect
    final highlightPaint =
        Paint()
          ..color = Colors.white.withOpacity(isDarkMode ? 0.4 : 0.7)
          ..style = PaintingStyle.fill;

    final highlightPath = Path();
    highlightPath.addOval(
      Rect.fromCenter(
        center: Offset(center.dx - (radius * 0.3), center.dy - (radius * 0.3)),
        width: radius * 0.6,
        height: radius * 0.3,
      ),
    );
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(AddTaskAuroraPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}

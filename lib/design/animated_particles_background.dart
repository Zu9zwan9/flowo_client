import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_notifier.dart';

/// A widget that displays animated particles in the background
/// to give the app a unique and engaging visual character.
class AnimatedParticlesBackground extends StatefulWidget {
  /// The child widget to display on top of the particles
  final Widget child;

  /// The number of particles to display
  final int particleCount;

  /// Whether to use the theme's accent colors for particles
  final bool useThemeColors;

  /// Custom colors to use for particles (if not using theme colors)
  final List<Color>? particleColors;

  /// The minimum size of particles
  final double minParticleSize;

  /// The maximum size of particles
  final double maxParticleSize;

  /// The speed factor for particle movement
  final double speedFactor;

  /// Whether to show a subtle blur effect behind particles
  final bool showBlur;

  /// The opacity of the particles
  final double particleOpacity;

  const AnimatedParticlesBackground({
    Key? key,
    required this.child,
    this.particleCount = 20,
    this.useThemeColors = true,
    this.particleColors,
    this.minParticleSize = 4.0,
    this.maxParticleSize = 12.0,
    this.speedFactor = 1.0,
    this.showBlur = true,
    this.particleOpacity = 0.5,
  }) : super(key: key);

  @override
  State<AnimatedParticlesBackground> createState() =>
      _AnimatedParticlesBackgroundState();
}

class _AnimatedParticlesBackgroundState
    extends State<AnimatedParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize particles
    _particles = List.generate(
      widget.particleCount,
      (_) => _createRandomParticle(),
    );
  }

  @override
  void didUpdateWidget(AnimatedParticlesBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update particles if count changed
    if (widget.particleCount != oldWidget.particleCount) {
      _particles = List.generate(
        widget.particleCount,
        (_) => _createRandomParticle(),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Creates a random particle with random position, size, color, and movement
  Particle _createRandomParticle() {
    return Particle(
      position: Offset(_random.nextDouble(), _random.nextDouble()),
      size:
          widget.minParticleSize +
          _random.nextDouble() *
              (widget.maxParticleSize - widget.minParticleSize),
      color: Colors.white, // Will be set in build method
      speed: Offset(
        (_random.nextDouble() - 0.5) * 0.05 * widget.speedFactor,
        (_random.nextDouble() - 0.5) * 0.05 * widget.speedFactor,
      ),
      opacity: 0.3 + _random.nextDouble() * 0.7 * widget.particleOpacity,
      blurRadius: widget.showBlur ? 2.0 + _random.nextDouble() * 3.0 : 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Determine particle colors based on theme or custom colors
    final List<Color> effectiveParticleColors =
        widget.useThemeColors
            ? [
              glassmorphicTheme.accentColor,
              glassmorphicTheme.secondaryAccentColor,
              ...glassmorphicTheme.gradientColors,
            ]
            : widget.particleColors ?? [Colors.white];

    return Stack(
      children: [
        // Particles layer
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            return CustomPaint(
              painter: ParticlesPainter(
                particles: _particles,
                animationValue: _animationController.value,
                particleColors: effectiveParticleColors,
                isDarkMode: isDarkMode,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Child content
        widget.child,
      ],
    );
  }
}

/// A class representing a single particle
class Particle {
  /// The relative position of the particle (0.0 to 1.0 for both x and y)
  Offset position;

  /// The size of the particle in pixels
  final double size;

  /// The color of the particle
  final Color color;

  /// The movement speed and direction of the particle
  final Offset speed;

  /// The opacity of the particle
  final double opacity;

  /// The blur radius of the particle
  final double blurRadius;

  Particle({
    required this.position,
    required this.size,
    required this.color,
    required this.speed,
    required this.opacity,
    required this.blurRadius,
  });

  /// Updates the particle position based on its speed
  void update(double animationValue) {
    // Move the particle based on its speed
    position += speed;

    // Wrap around if the particle goes off-screen
    if (position.dx < 0) position = Offset(1.0, position.dy);
    if (position.dx > 1) position = Offset(0.0, position.dy);
    if (position.dy < 0) position = Offset(position.dx, 1.0);
    if (position.dy > 1) position = Offset(position.dx, 0.0);
  }
}

/// A custom painter that draws the particles
class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final List<Color> particleColors;
  final bool isDarkMode;

  ParticlesPainter({
    required this.particles,
    required this.animationValue,
    required this.particleColors,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(
      42,
    ); // Fixed seed for consistent color assignment

    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];

      // Update particle position
      particle.update(animationValue);

      // Calculate actual position in pixels
      final position = Offset(
        particle.position.dx * size.width,
        particle.position.dy * size.height,
      );

      // Assign a color from the available colors
      final colorIndex = i % particleColors.length;
      final color = particleColors[colorIndex].withOpacity(particle.opacity);

      // Create a paint for the particle
      final paint =
          Paint()
            ..color = color
            ..maskFilter =
                particle.blurRadius > 0
                    ? MaskFilter.blur(BlurStyle.normal, particle.blurRadius)
                    : null;

      // Draw the particle as a circle
      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

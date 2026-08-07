
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D file/send tiles drifting bottom to top, scattered behind auth screens.
class FloatingFilesBackground extends StatefulWidget {
  const FloatingFilesBackground({super.key, this.opacity = 1});

  final double opacity;

  @override
  State<FloatingFilesBackground> createState() => _FloatingFilesBackgroundState();
}

class _FloatingFilesBackgroundState extends State<FloatingFilesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_DriftParticle> _particles;

  static const _icons = [
    Icons.send_rounded,
    Icons.near_me_rounded,
    Icons.upload_file_rounded,
    Icons.description_outlined,
    Icons.insert_drive_file_outlined,
    Icons.folder_rounded,
    Icons.image_outlined,
    Icons.cloud_upload_outlined,
  ];

  static const _tileColors = [
    [Color(0xFF4D49FF), Color(0xFF7B6CFF)],
    [Color(0xFF6322D1), Color(0xFF8B4FE8)],
    [Color(0xFF1976D2), Color(0xFF5DF2D6)],
    [Color(0xFF7E57C2), Color(0xFFB39DDB)],
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random(11);

    _particles = List.generate(16, (i) {
      return _DriftParticle(
        icon: _icons[i % _icons.length],
        colors: _tileColors[i % _tileColors.length],
        progress: random.nextDouble(),
        // Changed from lane: Assigns a random horizontal starting point between 0.0 and 1.0
        startX: random.nextDouble(), 
        size: 34 + random.nextDouble() * 22,
        speed: 0.055 + random.nextDouble() * 0.09,
        opacity: 0.55 + random.nextDouble() * 0.35,
        tiltX: (random.nextDouble() - 0.5) * 0.55,
        tiltY: (random.nextDouble() - 0.5) * 0.65,
        spin: random.nextDouble() * math.pi * 2,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final particle in _particles)
                  _buildParticle(
                    particle,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildParticle(_DriftParticle particle, double w, double h) {
    final t = (particle.progress + _controller.value * particle.speed) % 1.0;

    // SCATTERED X: Position strictly horizontally based on random startX
    final x = particle.startX * w;

    // UNIDIRECTIONAL Y: Move straight up
    // Add a buffer so they spawn completely off-screen at the bottom and disappear off-screen at the top
    final buffer = particle.size * 2;
    final totalTravel = h + (buffer * 2);
    final y = (h + buffer) - (t * totalTravel);

    // Depth: larger & sharper near center of screen, smaller at edges
    final depth = math.sin(t * math.pi);
    final scale = 0.72 + depth * 0.38;
    final alpha = particle.opacity * depth.clamp(0.35, 1.0) * widget.opacity;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0018)
      // Note: Replaced translateByDouble with standard translate for safety
      ..translate(x, y, depth * 40) 
      ..rotateX(particle.tiltX + depth * 0.18)
      ..rotateY(particle.tiltY + 0.35)
      ..rotateZ(-0.45 + math.sin(t * math.pi * 2 + particle.spin) * 0.08)
      ..scale(scale, scale, 1.0);

    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: _Floating3DTile(
        icon: particle.icon,
        size: particle.size,
        colors: particle.colors,
        opacity: alpha,
      ),
    );
  }
}

class _Floating3DTile extends StatelessWidget {
  const _Floating3DTile({
    required this.icon,
    required this.size,
    required this.colors,
    required this.opacity,
  });

  final IconData icon;
  final double size;
  final List<Color> colors;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Back depth layer
            Positioned(
              left: size * 0.1,
              top: size * 0.14,
              child: Container(
                width: size * 0.88,
                height: size * 0.88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  color: colors.last.withValues(alpha: 0.35),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.25),
                      blurRadius: size * 0.2,
                      offset: Offset(size * 0.06, size * 0.1),
                    ),
                  ],
                ),
              ),
            ),
            // Main 3D tile
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.first,
                    colors.last,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.45),
                    blurRadius: size * 0.28,
                    spreadRadius: 1,
                    offset: Offset(size * 0.04, size * 0.08),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.35),
                    blurRadius: size * 0.08,
                    offset: Offset(-size * 0.03, -size * 0.04),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Gloss highlight
                  Positioned(
                    left: size * 0.12,
                    top: size * 0.1,
                    child: Container(
                      width: size * 0.35,
                      height: size * 0.18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      icon,
                      size: size * 0.46,
                      color: Colors.white.withValues(alpha: 0.95),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: Offset(0, size * 0.04),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriftParticle {
  const _DriftParticle({
    required this.icon,
    required this.colors,
    required this.progress,
    required this.startX, // Replaced lane
    required this.size,
    required this.speed,
    required this.opacity,
    required this.tiltX,
    required this.tiltY,
    required this.spin,
  });

  final IconData icon;
  final List<Color> colors;
  final double progress;
  final double startX; 
  final double size;
  final double speed;
  final double opacity;
  final double tiltX;
  final double tiltY;
  final double spin;
}
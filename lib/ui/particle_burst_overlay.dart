import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleBurstOverlay extends StatefulWidget {
  final int triggerCount;
  const ParticleBurstOverlay({super.key, required this.triggerCount});

  @override
  State<ParticleBurstOverlay> createState() => _ParticleBurstOverlayState();
}

class _ParticleBurstOverlayState extends State<ParticleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_HoloParticle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant ParticleBurstOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerCount > oldWidget.triggerCount) {
      _spawnBurst();
    }
  }

  void _spawnBurst() {
    _particles.clear();
    for (int i = 0; i < 65; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 60.0 + _rng.nextDouble() * 180.0;
      _particles.add(_HoloParticle(
        angle: angle,
        speed: speed,
        radius: 2.0 + _rng.nextDouble() * 3.5,
      ));
    }
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(
          particles: _particles,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _HoloParticle {
  final double angle;
  final double speed;
  final double radius;
  _HoloParticle({required this.angle, required this.speed, required this.radius});
}

class _ParticlePainter extends CustomPainter {
  final List<_HoloParticle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(1.0 - progress);

    for (final p in particles) {
      final dist = p.speed * Curves.easeOutCubic.transform(progress);
      final pos = Offset(
        center.dx + math.cos(p.angle) * dist,
        center.dy + math.sin(p.angle) * dist,
      );
      canvas.drawCircle(pos, p.radius * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

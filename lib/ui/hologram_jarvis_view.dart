import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../controllers/jarvis_controller.dart';
import 'particle_burst_overlay.dart';

class HologramJarvisView extends ConsumerStatefulWidget {
  const HologramJarvisView({super.key});

  @override
  ConsumerState<HologramJarvisView> createState() => _HologramJarvisViewState();
}

class _HologramJarvisViewState extends ConsumerState<HologramJarvisView>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _shaderProgram;
  late final Ticker _ticker;
  double _elapsedSeconds = 0.0;

  double _parallaxX = 0.0;
  double _parallaxY = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      if (ref.read(jarvisProvider).renderActive) {
        setState(() {
          _elapsedSeconds = elapsed.inMilliseconds / 1000.0;
        });
      }
    })..start();

    _accelSub = accelerometerEventStream().listen((event) {
      if (ref.read(jarvisProvider).renderActive) {
        setState(() {
          _parallaxX = (event.x * 3.5).clamp(-20.0, 20.0);
          _parallaxY = (event.y * 3.5).clamp(-20.0, 20.0);
        });
      }
    });
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/hologram.frag');
      if (mounted) setState(() => _shaderProgram = program);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jarvisProvider);

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 120),
          left: -30 + _parallaxX,
          right: -30 - _parallaxX,
          top: -30 + _parallaxY,
          bottom: -30 - _parallaxY,
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.1,
                colors: [
                  Color(0xFF062846),
                  Color(0xFF030B17),
                  Color(0xFF010409),
                ],
              ),
            ),
          ),
        ),
        if (_shaderProgram != null)
          Positioned.fill(
            child: CustomPaint(
              painter: _HologramShaderPainter(
                shader: _shaderProgram!.fragmentShader(),
                time: _elapsedSeconds,
                amplitude: state.audioAmplitude,
                activeGlow: state.mood == JarvisMood.idle ? 0.2 : 1.0,
              ),
            ),
          ),
        Positioned.fill(
          child: ParticleBurstOverlay(triggerCount: state.particleTriggerCount),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildPrivacyHeader(state),
              const Spacer(),
              SizedBox(
                height: 260,
                width: 260,
                child: CustomPaint(
                  painter: _HoloVisorPainter(
                    time: _elapsedSeconds,
                    amplitude: state.audioAmplitude,
                    mood: state.mood,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                width: 280,
                child: CustomPaint(
                  painter: _WaveformVisualizerPainter(
                    time: _elapsedSeconds,
                    amplitude: state.audioAmplitude,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickCommandChips(),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _BilingualConsoleCard(state: state),
              ),
              const SizedBox(height: 20),
              _buildMicControlButton(context, state),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCommandChips() {
    final notifier = ref.read(jarvisProvider.notifier);
    final chips = [
      ('टॉपग का फेवरेट गाना', 'hi'),
      ('Play Topg favorite song', 'en'),
      ('वॉल्यूम 50% कर दो', 'hi'),
      ('Create a new playlist on Spotify', 'en'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: chips.map((c) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: const Color(0xFF06233B),
              side: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.4)),
              label: Text(
                c.$1,
                style: const TextStyle(color: Color(0xFFE0FFFF), fontSize: 12),
              ),
              onPressed: () => notifier.runQuickCommand(c.$1, c.$2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrivacyHeader(JarvisState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.micEnabled
                      ? const Color(0xFF00F0FF)
                      : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'JARVIS PRO • 100% OFFLINE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  letterSpacing: 1.6,
                  color: Color(0xFF00F0FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            state.activeLanguage == 'hi' ? 'हिंदी / EN' : 'EN / हिंदी',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMicControlButton(BuildContext context, JarvisState state) {
    return GestureDetector(
      onTap: () => ref.read(jarvisProvider.notifier).toggleMicrophone(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 68,
        width: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: state.micEnabled
              ? const Color(0xFF00F0FF).withOpacity(0.18)
              : Colors.white10,
          border: Border.all(
            color: state.micEnabled ? const Color(0xFF00F0FF) : Colors.white38,
            width: 2,
          ),
        ),
        child: Icon(
          state.micEnabled ? Icons.mic : Icons.mic_off,
          color: state.micEnabled ? const Color(0xFF00F0FF) : Colors.white54,
          size: 30,
        ),
      ),
    );
  }
}

class _BilingualConsoleCard extends StatelessWidget {
  final JarvisState state;
  const _BilingualConsoleCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF051329).withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.displayTranscript.isNotEmpty)
            Text(
              '> "${state.displayTranscript}"',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            state.jarvisResponse,
            style: const TextStyle(
              color: Color(0xFFE0FFFF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HologramShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final double amplitude;
  final double activeGlow;

  _HologramShaderPainter({
    required this.shader,
    required this.time,
    required this.amplitude,
    required this.activeGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, amplitude)
      ..setFloat(4, activeGlow);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _HologramShaderPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.amplitude != amplitude;
}

class _HoloVisorPainter extends CustomPainter {
  final double time;
  final double amplitude;
  final JarvisMood mood;

  _HoloVisorPainter({
    required this.time,
    required this.amplitude,
    required this.mood,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = mood == JarvisMood.shrugging
          ? const Color(0xFFFF4D6D)
          : const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 95 + math.sin(time * 3) * 4, paint);

    // Eyes
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(-34, -14), width: 28, height: 14),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(34, -14), width: 28, height: 14),
      math.pi,
      math.pi,
      false,
      paint,
    );

    // Lip-sync mouth
    final mouthOpen = 4.0 + amplitude * 28.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 38),
        width: 54,
        height: mouthOpen,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HoloVisorPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.amplitude != amplitude;
}

class _WaveformVisualizerPainter extends CustomPainter {
  final double time;
  final double amplitude;

  _WaveformVisualizerPainter({required this.time, required this.amplitude});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const int bars = 28;
    final spacing = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final wave = math.sin(time * 9.0 + i * 0.45).abs();
      final barHeight = 6.0 + (wave * (0.15 + amplitude) * size.height * 0.85);
      final x = i * spacing + spacing / 2;
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformVisualizerPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.amplitude != amplitude;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/graphics.dart';

/// A one-shot burst of confetti and stars. Finite by design: it plays once
/// per [play] and then stops, so it never keeps the app (or a test) busy.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.play, this.origin = const Alignment(0, -0.1)});

  /// Change this value to fire a new burst.
  final int play;
  final Alignment origin;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void didUpdateWidget(ConfettiBurst old) {
    super.didUpdateWidget(old);
    if (old.play != widget.play && widget.play > 0) _c.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    if (widget.play > 0) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => _c.isDismissed || _c.isCompleted
            ? const SizedBox.expand()
            : CustomPaint(painter: _ConfettiPainter(_c.value, widget.origin, widget.play, Graphics.of(context).confetti), size: Size.infinite),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.origin, this.seed, this.count);
  final int count;
  final double t;
  final Alignment origin;
  final int seed;

  static const _colors = [Color(0xFFFF5FA2), Color(0xFFFFC83D), Color(0xFF3CD5F2), Color(0xFF7CE38B), Color(0xFFB57BFF), Color(0xFFFF8A3D)];

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    final o = origin.alongSize(size);
    final secs = t * 2.2;
    final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);

    // Central flash.
    if (t < 0.25) {
      final r = size.shortestSide * (0.2 + t * 2);
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.7 * (1 - t / 0.25)),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }

    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (rand.nextDouble() - 0.5) * math.pi * 1.5;
      final speed = size.shortestSide * (0.7 + rand.nextDouble() * 0.9);
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed;
      final g = size.shortestSide * 1.1;
      final drag = 1 - math.exp(-secs * 2.2);
      final x = o.dx + vx * drag / 2.2 + math.sin(secs * 6 + i) * 10;
      final y = o.dy + vy * drag / 2.2 + 0.5 * g * secs * secs * 0.35;
      final spin = secs * (4 + rand.nextDouble() * 8) + i;
      final color = _colors[i % _colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      if (i % 5 == 0) {
        _star(canvas, 7 + rand.nextDouble() * 6, color);
      } else {
        final flip = math.cos(spin * 1.7).abs();
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 12, height: 7 * flip + 1), const Radius.circular(2)),
          Paint()..color = color,
        );
      }
      canvas.restore();
    }
  }

  void _star(Canvas canvas, double r, Color color) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final rr = k.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + k * math.pi / 5;
      final p = Offset(math.cos(a) * rr, math.sin(a) * rr);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

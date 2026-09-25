import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/age_band.dart';
import '../theme/motion.dart';
import '../theme/nova_theme.dart';

/// A living, layered environment behind every screen: graded sky, light
/// source with bloom, parallax hills, drifting clouds or twinkling stars,
/// floating particles and a lens vignette. Each age group has its own world.
class WorldBackdrop extends StatefulWidget {
  const WorldBackdrop({super.key, required this.world, this.groundLevel = 0.72, this.child});

  final WorldKind world;

  /// Where the nearest hill line sits, as a fraction of the height.
  final double groundLevel;
  final Widget? child;

  @override
  State<WorldBackdrop> createState() => _WorldBackdropState();
}

class _WorldBackdropState extends State<WorldBackdrop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((e) => setState(() => _t = e.inMicroseconds / 1e6));
  double _t = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = AmbientMotion.of(context);
    if (on && !_ticker.isActive) _ticker.start();
    if (!on && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: CustomPaint(painter: _WorldPainter(widget.world, _t, widget.groundLevel))),
        ?widget.child,
      ],
    );
  }
}

class _WorldPainter extends CustomPainter {
  _WorldPainter(this.world, this.t, this.ground) : p = WorldPalette.of(world);

  final WorldKind world;
  final double t;
  final double ground;
  final WorldPalette p;

  static final _rand = math.Random(7);
  static final _seeds = List.generate(90, (_) => (_rand.nextDouble(), _rand.nextDouble(), _rand.nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Sky.
    canvas.drawRect(
      rect,
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h * ground), [p.skyTop, Color.lerp(p.skyTop, p.skyBottom, 0.55)!, p.skyBottom], [0, 0.55, 1]),
    );

    switch (world) {
      case WorldKind.cosmicLab:
        _stars(canvas, size);
        _nebula(canvas, size);
        _planet(canvas, Offset(w * 0.8, h * 0.2), math.min(w, h) * 0.12);
        _shootingStar(canvas, size);
      case WorldKind.sunnyForest:
        _sun(canvas, Offset(w * 0.78, h * 0.17), math.min(w, h) * 0.09, rays: true);
        _clouds(canvas, size, tint: Colors.white);
      case WorldKind.candyMeadow:
        _rainbow(canvas, size);
        _sun(canvas, Offset(w * 0.18, h * 0.16), math.min(w, h) * 0.08, rays: false);
        _clouds(canvas, size, tint: const Color(0xFFFFF6FB));
    }

    // Parallax hill layers, far to near.
    _hills(canvas, size, level: ground - 0.16, amp: 0.05, freq: 1.3, speed: 0.02, color: p.hillFar, phase: 0.3, fog: 0.35);
    if (world == WorldKind.sunnyForest) _trees(canvas, size, ground - 0.1);
    if (world == WorldKind.cosmicLab) _crystals(canvas, size, ground - 0.06);
    _hills(canvas, size, level: ground - 0.07, amp: 0.04, freq: 2.1, speed: 0.035, color: p.hillMid, phase: 1.7, fog: 0.15);
    _hills(canvas, size, level: ground, amp: 0.025, freq: 1.6, speed: 0.05, color: p.hillNear, phase: 2.9, fog: 0);
    if (world == WorldKind.candyMeadow) _flowers(canvas, size);

    _particles(canvas, size);

    // Lens vignette.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h * 0.45),
          math.max(w, h) * 0.75,
          [Colors.transparent, Colors.transparent, (p.isNight ? Colors.black : const Color(0xFF2A1640)).withValues(alpha: p.isNight ? 0.5 : 0.22)],
          [0, 0.62, 1],
        ),
    );
  }

  void _sun(Canvas canvas, Offset c, double r, {required bool rays}) {
    canvas.drawCircle(c, r * 5, Paint()..shader = ui.Gradient.radial(c, r * 5, [p.glow.withValues(alpha: 0.55), p.glow.withValues(alpha: 0)]));
    if (rays) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(t * 0.05);
      final ray = Paint()..shader = ui.Gradient.radial(Offset.zero, r * 9, [p.glow.withValues(alpha: 0.28), p.glow.withValues(alpha: 0)]);
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        final spread = 0.07 + 0.02 * math.sin(t * 0.8 + i);
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(math.cos(a - spread) * r * 9, math.sin(a - spread) * r * 9)
            ..lineTo(math.cos(a + spread) * r * 9, math.sin(a + spread) * r * 9)
            ..close(),
          ray,
        );
      }
      canvas.restore();
    }
    canvas.drawCircle(
      c,
      r,
      Paint()..shader = ui.Gradient.radial(c - Offset(r * 0.3, r * 0.3), r * 1.3, [Colors.white, p.glow, const Color(0xFFFFC857)], [0, 0.45, 1]),
    );
  }

  void _clouds(Canvas canvas, Size size, {required Color tint}) {
    final w = size.width, h = size.height;
    for (var i = 0; i < 5; i++) {
      final s = _seeds[i];
      final speed = 6 + s.$3 * 10;
      final x = ((s.$1 * (w + 300) + t * speed) % (w + 300)) - 150;
      final y = h * (0.08 + s.$2 * 0.28);
      _cloud(canvas, Offset(x, y), 50 + s.$3 * 50, tint);
    }
  }

  void _cloud(Canvas canvas, Offset c, double r, Color tint) {
    final puffs = [
      (Offset(-r * 0.9, r * 0.15), r * 0.55),
      (Offset(-r * 0.3, -r * 0.2), r * 0.72),
      (Offset(r * 0.45, -r * 0.05), r * 0.62),
      (Offset(r * 1.0, r * 0.2), r * 0.45),
    ];
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, r * 0.55), width: r * 2.6, height: r * 0.35),
      Paint()..color = const Color(0xFF6A5A9A).withValues(alpha: 0.08),
    );
    for (final (o, pr) in puffs) {
      final pc = c + o;
      canvas.drawCircle(
        pc,
        pr,
        Paint()..shader = ui.Gradient.radial(pc - Offset(pr * 0.35, pr * 0.45), pr * 1.4, [Colors.white, tint, shade(tint, -0.12)], [0, 0.55, 1]),
      );
    }
  }

  void _rainbow(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.62, size.height * (ground + 0.05));
    final r = size.width * 0.42;
    const colors = [Color(0xFFFF8FB8), Color(0xFFFFC98F), Color(0xFFFFF09A), Color(0xFFA8F0C4), Color(0xFF9AD5FF), Color(0xFFC9A8FF)];
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - i * 14),
        math.pi,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = colors[i].withValues(alpha: 0.35),
      );
    }
  }

  void _stars(Canvas canvas, Size size) {
    for (var i = 0; i < _seeds.length; i++) {
      final s = _seeds[i];
      final twinkle = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * (1 + s.$3 * 3) + i));
      final pos = Offset(s.$1 * size.width, s.$2 * size.height * ground);
      final r = 0.6 + s.$3 * 1.6;
      canvas.drawCircle(pos, r * 3, Paint()..color = Colors.white.withValues(alpha: 0.08 * twinkle));
      canvas.drawCircle(pos, r, Paint()..color = Colors.white.withValues(alpha: twinkle));
    }
  }

  void _nebula(Canvas canvas, Size size) {
    final blobs = [
      (Offset(size.width * 0.25, size.height * 0.3), size.width * 0.45, const Color(0xFFB44BFF)),
      (Offset(size.width * 0.7, size.height * 0.45), size.width * 0.4, const Color(0xFF28D7E8)),
    ];
    for (final (c, r, color) in blobs) {
      final drift = Offset(math.sin(t * 0.07) * 20, math.cos(t * 0.05) * 12);
      canvas.drawCircle(c + drift, r, Paint()..shader = ui.Gradient.radial(c + drift, r, [color.withValues(alpha: 0.22), color.withValues(alpha: 0)]));
    }
  }

  void _planet(Canvas canvas, Offset c, double r) {
    final tilt = -0.35;
    final ring = Rect.fromCenter(center: Offset.zero, width: r * 3.4, height: r * 0.9);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..shader = ui.Gradient.linear(
        ring.centerLeft,
        ring.centerRight,
        [const Color(0x00FFD27A), const Color(0xCCFFD27A), const Color(0x00FFD27A)],
        [0, 0.5, 1],
      );
    canvas.save();
    canvas.translate(c.dx, c.dy + math.sin(t * 0.4) * 4);
    canvas.rotate(tilt);
    canvas.drawArc(ring, math.pi, math.pi, false, ringPaint);
    canvas.drawCircle(Offset.zero, r * 2.2, Paint()..shader = ui.Gradient.radial(Offset.zero, r * 2.2, [const Color(0x55FF7AD9), const Color(0x00FF7AD9)]));
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-r * 0.4, -r * 0.4),
          r * 1.6,
          [const Color(0xFFFFC2E8), const Color(0xFFE05BB5), const Color(0xFF5A1E7A), const Color(0xFF230C3F)],
          [0, 0.35, 0.8, 1],
        ),
    );
    canvas.drawArc(ring, 0, math.pi, false, ringPaint);
    canvas.restore();
  }

  void _shootingStar(Canvas canvas, Size size) {
    const period = 7.0;
    final u = (t % period) / 1.1;
    if (u > 1) return;
    final start = Offset(size.width * 0.1, size.height * 0.08);
    final end = Offset(size.width * 0.55, size.height * 0.3);
    final head = Offset.lerp(start, end, u)!;
    final tail = Offset.lerp(start, end, math.max(0, u - 0.25))!;
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(tail, head, [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.9 * (1 - u))]),
    );
  }

  void _hills(
    Canvas canvas,
    Size size, {
    required double level,
    required double amp,
    required double freq,
    required double speed,
    required Color color,
    required double phase,
    required double fog,
  }) {
    final w = size.width, h = size.height;
    final shift = t * speed;
    final path = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w + 8; x += 8) {
      final u = x / w;
      final y = h * (level + amp * math.sin((u + shift) * freq * math.pi * 2 + phase) + amp * 0.4 * math.sin((u - shift) * freq * 5.3 + phase));
      path.lineTo(x, y);
    }
    path
      ..lineTo(w, h)
      ..close();
    final top = h * (level - amp);
    final hazed = Color.lerp(color, p.skyBottom, fog)!;
    canvas.drawPath(path, Paint()..shader = ui.Gradient.linear(Offset(0, top), Offset(0, h), [shade(hazed, 0.18), hazed, shade(hazed, -0.25)], [0, 0.25, 1]));
    // Sunlit rim along the crest.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = p.glow.withValues(alpha: p.isNight ? 0.25 : 0.4),
    );
  }

  void _trees(Canvas canvas, Size size, double level) {
    final w = size.width, h = size.height;
    for (var i = 0; i < 7; i++) {
      final s = _seeds[20 + i];
      final x = (i + 0.3 + s.$1 * 0.4) / 7 * w;
      final base = h * (level + 0.02 * math.sin(i * 1.7));
      final r = (22 + s.$2 * 22) * (w / 800).clamp(0.6, 1.4);
      final sway = math.sin(t * 0.9 + i) * 0.03;
      canvas.save();
      canvas.translate(x, base);
      canvas.rotate(sway);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -r * 0.6), width: r * 0.28, height: r * 1.3), Radius.circular(r * 0.1)),
        Paint()..color = const Color(0xFF7A4B2A),
      );
      final green = Color.lerp(p.hillMid, p.hillNear, s.$3)!;
      for (final (o, pr) in [(Offset(-r * 0.45, -r * 1.3), r * 0.7), (Offset(r * 0.45, -r * 1.35), r * 0.68), (Offset(0, -r * 1.85), r * 0.8)]) {
        canvas.drawCircle(
          o,
          pr,
          Paint()..shader = ui.Gradient.radial(o - Offset(pr * 0.4, pr * 0.45), pr * 1.5, [shade(green, 0.35), green, shade(green, -0.35)], [0, 0.45, 1]),
        );
      }
      canvas.restore();
    }
  }

  void _crystals(Canvas canvas, Size size, double level) {
    final w = size.width, h = size.height;
    for (var i = 0; i < 6; i++) {
      final s = _seeds[40 + i];
      final x = (i + 0.2 + s.$1 * 0.6) / 6 * w;
      final base = h * level;
      final ch = 30 + s.$2 * 40;
      final pulse = 0.6 + 0.4 * math.sin(t * 1.5 + i);
      final color = i.isEven ? const Color(0xFF28D7E8) : const Color(0xFFB44BFF);
      canvas.drawCircle(
        Offset(x, base - ch * 0.5),
        ch,
        Paint()..shader = ui.Gradient.radial(Offset(x, base - ch * 0.5), ch, [color.withValues(alpha: 0.3 * pulse), color.withValues(alpha: 0)]),
      );
      final path = Path()
        ..moveTo(x - ch * 0.18, base)
        ..lineTo(x - ch * 0.12, base - ch * 0.8)
        ..lineTo(x, base - ch)
        ..lineTo(x + ch * 0.12, base - ch * 0.8)
        ..lineTo(x + ch * 0.18, base)
        ..close();
      canvas.drawPath(
        path,
        Paint()..shader = ui.Gradient.linear(Offset(x - ch * 0.2, 0), Offset(x + ch * 0.2, 0), [shade(color, 0.5), color, shade(color, -0.4)], [0, 0.5, 1]),
      );
    }
  }

  void _flowers(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const petals = [Color(0xFFFF8FB8), Color(0xFFFFE27A), Color(0xFFC9A8FF), Colors.white];
    for (var i = 0; i < 16; i++) {
      final s = _seeds[60 + i];
      final c = Offset(s.$1 * w, h * (ground + 0.05 + s.$2 * 0.2));
      final r = 4 + s.$3 * 5;
      final sway = math.sin(t * 1.2 + i) * 1.5;
      for (var k = 0; k < 5; k++) {
        final a = k * math.pi * 2 / 5;
        canvas.drawCircle(c + Offset(math.cos(a) * r + sway, math.sin(a) * r), r * 0.7, Paint()..color = petals[i % petals.length]);
      }
      canvas.drawCircle(c + Offset(sway, 0), r * 0.5, Paint()..color = const Color(0xFFFFB347));
    }
  }

  void _particles(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final night = p.isNight;
    for (var i = 0; i < 22; i++) {
      final s = _seeds[i + 5];
      final speed = 8 + s.$3 * 14;
      final y = h - ((s.$2 * h + t * speed) % (h + 40));
      final x = s.$1 * w + math.sin(t * 0.6 + i) * 18;
      final r = 1.5 + s.$3 * (world == WorldKind.candyMeadow ? 9 : 2.5);
      if (world == WorldKind.candyMeadow) {
        // Soap bubbles with iridescent rims.
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(x, y),
              r,
              [Colors.white.withValues(alpha: 0.05), const Color(0xFFB9E4FF).withValues(alpha: 0.35), const Color(0xFFFFB5D2).withValues(alpha: 0.6)],
              [0, 0.8, 1],
            ),
        );
        canvas.drawCircle(Offset(x - r * 0.35, y - r * 0.35), r * 0.22, Paint()..color = Colors.white.withValues(alpha: 0.8));
      } else {
        final glow = night ? p.glow : const Color(0xFFFFF3C4);
        canvas.drawCircle(Offset(x, y), r * 3, Paint()..color = glow.withValues(alpha: 0.12));
        canvas.drawCircle(Offset(x, y), r, Paint()..color = glow.withValues(alpha: 0.8));
      }
    }
  }

  @override
  bool shouldRepaint(_WorldPainter old) => old.t != t || old.world != world || old.ground != ground;
}

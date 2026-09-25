import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A glossy, lit 3D apple: two-lobed body with a key-light gradient, a warm
/// bounce light underneath, a sharp specular, a stem and a leaf.
class Apple3D extends StatelessWidget {
  const Apple3D({super.key, this.size = 64, this.lifted = false});
  final double size;

  /// Lifted apples (being dragged) cast a wider, softer shadow further away.
  final bool lifted;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _ApplePainter(lifted)),
  );
}

class _ApplePainter extends CustomPainter {
  _ApplePainter(this.lifted);
  final bool lifted;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s * 0.56);
    final r = s * 0.4;

    // Shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx + (lifted ? s * 0.12 : 0), s * (lifted ? 1.12 : 0.95)),
        width: r * (lifted ? 1.5 : 1.8),
        height: r * (lifted ? 0.35 : 0.4),
      ),
      Paint()
        ..color = const Color(0xFF3A1030).withValues(alpha: lifted ? 0.18 : 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, lifted ? 6 : 3),
    );

    final body = Path()
      ..moveTo(c.dx, c.dy - r * 0.72)
      ..cubicTo(c.dx + r * 0.5, c.dy - r * 1.12, c.dx + r * 1.12, c.dy - r * 0.8, c.dx + r * 1.02, c.dy + r * 0.05)
      ..cubicTo(c.dx + r * 0.96, c.dy + r * 0.72, c.dx + r * 0.48, c.dy + r * 1.02, c.dx + r * 0.2, c.dy + r * 0.94)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.86, c.dx - r * 0.2, c.dy + r * 0.94)
      ..cubicTo(c.dx - r * 0.48, c.dy + r * 1.02, c.dx - r * 0.96, c.dy + r * 0.72, c.dx - r * 1.02, c.dy + r * 0.05)
      ..cubicTo(c.dx - r * 1.12, c.dy - r * 0.8, c.dx - r * 0.5, c.dy - r * 1.12, c.dx, c.dy - r * 0.72)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          c + Offset(-r * 0.4, -r * 0.45),
          r * 1.7,
          [const Color(0xFFFF8A7A), const Color(0xFFE8242E), const Color(0xFFA5102A), const Color(0xFF5E0A2A)],
          [0, 0.35, 0.75, 1],
        ),
    );
    // Bounce light.
    canvas.drawPath(body, Paint()..shader = ui.Gradient.radial(c + Offset(r * 0.1, r * 1.0), r * 0.9, [const Color(0x66FFB36B), const Color(0x00FFB36B)]));
    // Rim.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025
        ..shader = ui.Gradient.linear(
          c + Offset(-r, -r),
          c + Offset(r, r),
          [const Color(0x00FFE0C0), const Color(0x00FFE0C0), const Color(0xAAFFE0C0)],
          [0, 0.6, 1],
        ),
    );
    // Specular highlights.
    canvas.save();
    canvas.translate(c.dx - r * 0.45, c.dy - r * 0.32);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.52, height: r * 0.26),
      Paint()..shader = ui.Gradient.radial(Offset.zero, r * 0.26, [Colors.white.withValues(alpha: 0.95), Colors.white.withValues(alpha: 0)]),
    );
    canvas.restore();
    canvas.drawCircle(c + Offset(r * 0.5, r * 0.45), r * 0.07, Paint()..color = Colors.white.withValues(alpha: 0.5));

    // Stem.
    final stem = Path()
      ..moveTo(c.dx, c.dy - r * 0.68)
      ..quadraticBezierTo(c.dx + r * 0.05, c.dy - r * 1.05, c.dx + r * 0.18, c.dy - r * 1.28);
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF5B3A1E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.06
        ..strokeCap = StrokeCap.round,
    );
    // Leaf.
    final base = c + Offset(r * 0.12, -r * 1.08);
    final leaf = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + r * 0.35, base.dy - r * 0.55, base.dx + r * 0.95, base.dy - r * 0.35)
      ..quadraticBezierTo(base.dx + r * 0.5, base.dy + r * 0.15, base.dx, base.dy)
      ..close();
    canvas.drawPath(leaf, Paint()..shader = ui.Gradient.linear(base, base + Offset(r * 0.9, -r * 0.4), [const Color(0xFF2F9E45), const Color(0xFF8BE36B)]));
    canvas.drawLine(
      base,
      base + Offset(r * 0.8, -r * 0.33),
      Paint()
        ..color = const Color(0x5520501E)
        ..strokeWidth = s * 0.012,
    );
  }

  @override
  bool shouldRepaint(_ApplePainter old) => old.lifted != lifted;
}

/// A porcelain plate seen in perspective: shaded rim, recessed well with
/// an inner shadow, and a glow ring when something is hovering over it.
class Plate3D extends StatelessWidget {
  const Plate3D({super.key, this.width = 240, this.glow = 0, this.glowColor = const Color(0xFFFFD54F), this.child});
  final double width;
  final double glow;
  final Color glowColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * 0.42,
    child: CustomPaint(painter: _PlatePainter(glow, glowColor), child: child),
  );
}

class _PlatePainter extends CustomPainter {
  _PlatePainter(this.glow, this.glowColor);
  final double glow;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final outer = Rect.fromLTWH(0, h * 0.1, w, h * 0.8);
    final inner = outer.deflate(w * 0.12).translate(0, -h * 0.02);

    if (glow > 0) {
      canvas.drawOval(
        outer.inflate(18 * glow),
        Paint()..shader = ui.Gradient.radial(outer.center, w * 0.6, [glowColor.withValues(alpha: 0.55 * glow), glowColor.withValues(alpha: 0)]),
      );
    }
    canvas.drawOval(
      outer.translate(0, h * 0.08),
      Paint()
        ..color = const Color(0xFF2A1640).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Plate side thickness.
    canvas.drawOval(outer.translate(0, h * 0.05), Paint()..color = const Color(0xFFC9C3DA));
    // Rim.
    canvas.drawOval(
      outer,
      Paint()..shader = ui.Gradient.linear(outer.topLeft, outer.bottomRight, [Colors.white, const Color(0xFFF1EDF8), const Color(0xFFD9D2EA)], [0, 0.5, 1]),
    );
    // Decorative band.
    canvas.drawOval(
      outer.deflate(w * 0.05),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF7FB6FF).withValues(alpha: 0.7),
    );
    // Well with inner shadow.
    canvas.drawOval(
      inner,
      Paint()..shader = ui.Gradient.linear(inner.topCenter, inner.bottomCenter, [const Color(0xFFD7D0E6), const Color(0xFFF7F4FC)], [0, 0.7]),
    );
    // Specular glint on the rim.
    canvas.save();
    canvas.translate(outer.left + w * 0.24, outer.top + h * 0.12);
    canvas.rotate(-0.2);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.2, height: h * 0.06), Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlatePainter old) => old.glow != glow || old.glowColor != glowColor;
}

/// A little glowing star, for scores and badges.
class StarShape extends StatelessWidget {
  const StarShape({super.key, this.size = 28, this.filled = true});
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _StarPainter(filled)),
  );
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.filled);
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final rr = k.isEven ? r : r * 0.48;
      final a = -math.pi / 2 + k * math.pi / 5;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.radial(
            c - Offset(r * 0.3, r * 0.35),
            r * 1.3,
            [const Color(0xFFFFF6B0), const Color(0xFFFFC83D), const Color(0xFFE08A00)],
            [0, 0.5, 1],
          ),
      );
    } else {
      canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.35));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.05
        ..strokeJoin = StrokeJoin.round
        ..color = filled ? const Color(0xFFB86A00) : Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.filled != filled;
}

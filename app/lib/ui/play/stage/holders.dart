import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/nova_theme.dart';
import 'choice_look.dart';

/// Paints one answer holder around its content: [HolderArt] draws what is
/// behind the answer's picture (the balloon, the board, the bubble) and,
/// for holders that wrap around it, what is in front (the basket's weave,
/// the bubble's shine). The picture itself always sits on a light face so
/// it stays easy to see.
class HolderArt extends StatelessWidget {
  const HolderArt({super.key, required this.look, required this.width, required this.child, this.glow});
  final ChoiceLook look;
  final double width;
  final Widget child;

  /// A soft ring of colour (green when right, gold for a hint).
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final h = look.holder;
    final size = Size(width, width * h.aspect);
    final face = Rect.fromLTRB(h.face.left * size.width, h.face.top * size.height, h.face.right * size.width, h.face.bottom * size.height);
    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _HolderPainter(look, back: true, glow: glow),
        foregroundPainter: _HolderPainter(look, back: false),
        child: Stack(
          children: [
            // Round holders keep what they carry inside their curve.
            Positioned.fromRect(
              rect: face,
              child: h == Holder.balloon || h == Holder.bubble ? ClipOval(child: Center(child: child)) : Center(child: child),
            ),
          ],
        ),
      ),
    );
  }

  /// The biggest square picture that fits the holder's face for [width].
  static double contentSize(Holder holder, double width) {
    final f = holder.face;
    return math.min(f.width * width, f.height * width * holder.aspect);
  }
}

class _HolderPainter extends CustomPainter {
  _HolderPainter(this.look, {required this.back, this.glow});
  final ChoiceLook look;
  final bool back;
  final Color? glow;

  static const _cream = Color(0xFFFFFBF2);
  static const _wood = Color(0xFFE9C48E);
  static const _woodDark = Color(0xFF9A6440);

  Color get _pale => Color.lerp(look.tint, Colors.white, 0.82)!;
  Color get _soft => Color.lerp(look.tint, Colors.white, 0.6)!;

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  void _shadow(Canvas canvas, Size s, {double y = 0.98, double w = 0.7}) => canvas.drawOval(
        Rect.fromCenter(center: Offset(s.width / 2, s.height * y), width: s.width * w, height: s.width * 0.1),
        Paint()
          ..color = const Color(0x2E2E1A5C)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

  void _glow(Canvas canvas, Path shape) {
    final g = glow;
    if (g == null) return;
    canvas.drawPath(shape, Paint()
      ..color = g.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(shape, _stroke(g, 5));
  }

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    switch (look.holder) {
      case Holder.card:
        final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(w * 0.2));
        if (back) {
          canvas.drawRRect(r.shift(const Offset(0, 6)), _fill(const Color(0x222A1640)));
          canvas.drawRRect(r, _fill(Colors.white));
          canvas.drawRRect(r.deflate(1.5), _stroke(_soft, 3));
          _glow(canvas, Path()..addRRect(r));
        }
      case Holder.basket:
        final body = Path()
          ..moveTo(w * 0.04, h * 0.58)
          ..lineTo(w * 0.96, h * 0.58)
          ..lineTo(w * 0.84, h * 0.96)
          ..quadraticBezierTo(w * 0.5, h * 1.0, w * 0.16, h * 0.96)
          ..close();
        final dish = Rect.fromLTRB(w * 0.08, h * 0.1, w * 0.92, h * 0.7);
        if (back) {
          _shadow(canvas, s);
          canvas.drawArc(Rect.fromLTRB(w * 0.16, -h * 0.03, w * 0.84, h * 1.0), math.pi, math.pi, false, _stroke(_woodDark, w * 0.06));
          canvas.drawArc(Rect.fromLTRB(w * 0.16, -h * 0.03, w * 0.84, h * 1.0), math.pi, math.pi, false, _stroke(_wood, w * 0.025));
          canvas.drawOval(dish, _fill(_cream));
          canvas.drawOval(dish.deflate(2), _stroke(_pale, 3));
          _glow(canvas, Path()..addOval(dish)..addPath(body, Offset.zero));
        } else {
          canvas.drawPath(body, Paint()..shader = ui.Gradient.linear(Offset(0, h * 0.58), Offset(0, h), [_wood, shade(_wood, -0.18)]));
          canvas.save();
          canvas.clipPath(body);
          for (var i = 0; i < 9; i++) {
            final x = w * (0.02 + i * 0.12);
            canvas.drawLine(Offset(x, h * 0.58), Offset(x + w * 0.05, h), _stroke(shade(_wood, -0.28), 2));
          }
          for (var j = 0; j < 3; j++) {
            final y = h * (0.7 + j * 0.1);
            canvas.drawLine(Offset(0, y), Offset(w, y), _stroke(shade(_wood, 0.18), 2.4));
          }
          canvas.restore();
          final rim = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.01, h * 0.55, w * 0.99, h * 0.64), Radius.circular(h * 0.05));
          canvas.drawRRect(rim, _fill(shade(_wood, -0.12)));
          canvas.drawRRect(rim, _stroke(_woodDark, 2));
          // A ribbon in the place's colour.
          canvas.drawCircle(Offset(w * 0.5, h * 0.6), w * 0.05, _fill(look.tint));
        }
      case Holder.balloon:
        final ball = Rect.fromLTRB(w * 0.03, 0, w * 0.97, h * 0.76);
        if (back) {
          final string = Path()..moveTo(w * 0.5, h * 0.78);
          for (var i = 1; i <= 4; i++) {
            string.quadraticBezierTo(w * (i.isOdd ? 0.56 : 0.44), h * (0.78 + i * 0.05 - 0.025), w * 0.5, h * (0.78 + i * 0.055));
          }
          canvas.drawPath(string, _stroke(const Color(0xFF8A7BA8), 2));
          final knot = Path()
            ..moveTo(w * 0.5, h * 0.74)
            ..lineTo(w * 0.56, h * 0.8)
            ..lineTo(w * 0.44, h * 0.8)
            ..close();
          canvas.drawPath(knot, _fill(look.deep));
          canvas.drawOval(ball, Paint()..shader = ui.Gradient.radial(Offset(w * 0.36, h * 0.2), w * 0.8, [Colors.white, _pale, _soft], [0, 0.5, 1]));
          canvas.drawOval(ball.deflate(1.5), _stroke(look.tint, 4));
          _glow(canvas, Path()..addOval(ball));
        } else {
          canvas.drawOval(Rect.fromLTWH(w * 0.16, h * 0.06, w * 0.12, h * 0.1), _fill(Colors.white.withValues(alpha: 0.8)));
        }
      case Holder.bubble:
        final c = Offset(w / 2, h / 2);
        final r = w * 0.48;
        if (back) {
          canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.radial(c, r, [Colors.white.withValues(alpha: 0.95), Colors.white.withValues(alpha: 0.9), _soft.withValues(alpha: 0.9)], [0, 0.7, 1]));
          _glow(canvas, Path()..addOval(Rect.fromCircle(center: c, radius: r)));
        } else {
          canvas.drawCircle(
            c,
            r - 2,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..shader = ui.Gradient.sweep(c, const [Color(0xAA8FD3FF), Color(0xAAFFB3E6), Color(0xAAFFF0A0), Color(0xAA9BF0C8), Color(0xAA8FD3FF)]),
          );
          canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.8), math.pi * 1.1, math.pi * 0.35, false, _stroke(Colors.white, 5));
          canvas.drawCircle(c + Offset(r * 0.55, -r * 0.62), r * 0.07, _fill(Colors.white));
        }
      case Holder.lilyPad:
        final pad = Rect.fromLTRB(0, h * 0.62, w, h);
        final disc = Rect.fromCenter(center: Offset(w / 2, h * 0.37), width: w * 0.78, height: h * 0.72);
        if (back) {
          final notch = Path()
            ..addOval(pad)
            ..close();
          final cut = Path()
            ..moveTo(w / 2, pad.center.dy)
            ..lineTo(w * 0.62, h)
            ..lineTo(w * 0.72, h)
            ..close();
          canvas.drawPath(Path.combine(PathOperation.difference, notch, cut), Paint()..shader = ui.Gradient.linear(pad.topCenter, pad.bottomCenter, [const Color(0xFF7FD06A), const Color(0xFF3F9E4E)]));
          for (var i = 0; i < 8; i++) {
            final a = i * math.pi / 4;
            final p = disc.center + Offset(math.cos(a) * disc.width * 0.48, math.sin(a) * disc.height * 0.48);
            canvas.drawOval(Rect.fromCenter(center: p, width: w * 0.22, height: w * 0.22), _fill(const Color(0xFFFFC2DA)));
          }
          canvas.drawOval(disc, _fill(_cream));
          _glow(canvas, Path()..addOval(disc));
        }
      case Holder.signpost:
        final board = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.02, h * 0.02, w * 0.98, h * 0.76), Radius.circular(w * 0.1));
        if (back) {
          _shadow(canvas, s, w: 0.4);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.44, h * 0.6, w * 0.56, h * 0.99), Radius.circular(w * 0.03)), _fill(_woodDark));
          canvas.drawRRect(board.shift(const Offset(0, 4)), _fill(shade(_woodDark, -0.1)));
          canvas.drawRRect(board, _fill(_woodDark));
          final inner = board.deflate(w * 0.045);
          canvas.drawRRect(inner, Paint()..shader = ui.Gradient.linear(inner.outerRect.topLeft, inner.outerRect.bottomRight, [const Color(0xFFFFF4DE), const Color(0xFFF8E3BD)]));
          for (final x in [0.08, 0.92]) {
            canvas.drawCircle(Offset(w * x, h * 0.07), w * 0.022, _fill(shade(_woodDark, -0.2)));
          }
          _glow(canvas, Path()..addRRect(board));
        }
      case Holder.cloud:
        final puffs = [(0.5, 0.36, 0.34), (0.26, 0.5, 0.25), (0.74, 0.5, 0.25), (0.36, 0.72, 0.24), (0.64, 0.72, 0.24), (0.5, 0.62, 0.32)];
        final shape = Path();
        for (final (x, y, r) in puffs) {
          shape.addOval(Rect.fromCircle(center: Offset(w * x, h * y), radius: w * r));
        }
        if (back) {
          canvas.drawPath(shape.shift(const Offset(0, 5)), _fill(Color.lerp(look.tint, Colors.white, 0.55)!.withValues(alpha: 0.8)));
          canvas.drawPath(shape, _fill(Colors.white));
          _glow(canvas, shape);
        }
      case Holder.carriage:
        final body = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.02, h * 0.03, w * 0.98, h * 0.8), Radius.circular(w * 0.12));
        final window = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.09, h * 0.09, w * 0.91, h * 0.72), Radius.circular(w * 0.08));
        if (back) {
          canvas.drawLine(Offset(0, h * 0.88), Offset(w, h * 0.88), _stroke(const Color(0xFF8A6A50), 4));
          canvas.drawRRect(body, Paint()..shader = ui.Gradient.linear(body.outerRect.topCenter, body.outerRect.bottomCenter, [shade(look.tint, 0.12), look.deep]));
          canvas.drawRRect(window, _fill(_cream));
          for (final x in [0.26, 0.74]) {
            final c = Offset(w * x, h * 0.86);
            canvas.drawCircle(c, w * 0.11, _fill(const Color(0xFF3D3552)));
            canvas.drawCircle(c, w * 0.045, _fill(const Color(0xFFFFD54A)));
          }
          _glow(canvas, Path()..addRRect(body));
        }
      case Holder.crystal:
        final gem = Path()
          ..moveTo(w * 0.5, 0)
          ..lineTo(w * 0.98, h * 0.26)
          ..lineTo(w * 0.98, h * 0.7)
          ..lineTo(w * 0.5, h * 0.98)
          ..lineTo(w * 0.02, h * 0.7)
          ..lineTo(w * 0.02, h * 0.26)
          ..close();
        if (back) {
          canvas.drawPath(gem, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(w, h), [Colors.white, _pale, _soft]));
          canvas.drawPath(gem, _stroke(look.tint, 4));
          _glow(canvas, gem);
        } else {
          final facet = _stroke(Colors.white.withValues(alpha: 0.8), 2);
          canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.2, h * 0.14), facet);
          canvas.drawLine(Offset(w * 0.08, h * 0.3), Offset(w * 0.08, h * 0.5), facet);
        }
    }
  }

  @override
  bool shouldRepaint(_HolderPainter old) => old.look != look || old.back != back || old.glow != glow;
}

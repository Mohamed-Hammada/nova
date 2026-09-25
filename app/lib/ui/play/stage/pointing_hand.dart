import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/tokens.dart';

/// The companion's helping hand: a big friendly glove that taps on the
/// thing to look at. It shows how (a demonstration), points out the answer
/// after two tries, or appears when the child asks for a hint. It never
/// taps for the child: the child still makes the choice.
class PointingHand extends StatefulWidget {
  const PointingHand({super.key, this.size = 72, this.color = const Color(0xFFFFD9B0)});
  final double size;
  final Color color;

  @override
  State<PointingHand> createState() => _PointingHandState();
}

class _PointingHandState extends State<PointingHand> with SingleTickerProviderStateMixin {
  late final AnimationController _tap = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NovaMotion.reduced(context)) {
      _tap.stop();
      _tap.value = 0.5;
    } else if (!_tap.isAnimating) {
      _tap.repeat();
    }
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _tap,
          builder: (context, child) {
            // Down-and-up taps with a little squash at the bottom.
            final t = _tap.value;
            final dip = math.max(0.0, math.sin(t * math.pi * 2));
            return Transform.translate(
              offset: Offset(-dip * widget.size * 0.1, -dip * widget.size * 0.16),
              child: Transform.scale(scale: 1 - dip * 0.06, child: child),
            );
          },
          child: SizedBox.square(dimension: widget.size, child: CustomPaint(painter: _HandPainter(widget.color))),
        ),
      );
}

/// A cartoon hand pointing up and to the start side, with a soft outline so
/// it reads on any background.
class _HandPainter extends CustomPainter {
  _HandPainter(this.skin);
  final Color skin;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    canvas.save();
    // Tilted so the fingertip leads toward the top-left corner.
    canvas.translate(w / 2, w / 2);
    canvas.rotate(-0.55);
    canvas.translate(-w / 2, -w / 2);
    final outline = Paint()
      ..color = const Color(0xFF6B3F2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = skin;
    final finger = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.4, w * 0.02, w * 0.2, w * 0.52), Radius.circular(w * 0.1));
    final palm = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, w * 0.4, w * 0.56, w * 0.48), Radius.circular(w * 0.2));
    final thumb = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, w * 0.46, w * 0.22, w * 0.16), Radius.circular(w * 0.08));
    final hand = Path()
      ..addRRect(finger)
      ..addRRect(palm)
      ..addRRect(thumb);
    canvas.drawPath(hand.shift(Offset(0, w * 0.04)), Paint()..color = const Color(0x33000000));
    canvas.drawPath(hand, outline);
    canvas.drawRRect(finger, fill);
    canvas.drawRRect(palm, fill);
    canvas.drawRRect(thumb, fill);
    // Knuckle lines of the folded fingers.
    final line = Paint()
      ..color = const Color(0x886B3F2A)
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    for (final x in [0.62, 0.72]) {
      canvas.drawLine(Offset(w * x, w * 0.5), Offset(w * x, w * 0.64), line);
    }
    // A white cuff.
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.24, w * 0.8, w * 0.52, w * 0.16), Radius.circular(w * 0.06)), Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.24, w * 0.8, w * 0.52, w * 0.16), Radius.circular(w * 0.06)), outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HandPainter old) => old.skin != skin;
}

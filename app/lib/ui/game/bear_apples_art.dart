import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';

/// Illustrations for game.math.bear-apples, drawn in code: no image assets to
/// ship, crisp at every size and pixel density, and identical on every
/// platform. All of them are decorative -- the widgets that use them supply
/// the semantics.

enum Fruit { apple, pear }

class FruitArt extends StatelessWidget {
  const FruitArt({super.key, required this.fruit, this.size = NovaSize.gameItem});
  final Fruit fruit;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: fruit == Fruit.apple ? const _ApplePainter() : const _PearPainter()),
      );
}

class _ApplePainter extends CustomPainter {
  const _ApplePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(w * 0.5, h * 0.30)
      ..cubicTo(w * 0.30, h * 0.16, w * 0.06, h * 0.26, w * 0.08, h * 0.54)
      ..cubicTo(w * 0.10, h * 0.80, w * 0.30, h * 0.96, w * 0.5, h * 0.88)
      ..cubicTo(w * 0.70, h * 0.96, w * 0.90, h * 0.80, w * 0.92, h * 0.54)
      ..cubicTo(w * 0.94, h * 0.26, w * 0.70, h * 0.16, w * 0.5, h * 0.30)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.35),
          radius: 0.95,
          colors: [NovaPalette.apple, NovaPalette.appleShade],
        ).createShader(Offset.zero & size),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.32, h * 0.44), width: w * 0.14, height: h * 0.22),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    _stemAndLeaf(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PearPainter extends CustomPainter {
  const _PearPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(w * 0.5, h * 0.24)
      ..cubicTo(w * 0.36, h * 0.24, w * 0.34, h * 0.42, w * 0.30, h * 0.50)
      ..cubicTo(w * 0.14, h * 0.62, w * 0.14, h * 0.94, w * 0.5, h * 0.94)
      ..cubicTo(w * 0.86, h * 0.94, w * 0.86, h * 0.62, w * 0.70, h * 0.50)
      ..cubicTo(w * 0.66, h * 0.42, w * 0.64, h * 0.24, w * 0.5, h * 0.24)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, 0.1),
          radius: 0.9,
          colors: [NovaPalette.pear, NovaPalette.pearShade],
        ).createShader(Offset.zero & size),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.38, h * 0.66), width: w * 0.10, height: h * 0.18),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    _stemAndLeaf(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _stemAndLeaf(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  canvas.drawLine(
    Offset(w * 0.5, h * 0.30),
    Offset(w * 0.54, h * 0.10),
    Paint()
      ..color = NovaPalette.stem
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round,
  );
  canvas.save();
  canvas.translate(w * 0.64, h * 0.14);
  canvas.rotate(-math.pi / 7);
  canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.24, height: h * 0.12), Paint()..color = NovaPalette.leaf);
  canvas.restore();
}

/// The plate, drawn as an ellipse; [highlighted] while an item is dragged
/// over it, so the child can see where a drop will land.
class PlateArt extends StatelessWidget {
  const PlateArt({super.key, required this.highlighted, required this.child});
  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rim = highlighted ? Theme.of(context).colorScheme.primary : NovaPalette.plateRim;
    return AnimatedContainer(
      duration: NovaMotion.of(context, NovaMotion.short),
      curve: NovaMotion.curve,
      decoration: ShapeDecoration(
        color: NovaPalette.plate,
        shape: StadiumBorder(side: BorderSide(color: rim, width: highlighted ? 6 : 4)),
        shadows: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: NovaSpace.lg, vertical: NovaSpace.md),
      child: child,
    );
  }
}

enum BearMood { waiting, happy, thinking }

class BearArt extends StatelessWidget {
  const BearArt({super.key, required this.mood, this.size = 120});
  final BearMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    // A small hop when the bear is happy; still when motion is reduced.
    return AnimatedScale(
      scale: mood == BearMood.happy && !NovaMotion.reduced(context) ? 1.08 : 1,
      duration: NovaMotion.of(context, NovaMotion.medium),
      curve: NovaMotion.emphasized,
      child: SizedBox.square(dimension: size, child: CustomPaint(painter: _BearPainter(mood))),
    );
  }
}

class _BearPainter extends CustomPainter {
  const _BearPainter(this.mood);
  final BearMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fur = Paint()..color = NovaPalette.bearFur;
    final shade = Paint()..color = NovaPalette.bearFurShade;
    final muzzle = Paint()..color = NovaPalette.bearMuzzle;
    final ink = Paint()..color = NovaPalette.ink;

    for (final x in [0.22, 0.78]) {
      canvas.drawCircle(Offset(w * x, h * 0.24), w * 0.16, fur);
      canvas.drawCircle(Offset(w * x, h * 0.24), w * 0.08, shade);
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.56), width: w * 0.84, height: h * 0.76), fur);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.70), width: w * 0.42, height: h * 0.32), muzzle);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.62), width: w * 0.14, height: h * 0.09), ink);

    final eyeY = h * 0.46;
    if (mood == BearMood.happy) {
      final stroke = Paint()
        ..color = NovaPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round;
      for (final x in [0.34, 0.66]) {
        canvas.drawArc(Rect.fromCenter(center: Offset(w * x, eyeY + h * 0.02), width: w * 0.12, height: h * 0.10), math.pi, math.pi, false, stroke);
      }
    } else {
      for (final x in [0.34, 0.66]) {
        canvas.drawCircle(Offset(w * x, eyeY), w * 0.045, ink);
        canvas.drawCircle(Offset(w * x + w * 0.015, eyeY - h * 0.015), w * 0.014, Paint()..color = Colors.white);
      }
    }

    final mouth = Paint()
      ..color = NovaPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    switch (mood) {
      case BearMood.happy:
        canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.5, h * 0.70), width: w * 0.24, height: h * 0.16), 0.15, math.pi - 0.3, false, mouth);
      case BearMood.waiting:
        canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.5, h * 0.70), width: w * 0.14, height: h * 0.08), 0.3, math.pi - 0.6, false, mouth);
      case BearMood.thinking:
        canvas.drawLine(Offset(w * 0.44, h * 0.75), Offset(w * 0.56, h * 0.74), mouth);
    }
  }

  @override
  bool shouldRepaint(covariant _BearPainter oldDelegate) => oldDelegate.mood != mood;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';

import 'game_art.dart';

/// Reusable vector CustomPainters providing crisp, infinite-resolution,
/// deterministic rendering and reliable offline fallbacks.
class VectorArtPainters {
  const VectorArtPainters._();

  static CustomPainter characterPainter(String characterId, CharacterVisualState state) {
    switch (characterId.toLowerCase()) {
      case 'bunny':
      case 'rabbit':
      case 'pip':
        return BunnyVectorPainter(state);
      case 'bear':
      default:
        return BearVectorPainter(state);
    }
  }

  static CustomPainter objectPainter(String objectId) {
    if (objectId == 'apple') {
      return const AppleVectorPainter();
    } else if (objectId == 'pear') {
      return const PearVectorPainter();
    }
    return const AppleVectorPainter();
  }

  static CustomPainter environmentPainter(String environmentId) {
    if (environmentId.contains('branch')) {
      return const TreeBranchVectorPainter();
    }
    if (environmentId.contains('blanket')) {
      return const PicnicBlanketVectorPainter();
    }
    return const MeadowBackgroundVectorPainter();
  }

  static CustomPainter basketPainter({required bool highlighted, bool frontOnly = false}) {
    return BasketVectorPainter(highlighted: highlighted, frontOnly: frontOnly);
  }

  static CustomPainter feedbackPainter(String effectId) {
    if (effectId.contains('star')) {
      return const StarVectorPainter();
    }
    return const SparkleVectorPainter();
  }
}

class AppleVectorPainter extends CustomPainter {
  const AppleVectorPainter();

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

    // Stem and Leaf
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
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.24, height: h * 0.12),
      Paint()..color = NovaPalette.leaf,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PearVectorPainter extends CustomPainter {
  const PearVectorPainter();

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

    // Stem and Leaf
    canvas.drawLine(
      Offset(w * 0.5, h * 0.24),
      Offset(w * 0.54, h * 0.08),
      Paint()
        ..color = NovaPalette.stem
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );
    canvas.save();
    canvas.translate(w * 0.64, h * 0.12);
    canvas.rotate(-math.pi / 7);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.24, height: h * 0.12),
      Paint()..color = NovaPalette.leaf,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BearVectorPainter extends CustomPainter {
  const BearVectorPainter(this.state);
  final CharacterVisualState state;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fur = Paint()..color = NovaPalette.bearFur;
    final shade = Paint()..color = NovaPalette.bearFurShade;
    final muzzle = Paint()..color = NovaPalette.bearMuzzle;
    final ink = Paint()..color = NovaPalette.ink;

    // Ears
    for (final x in [0.22, 0.78]) {
      canvas.drawCircle(Offset(w * x, h * 0.24), w * 0.16, fur);
      canvas.drawCircle(Offset(w * x, h * 0.24), w * 0.08, shade);
    }

    // Head and Muzzle
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.56), width: w * 0.84, height: h * 0.76), fur);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.70), width: w * 0.42, height: h * 0.32), muzzle);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.62), width: w * 0.14, height: h * 0.09), ink);

    // Eyes
    final eyeY = h * 0.46;
    if (state == CharacterVisualState.happy || state == CharacterVisualState.celebrate) {
      final stroke = Paint()
        ..color = NovaPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round;
      for (final x in [0.34, 0.66]) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * x, eyeY + h * 0.02), width: w * 0.12, height: h * 0.10),
          math.pi,
          math.pi,
          false,
          stroke,
        );
      }
    } else {
      for (final x in [0.34, 0.66]) {
        canvas.drawCircle(Offset(w * x, eyeY), w * 0.045, ink);
        canvas.drawCircle(Offset(w * x + w * 0.015, eyeY - h * 0.015), w * 0.014, Paint()..color = Colors.white);
      }
    }

    // Mouth
    final mouth = Paint()
      ..color = NovaPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;

    switch (state) {
      case CharacterVisualState.happy:
      case CharacterVisualState.celebrate:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.5, h * 0.70), width: w * 0.24, height: h * 0.16),
          0.15,
          math.pi - 0.3,
          false,
          mouth,
        );
      case CharacterVisualState.encourage:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.5, h * 0.69), width: w * 0.20, height: h * 0.12),
          0.2,
          math.pi - 0.4,
          false,
          mouth,
        );
      case CharacterVisualState.idle:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.5, h * 0.70), width: w * 0.14, height: h * 0.08),
          0.3,
          math.pi - 0.6,
          false,
          mouth,
        );
      case CharacterVisualState.thinking:
        canvas.drawLine(Offset(w * 0.44, h * 0.75), Offset(w * 0.56, h * 0.74), mouth);
      case CharacterVisualState.confused:
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.72), width: w * 0.08, height: h * 0.08), mouth);
    }
  }

  @override
  bool shouldRepaint(covariant BearVectorPainter oldDelegate) => oldDelegate.state != state;
}

class BunnyVectorPainter extends CustomPainter {
  const BunnyVectorPainter(this.state);
  final CharacterVisualState state;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fur = Paint()..color = const Color(0xFFFAF7F2);
    final furShade = Paint()..color = const Color(0xFFE8E1DA);
    final pink = Paint()..color = const Color(0xFFFFB6C1);
    final pinkNose = Paint()..color = const Color(0xFFF58CA0);
    final ink = Paint()..color = NovaPalette.ink;

    // Ears
    final earAngles = switch (state) {
      CharacterVisualState.happy || CharacterVisualState.celebrate => [-0.25, 0.25],
      CharacterVisualState.thinking => [-0.35, 0.05],
      CharacterVisualState.confused => [-0.38, 0.02],
      _ => [-0.18, 0.18],
    };

    for (int i = 0; i < 2; i++) {
      final base = Offset(w * (i == 0 ? 0.38 : 0.62), h * 0.35);
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(earAngles[i]);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -h * 0.22), width: w * 0.18, height: h * 0.42), fur);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -h * 0.22), width: w * 0.10, height: h * 0.32), pink);
      canvas.restore();
    }

    // Head
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.58), width: w * 0.75, height: h * 0.60), fur);
    canvas.drawCircle(Offset(w * 0.22, h * 0.64), w * 0.14, furShade);
    canvas.drawCircle(Offset(w * 0.78, h * 0.64), w * 0.14, furShade);

    // Eyes
    final eyeY = h * 0.52;
    if (state == CharacterVisualState.happy || state == CharacterVisualState.celebrate) {
      final stroke = Paint()
        ..color = NovaPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round;
      for (final x in [0.36, 0.64]) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * x, eyeY + h * 0.01), width: w * 0.11, height: h * 0.09),
          math.pi,
          math.pi,
          false,
          stroke,
        );
      }
    } else {
      for (final x in [0.36, 0.64]) {
        final radius = (state == CharacterVisualState.confused && x == 0.64) ? w * 0.05 : w * 0.042;
        canvas.drawCircle(Offset(w * x, eyeY), radius, ink);
        canvas.drawCircle(Offset(w * x + w * 0.012, eyeY - h * 0.012), w * 0.015, Paint()..color = Colors.white);
      }
    }

    // Nose
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.63), width: w * 0.10, height: h * 0.07), pinkNose);

    // Mouth
    final mouth = Paint()
      ..color = NovaPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    if (state == CharacterVisualState.confused) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.72), width: w * 0.06, height: h * 0.07), mouth);
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.70), width: w * 0.16, height: h * 0.09),
        0.2,
        math.pi - 0.4,
        false,
        mouth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BunnyVectorPainter oldDelegate) => oldDelegate.state != state;
}

class BasketVectorPainter extends CustomPainter {
  const BasketVectorPainter({required this.highlighted, this.frontOnly = false});
  final bool highlighted;
  final bool frontOnly;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rimColor = highlighted ? const Color(0xFFE28743) : const Color(0xFFC47B3A);

    if (!frontOnly) {
      // Handle
      final handlePaint = Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.48), width: w * 0.76, height: h * 0.65),
        math.pi,
        math.pi,
        false,
        handlePaint,
      );

      // Basket Back / Interior
      final interior = Path()
        ..addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.48), width: w * 0.88, height: h * 0.36));
      canvas.drawPath(interior, Paint()..color = const Color(0xFF5E3918));
    }

    // Basket Tub / Wicker Front
    final tub = Path()
      ..moveTo(w * 0.08, h * 0.48)
      ..cubicTo(w * 0.10, h * 0.82, w * 0.28, h * 0.94, w * 0.50, h * 0.94)
      ..cubicTo(w * 0.72, h * 0.94, w * 0.90, h * 0.82, w * 0.92, h * 0.48)
      ..close();

    canvas.drawPath(
      tub,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD4924B), Color(0xFF9E6226)],
        ).createShader(Offset.zero & size),
    );

    // Rim
    final rim = Path()
      ..addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.48), width: w * 0.90, height: h * 0.16));
    canvas.drawPath(rim, Paint()..color = rimColor);
  }

  @override
  bool shouldRepaint(covariant BasketVectorPainter oldDelegate) =>
      oldDelegate.highlighted != highlighted || oldDelegate.frontOnly != frontOnly;
}

class StarVectorPainter extends CustomPainter {
  const StarVectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w * 0.5, cy = h * 0.5;
    final outerR = w * 0.46;
    final innerR = w * 0.22;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = -math.pi / 2 + i * (math.pi / 5);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFEA79), Color(0xFFFFB300)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SparkleVectorPainter extends CustomPainter {
  const SparkleVectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w * 0.5, cy = h * 0.5;
    final path = Path()
      ..moveTo(cx, h * 0.05)
      ..cubicTo(cx, cy, cx, cy, w * 0.95, cy)
      ..cubicTo(cx, cy, cx, cy, cx, h * 0.95)
      ..cubicTo(cx, cy, cx, cy, w * 0.05, cy)
      ..cubicTo(cx, cy, cx, cy, cx, h * 0.05)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD54F));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TreeBranchVectorPainter extends CustomPainter {
  const TreeBranchVectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Branch line
    canvas.drawLine(
      Offset(0, h * 0.2),
      Offset(w * 0.9, h * 0.5),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = h * 0.12
        ..strokeCap = StrokeCap.round,
    );
    // Green leaves
    final leafPaint = Paint()..color = const Color(0xFF66BB6A);
    for (final x in [0.2, 0.4, 0.6, 0.8]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * x, h * (0.2 + x * 0.3)), width: w * 0.16, height: h * 0.35),
        leafPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PicnicBlanketVectorPainter extends CustomPainter {
  const PicnicBlanketVectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(NovaRadius.lg));
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFE57373));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MeadowBackgroundVectorPainter extends CustomPainter {
  const MeadowBackgroundVectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB3E5FC), Color(0xFFE8F5E9)],
        ).createShader(Offset.zero & size),
    );
    // Meadow
    final hill = Path()
      ..moveTo(0, h * 0.55)
      ..cubicTo(w * 0.3, h * 0.48, w * 0.7, h * 0.58, w, h * 0.50)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF81C784));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

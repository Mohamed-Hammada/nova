import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nova_app/core/content/models.dart';

import '../l10n.dart';
import '../scene/story_scene.dart';
import '../theme/nova_theme.dart';

/// The places of the Nova world. Every activity lives in one of them, so a
/// child explores places rather than scrolling a list of exercises.
///
/// Presentation only: which activities a child sees still comes from each
/// game's age range and language in the curriculum spec, and what a game
/// teaches is still its skills there.
enum ActivityCategory {
  numbers(
    color: Color(0xFFFF9A2E),
    deep: Color(0xFFD9670B),
    scene: SceneTheme(
      skyTop: Color(0xFF74C8FF),
      skyBottom: Color(0xFFFFF0CF),
      hillFar: Color(0xFFB5DDA0),
      hillMid: Color(0xFF94CF6A),
      ground: Color(0xFF86C95A),
      groundLight: Color(0xFFB8E27A),
      foliage: Color(0xFF55AE4B),
      accent: Color(0xFFFF9A2E),
      props: [SceneProp.fruitTrees, SceneProp.flowers],
    ),
  ),
  language(
    color: Color(0xFF3FAE6A),
    deep: Color(0xFF257A45),
    scene: SceneTheme(
      skyTop: Color(0xFF7FCBEA),
      skyBottom: Color(0xFFE7F7E8),
      hillFar: Color(0xFF9CCFA8),
      hillMid: Color(0xFF5DAA64),
      ground: Color(0xFF6DB85A),
      groundLight: Color(0xFF9ED27A),
      foliage: Color(0xFF3C8F4A),
      accent: Color(0xFFF2508B),
      props: [SceneProp.pines, SceneProp.mushrooms],
    ),
  ),
  sounds(
    color: Color(0xFF8E6CF0),
    deep: Color(0xFF5B3CC4),
    scene: SceneTheme(
      skyTop: Color(0xFFA78BFA),
      skyBottom: Color(0xFFFFE3F1),
      hillFar: Color(0xFFC7B6F2),
      hillMid: Color(0xFF9FD08A),
      ground: Color(0xFF8CCB6E),
      groundLight: Color(0xFFBFE39A),
      foliage: Color(0xFF6FB463),
      accent: Color(0xFF7A5AE0),
      props: [SceneProp.notes, SceneProp.flowers],
      sun: Color(0xFFFFE6F3),
    ),
  ),
  feelings(
    color: Color(0xFFF2508B),
    deep: Color(0xFFC22E65),
    scene: SceneTheme(
      skyTop: Color(0xFFFFB3CF),
      skyBottom: Color(0xFFFFF1E4),
      hillFar: Color(0xFFBFE3C8),
      hillMid: Color(0xFF9AD68A),
      ground: Color(0xFF8ACD74),
      groundLight: Color(0xFFBDE69C),
      foliage: Color(0xFF69B964),
      accent: Color(0xFFF2508B),
      props: [SceneProp.hearts, SceneProp.flowers],
    ),
  ),
  memory(
    color: Color(0xFF2F9FE0),
    deep: Color(0xFF1D6FAA),
    scene: SceneTheme(
      skyTop: Color(0xFF5CB8F2),
      skyBottom: Color(0xFFE2F5FF),
      hillFar: Color(0xFFA8D8C8),
      hillMid: Color(0xFFF2DDA8),
      ground: Color(0xFFF4DEA6),
      groundLight: Color(0xFFFFF0C8),
      foliage: Color(0xFF4FB38A),
      accent: Color(0xFF2F9FE0),
      props: [SceneProp.shells, SceneProp.roundTrees],
      water: Color(0xFF4FB4EC),
    ),
  ),
  discovery(
    color: Color(0xFF14A9A0),
    deep: Color(0xFF0B7A73),
    scene: SceneTheme(
      skyTop: Color(0xFF6BC9E8),
      skyBottom: Color(0xFFFFF4D6),
      hillFar: Color(0xFFC6D9A6),
      hillMid: Color(0xFFE2C77F),
      ground: Color(0xFFA8D06A),
      groundLight: Color(0xFFD2E79A),
      foliage: Color(0xFF5CA95A),
      accent: Color(0xFF14A9A0),
      props: [SceneProp.crystals, SceneProp.roundTrees],
    ),
  ),
  movement(
    color: Color(0xFF28B8D8),
    deep: Color(0xFF12839E),
    scene: SceneTheme(
      skyTop: Color(0xFF63C3FF),
      skyBottom: Color(0xFFE0F7FF),
      hillFar: Color(0xFFA7DEC0),
      hillMid: Color(0xFF7FCB7A),
      ground: Color(0xFF78C466),
      groundLight: Color(0xFFA9DD8A),
      foliage: Color(0xFF47A55A),
      accent: Color(0xFF28B8D8),
      props: [SceneProp.lilyPads, SceneProp.flowers],
      water: Color(0xFF5CC8E8),
    ),
  );

  const ActivityCategory({required this.color, required this.deep, required this.scene});

  final Color color;
  final Color deep;
  final SceneTheme scene;

  String title(AppLocalizations l10n) => switch (this) {
        numbers => l10n.catNumbers,
        language => l10n.catLanguage,
        sounds => l10n.catSounds,
        feelings => l10n.catFeelings,
        memory => l10n.catMemory,
        discovery => l10n.catDiscovery,
        movement => l10n.catMovement,
      };

  String tagline(AppLocalizations l10n) => switch (this) {
        numbers => l10n.catNumbersTag,
        language => l10n.catLanguageTag,
        sounds => l10n.catSoundsTag,
        feelings => l10n.catFeelingsTag,
        memory => l10n.catMemoryTag,
        discovery => l10n.catDiscoveryTag,
        movement => l10n.catMovementTag,
      };

  /// The place a curriculum stage is set in (the spec's stage `place`).
  static ActivityCategory fromPlace(String place) => ActivityCategory.values.firstWhere((c) => c.name == place, orElse: () => numbers);

  /// Which place an activity belongs to, from its id and mechanic.
  static ActivityCategory of(Game game) {
    final id = game.id;
    if (id.startsWith('game.math.')) return numbers;
    if (id.startsWith('game.sel.')) return feelings;
    if (id.startsWith('game.memory.')) return memory;
    if (id.startsWith('game.lit.')) return _soundMechanics.contains(game.mechanicId) ? sounds : language;
    if (game.mechanicId == 'go-no-go') return movement;
    return discovery;
  }

  static const _soundMechanics = {'segment-sounds', 'rhyme-select', 'sound-match', 'blend-sounds'};
}

/// The landmark that marks a place: a chunky, softly lit object a child can
/// recognise without reading -- number blocks, a storybook, a drum, a
/// heart, memory cards, a magnifying glass, a leaping fish.
class CategoryLandmark extends StatelessWidget {
  const CategoryLandmark({super.key, required this.category, this.size = 96});
  final ActivityCategory category;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        // Number blocks show the digits the child reads (Eastern Arabic in Arabic).
        child: CustomPaint(painter: _LandmarkPainter(category, arabicDigits: Localizations.maybeLocaleOf(context)?.languageCode == 'ar')),
      );
}

class _LandmarkPainter extends CustomPainter {
  _LandmarkPainter(this.c, {this.arabicDigits = false});
  final ActivityCategory c;
  final bool arabicDigits;

  String _d(int n) => arabicDigits ? '٠١٢٣٤٥٦٧٨٩'[n] : '$n';

  Paint _lit(Rect r, Color base) => Paint()
    ..shader = ui.Gradient.radial(r.topLeft + Offset(r.width * 0.35, r.height * 0.3), r.longestSide * 0.9, [shade(base, 0.35), base, shade(base, -0.25)], [0, 0.5, 1]);

  void _shadow(Canvas canvas, Size s) => canvas.drawOval(
        Rect.fromCenter(center: Offset(s.width / 2, s.height * 0.92), width: s.width * 0.7, height: s.height * 0.1),
        Paint()
          ..color = const Color(0x332E1A5C)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

  void _block(Canvas canvas, Rect r, Color color, String digit) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.22));
    canvas.drawRRect(rr.shift(Offset(0, r.height * 0.08)), Paint()..color = shade(color, -0.35));
    canvas.drawRRect(rr, _lit(r, color));
    final tp = TextPainter(
      text: TextSpan(text: digit, style: TextStyle(fontSize: r.height * 0.62, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'NotoSans', fontFamilyFallback: const ['NotoSansArabic'])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    _shadow(canvas, s);
    switch (c) {
      case ActivityCategory.numbers:
        _block(canvas, Rect.fromLTWH(w * 0.08, h * 0.5, w * 0.4, h * 0.36), const Color(0xFFFF7A59), _d(1));
        _block(canvas, Rect.fromLTWH(w * 0.52, h * 0.5, w * 0.4, h * 0.36), const Color(0xFF3C8DF2), _d(2));
        _block(canvas, Rect.fromLTWH(w * 0.3, h * 0.1, w * 0.4, h * 0.36), const Color(0xFFFFB02E), _d(3));
      case ActivityCategory.language:
        final left = Path()
          ..moveTo(w * 0.5, h * 0.3)
          ..quadraticBezierTo(w * 0.3, h * 0.2, w * 0.06, h * 0.26)
          ..lineTo(w * 0.06, h * 0.8)
          ..quadraticBezierTo(w * 0.3, h * 0.74, w * 0.5, h * 0.84)
          ..close();
        final right = Path()
          ..moveTo(w * 0.5, h * 0.3)
          ..quadraticBezierTo(w * 0.7, h * 0.2, w * 0.94, h * 0.26)
          ..lineTo(w * 0.94, h * 0.8)
          ..quadraticBezierTo(w * 0.7, h * 0.74, w * 0.5, h * 0.84)
          ..close();
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.03, h * 0.3, w * 0.97, h * 0.9), Radius.circular(w * 0.08)), Paint()..color = const Color(0xFF3FAE6A));
        canvas.drawPath(left, Paint()..color = const Color(0xFFFFFBF2));
        canvas.drawPath(right, Paint()..color = const Color(0xFFFFF3DD));
        for (var i = 0; i < 4; i++) {
          final y = h * (0.38 + i * 0.1);
          final line = Paint()
            ..color = const Color(0xFFD9C8A8)
            ..strokeWidth = h * 0.025
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(w * 0.14, y), Offset(w * 0.42, y), line);
          canvas.drawLine(Offset(w * 0.58, y), Offset(w * 0.86, y), line);
        }
        _sparkle(canvas, Offset(w * 0.5, h * 0.14), w * 0.08, const Color(0xFFFFD84D));
      case ActivityCategory.sounds:
        final body = Rect.fromLTWH(w * 0.14, h * 0.4, w * 0.72, h * 0.44);
        canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(w * 0.1)), _lit(body, const Color(0xFF8E6CF0)));
        for (var i = 0; i < 5; i++) {
          final x = body.left + body.width * (0.1 + i * 0.2);
          canvas.drawLine(Offset(x, body.top + 6), Offset(x + body.width * 0.1, body.bottom - 6), Paint()..color = const Color(0xFFFFD84D)..strokeWidth = w * 0.025);
        }
        final skin = Rect.fromLTWH(w * 0.14, h * 0.3, w * 0.72, h * 0.2);
        canvas.drawOval(skin, Paint()..color = const Color(0xFFFFF6E6));
        canvas.drawOval(skin, Paint()..color = const Color(0xFFD9C3A8)..style = PaintingStyle.stroke..strokeWidth = w * 0.02);
        for (final (x, a) in [(0.24, -0.6), (0.76, 0.6)]) {
          canvas.save();
          canvas.translate(w * x, h * 0.24);
          canvas.rotate(a);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w * 0.05, height: h * 0.34), Radius.circular(w)), Paint()..color = const Color(0xFFB9825A));
          canvas.drawCircle(Offset(0, -h * 0.17), w * 0.055, Paint()..color = const Color(0xFFFF7A59));
          canvas.restore();
        }
      case ActivityCategory.feelings:
        final heart = Path()
          ..moveTo(w * 0.5, h * 0.88)
          ..cubicTo(w * -0.05, h * 0.52, w * 0.12, h * 0.06, w * 0.5, h * 0.3)
          ..cubicTo(w * 0.88, h * 0.06, w * 1.05, h * 0.52, w * 0.5, h * 0.88)
          ..close();
        canvas.drawPath(heart, _lit(Rect.fromLTWH(0, h * 0.1, w, h * 0.8), const Color(0xFFF2508B)));
        final eye = Paint()..color = const Color(0xFF3A1C24);
        canvas.drawCircle(Offset(w * 0.38, h * 0.48), w * 0.045, eye);
        canvas.drawCircle(Offset(w * 0.62, h * 0.48), w * 0.045, eye);
        canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.5, h * 0.56), width: w * 0.2, height: h * 0.14), 0.2, math.pi - 0.4, false, eye..style = PaintingStyle.stroke..strokeWidth = w * 0.03..strokeCap = StrokeCap.round);
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.28, h * 0.58), width: w * 0.1, height: h * 0.06), Paint()..color = const Color(0x66FFFFFF));
      case ActivityCategory.memory:
        for (final (dx, a, face) in [(-0.14, -0.2, false), (0.14, 0.18, true)]) {
          canvas.save();
          canvas.translate(w * (0.5 + dx), h * 0.52);
          canvas.rotate(a);
          final r = Rect.fromCenter(center: Offset.zero, width: w * 0.46, height: h * 0.62);
          canvas.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(0, 4)), Radius.circular(w * 0.08)), Paint()..color = const Color(0x332E1A5C));
          canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(w * 0.08)), face ? (Paint()..color = Colors.white) : _lit(r, const Color(0xFF2F9FE0)));
          if (face) {
            _sparkle(canvas, Offset.zero, w * 0.14, const Color(0xFFFFC53D));
          } else {
            canvas.drawCircle(Offset.zero, w * 0.08, Paint()..color = Colors.white.withValues(alpha: 0.6));
          }
          canvas.restore();
        }
      case ActivityCategory.discovery:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.56, w * 0.26, w * 0.26), Radius.circular(w * 0.05)), Paint()..color = const Color(0xFFFF7A59));
        canvas.drawCircle(Offset(w * 0.7, h * 0.72), w * 0.13, Paint()..color = const Color(0xFFFFC53D));
        final lens = Offset(w * 0.46, h * 0.4);
        canvas.save();
        canvas.translate(lens.dx, lens.dy);
        canvas.rotate(0.7);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w * 0.05, w * 0.22, w * 0.1, w * 0.34), Radius.circular(w)), Paint()..color = const Color(0xFF7E4E33));
        canvas.restore();
        canvas.drawCircle(lens, w * 0.24, Paint()..color = const Color(0xFF14A9A0));
        canvas.drawCircle(lens, w * 0.18, Paint()..shader = ui.Gradient.radial(lens - Offset(w * 0.06, w * 0.06), w * 0.2, [const Color(0xFFE6FFFB), const Color(0xFFA6ECE6)]));
        canvas.drawArc(Rect.fromCircle(center: lens, radius: w * 0.12), 3.6, 1.2, false, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = w * 0.03..strokeCap = StrokeCap.round);
      case ActivityCategory.movement:
        canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.66, w * 0.84, h * 0.2), Paint()..color = const Color(0xFF5CC8E8));
        canvas.drawOval(Rect.fromLTWH(w * 0.2, h * 0.7, w * 0.6, h * 0.1), Paint()..color = Colors.white.withValues(alpha: 0.4));
        canvas.save();
        canvas.translate(w * 0.5, h * 0.42);
        canvas.rotate(-0.5);
        final fish = Rect.fromCenter(center: Offset.zero, width: w * 0.56, height: h * 0.32);
        canvas.drawOval(fish, _lit(fish, const Color(0xFFFF9A2E)));
        final tail = Path()
          ..moveTo(fish.right - w * 0.04, 0)
          ..lineTo(fish.right + w * 0.14, -h * 0.13)
          ..lineTo(fish.right + w * 0.14, h * 0.13)
          ..close();
        canvas.drawPath(tail, Paint()..color = const Color(0xFFFF7A59));
        canvas.drawCircle(Offset(fish.left + w * 0.12, -h * 0.03), w * 0.045, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(fish.left + w * 0.12, -h * 0.03), w * 0.022, Paint()..color = const Color(0xFF3A1C24));
        canvas.restore();
        for (final (x, y, r) in [(0.2, 0.3, 0.035), (0.14, 0.18, 0.025), (0.84, 0.28, 0.03)]) {
          canvas.drawCircle(Offset(w * x, h * y), w * r, Paint()..color = const Color(0xFF9FE6FF));
        }
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final p = Path();
    for (var k = 0; k < 8; k++) {
      final rr = k.isEven ? r : r * 0.4;
      final a = -math.pi / 2 + k * math.pi / 4;
      final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(p..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LandmarkPainter old) => old.c != c || old.arabicDigits != arabicDigits;
}

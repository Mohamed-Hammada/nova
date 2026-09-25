import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nova_app/core/play/lexicon.dart';
import 'package:nova_app/core/play/trials.dart';

import '../art/pic_art.dart';
import '../characters/character_rig.dart';
import '../characters/expressions.dart';
import '../theme/nova_theme.dart';

/// Numerals as children see them in each language: Eastern Arabic digits
/// (١٢٣) in Arabic mode, Western digits (123) in English.
String numeral(int n, String language) {
  if (language != 'ar') return '$n';
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return '$n'.split('').map((d) => digits[int.parse(d)]).join();
}

Color hueColor(Hue h) => switch (h) {
  Hue.red => const Color(0xFFF0413B),
  Hue.blue => const Color(0xFF3C8DF2),
  Hue.yellow => const Color(0xFFFFC83D),
  Hue.green => const Color(0xFF34C77B),
  Hue.purple => const Color(0xFF9B6BFF),
};

class VisualView extends StatelessWidget {
  const VisualView(this.visual, {super.key, required this.size, required this.language});
  final Visual visual;
  final double size;
  final String language;

  @override
  Widget build(BuildContext context) {
    final v = visual;
    return switch (v) {
      PicVisual() => PicArt(v.pic, size: size),
      GroupVisual() => _Group(v, size),
      NumeralVisual() => NumeralBadge(numeral(v.value, language), size: size),
      TextVisual() => _TextCard(v.text, size: size, letter: v.isLetter),
      TokenVisual() => TokenArt(v.token, size: size),
      PatternVisual() => FittedBox(fit: BoxFit.scaleDown, child: _Pattern(v, size)),
      TowersVisual() => FittedBox(fit: BoxFit.scaleDown, child: _Towers(v, size)),
      FaceVisual() => FaceArt(v.who, v.emotion, size: size),
      SceneVisual() => _Scene(v, size),
    };
  }
}

class NumeralBadge extends StatelessWidget {
  const NumeralBadge(this.text, {super.key, required this.size});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(center: Alignment(-0.35, -0.4), colors: [Color(0xFFFFF4B8), Color(0xFFFFC83D), Color(0xFFE08A00)], stops: [0, 0.5, 1]),
      boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 5))],
      border: Border.all(color: Colors.white, width: size * 0.04),
    ),
    child: FittedBox(
      child: Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: Text(text, style: novaText(size * 0.5, weight: 800, color: const Color(0xFF7A3E00))),
      ),
    ),
  );
}

class _TextCard extends StatelessWidget {
  const _TextCard(this.text, {required this.size, required this.letter});
  final String text;
  final double size;
  final bool letter;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: letter ? size : null,
    height: size,
    child: Center(
      child: FittedBox(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.08),
          child: Text(
            text,
            textDirection: RegExp(r'[؀-ۿ]').hasMatch(text) ? TextDirection.rtl : TextDirection.ltr,
            style: novaText(size * (letter ? 0.62 : 0.42), weight: 800, color: const Color(0xFF3A2A4A)),
          ),
        ),
      ),
    ),
  );
}

class TokenArt extends StatelessWidget {
  const TokenArt(this.token, {super.key, this.size = 56});
  final Token token;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _TokenPainter(token)),
  );
}

class _TokenPainter extends CustomPainter {
  _TokenPainter(this.token);
  final Token token;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width * (token.big ? 0.9 : 0.72);
    final c = size.center(Offset.zero);
    final r = s / 2;
    final path = switch (token.shape) {
      Shape.circle => Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Shape.square => Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCircle(center: c, radius: r * 0.9), Radius.circular(r * 0.2))),
      Shape.triangle =>
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy + r * 0.8)
          ..lineTo(c.dx - r, c.dy + r * 0.8)
          ..close(),
      Shape.star => () {
        final p = Path();
        for (var k = 0; k < 10; k++) {
          final rr = k.isEven ? r : r * 0.48;
          final a = -math.pi / 2 + k * math.pi / 5;
          final q = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
          k == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
        }
        return p..close();
      }(),
      Shape.heart =>
        Path()
          ..moveTo(c.dx, c.dy + r * 0.9)
          ..cubicTo(c.dx - r * 1.4, c.dy, c.dx - r * 0.8, c.dy - r * 1.2, c.dx, c.dy - r * 0.45)
          ..cubicTo(c.dx + r * 0.8, c.dy - r * 1.2, c.dx + r * 1.4, c.dy, c.dx, c.dy + r * 0.9)
          ..close(),
    };
    final color = hueColor(token.hue);
    canvas.drawShadow(path, const Color(0xFF2A1640), 4, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 0.95,
          colors: [shade(color, 0.45), color, shade(color, -0.35)],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.3, -r * 0.4), width: r * 0.6, height: r * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_TokenPainter old) => old.token != token;
}

class _Group extends StatelessWidget {
  const _Group(this.v, this.size);
  final GroupVisual v;
  final double size;

  @override
  Widget build(BuildContext context) {
    final n = v.count;
    final cols = n <= 3 ? n : (n <= 6 ? 3 : (n <= 12 ? 4 : 5));
    final item = size / (math.max(cols, 2) + 0.6);
    if (!v.scattered) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: item * 0.12,
            runSpacing: item * 0.12,
            children: [for (var i = 0; i < n; i++) v.pic == Pic.gem ? _Dot(item * 0.8) : PicArt(v.pic, size: item)],
          ),
        ),
      );
    }
    // Scattered but never overlapping: jittered cells of a grid.
    final rng = math.Random(v.seed);
    final rows = (n / cols).ceil();
    final cell = size / math.max(cols, rows);
    final cells = [
      for (var r = 0; r < math.max(cols, rows); r++)
        for (var c = 0; c < math.max(cols, rows); c++) (r, c),
    ]..shuffle(rng);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < n; i++)
            Positioned(
              left: cells[i].$2 * cell + rng.nextDouble() * cell * 0.15,
              top: cells[i].$1 * cell + rng.nextDouble() * cell * 0.15,
              child: PicArt(v.pic, size: cell * 0.82),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.size);
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(center: Alignment(-0.35, -0.4), colors: [Color(0xFFB9F1FF), Color(0xFF28B8E8), Color(0xFF0F6FA0)], stops: [0, 0.5, 1]),
    ),
  );
}

class _Pattern extends StatelessWidget {
  const _Pattern(this.v, this.size);
  final PatternVisual v;
  final double size;

  @override
  Widget build(BuildContext context) {
    final count = v.shown.length + 1;
    final item = math.min(size * 0.9, size * 4 / count);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in v.shown)
            _Carriage(
              size: item,
              child: TokenArt(t, size: item * 0.8),
            ),
          _Carriage(
            size: item,
            child: Text('?', style: novaText(item * 0.55, weight: 800, color: const Color(0xFF7C6CF2))),
          ),
        ],
      ),
    );
  }
}

class _Carriage extends StatelessWidget {
  const _Carriage({required this.size, required this.child});
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    margin: EdgeInsets.symmetric(horizontal: size * 0.04),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(size * 0.2),
      border: Border.all(color: const Color(0xFFE2A969), width: size * 0.05),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3))],
    ),
    child: child,
  );
}

class _Towers extends StatelessWidget {
  const _Towers(this.v, this.size);
  final TowersVisual v;
  final double size;

  @override
  Widget build(BuildContext context) {
    final maxH = [...v.heights, 4].reduce(math.max) + (v.withGap ? 2 : 0);
    final block = math.min(size / (maxH + 1), size * 1.8 / (v.heights.length + (v.withGap ? 1 : 0)) * 0.7);
    Widget tower(int h, {bool mystery = false}) => Padding(
      padding: EdgeInsets.symmetric(horizontal: block * 0.25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: mystery
            ? [Text('?', style: novaText(block * 1.2, weight: 800, color: const Color(0xFF7C6CF2)))]
            : [
                for (var i = 0; i < h; i++)
                  Container(
                    width: block,
                    height: block * 0.92,
                    margin: EdgeInsets.only(top: block * 0.06),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(block * 0.18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [shade(const Color(0xFF28B8E8), 0.35), const Color(0xFF1E88C8)],
                      ),
                    ),
                  ),
              ],
      ),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: size,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [for (final h in v.heights) tower(h), if (v.withGap) tower(0, mystery: true)],
        ),
      ),
    );
  }
}

/// A character's head and shoulders showing a feeling.
class FaceArt extends StatelessWidget {
  const FaceArt(this.who, this.emotion, {super.key, required this.size});
  final Who who;
  final Emotion emotion;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: ClipRect(
      child: OverflowBox(
        maxWidth: size * 1.5,
        maxHeight: size * 2.0,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: size * 1.5,
          height: size * 2.0,
          child: CustomPaint(
            painter: CharacterPainter(kind: kindOf(who), pose: emotionPose(emotion)),
          ),
        ),
      ),
    ),
  );
}

class _Scene extends StatelessWidget {
  const _Scene(this.v, this.size);
  final SceneVisual v;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: CharacterPainter(kind: kindOf(v.who), pose: actionPose(v.action)),
          ),
        ),
        if (v.prop != null)
          Positioned(
            right: 0,
            bottom: size * 0.05,
            child: PicArt(v.prop!, size: size * 0.36),
          ),
        if (v.action == Act.sleeping)
          Positioned(
            right: size * 0.12,
            top: size * 0.04,
            // A drawn snore, not words: hidden from screen readers.
            child: ExcludeSemantics(child: Text(_snore, style: novaText(size * 0.14, weight: 800, color: const Color(0xFF7C6CF2)))),
          ),
      ],
    ),
  );
}

const _snore = 'z z';

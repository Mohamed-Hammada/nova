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
      TextVisual() => v.isSentence ? _SentenceCard(v.text, size: size) : _TextCard(v.text, size: size, letter: v.isLetter),
      TokenVisual() => TokenArt(v.token, size: size),
      PatternVisual() => FittedBox(fit: BoxFit.scaleDown, child: _Pattern(v, size)),
      TowersVisual() => FittedBox(fit: BoxFit.scaleDown, child: _Towers(v, size)),
      FaceVisual() => FaceArt(v.who, v.emotion, size: size),
      SceneVisual() => _Scene(v, size),
      FrameVisual() => FittedBox(fit: BoxFit.scaleDown, child: _Frame(v, size, language)),
      PathVisual() => FittedBox(fit: BoxFit.scaleDown, child: _Path(v, size, language)),
      CherryVisual() => FittedBox(fit: BoxFit.scaleDown, child: _Cherries(v, size, language)),
      TapeVisual() => FittedBox(fit: BoxFit.scaleDown, child: _Tape(v, size, language)),
    };
  }
}

/// A five- or ten-frame: two rows of squares, the first [FrameVisual.filled]
/// holding a dot. Without dots, the number is written instead.
class _Frame extends StatelessWidget {
  const _Frame(this.v, this.size, this.language);
  final FrameVisual v;
  final double size;
  final String language;

  @override
  Widget build(BuildContext context) {
    if (!v.showDots) return NumeralBadge(numeral(v.filled, language), size: size);
    final perRow = v.slots == 10 ? 5 : v.slots;
    final rows = (v.slots / perRow).ceil();
    final cell = size * 0.42;
    return Semantics(
      label: numeral(v.filled, language),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(cell * 0.12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(cell * 0.2), border: Border.all(color: const Color(0xFF5B4A70), width: 3)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows; r++)
              Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  for (var c = 0; c < perRow; c++)
                    Container(
                      width: cell,
                      height: cell,
                      margin: EdgeInsets.all(cell * 0.04),
                      decoration: BoxDecoration(color: const Color(0xFFFFF7E6), border: Border.all(color: const Color(0xFFB9A8CC), width: 2), borderRadius: BorderRadius.circular(cell * 0.12)),
                      child: r * perRow + c < v.filled
                          ? Center(child: Container(width: cell * 0.66, height: cell * 0.66, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF0413B))))
                          : null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A numbered path left to right (a number line children can hop along),
/// the frog on its square and the spinner's hops shown as arcs of dots.
class _Path extends StatelessWidget {
  const _Path(this.v, this.size, this.language);
  final PathVisual v;
  final double size;
  final String language;

  @override
  Widget build(BuildContext context) {
    final cell = size * (v.length > 5 ? 0.36 : 0.52);
    return Semantics(
      label: '${numeral(v.at, language)} + ${numeral(v.hops, language)}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < v.hops; i++)
                Container(margin: EdgeInsets.all(cell * 0.06), width: cell * 0.3, height: cell * 0.3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34C77B))),
            ],
          ),
          SizedBox(height: cell * 0.15),
          // Numbers always run left to right, as on a ruler, in both languages.
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              for (var n = 1; n <= v.length; n++)
                Container(
                  width: cell,
                  height: cell * 1.25,
                  margin: EdgeInsets.all(cell * 0.03),
                  decoration: BoxDecoration(
                    color: n == v.at ? const Color(0xFFB8E27A) : (n.isEven ? const Color(0xFFFFE9B8) : const Color(0xFFFFF7E6)),
                    borderRadius: BorderRadius.circular(cell * 0.18),
                    border: Border.all(color: const Color(0xFF5B4A70), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(numeral(n, language), style: novaText(cell * 0.4, weight: 800, color: const Color(0xFF3A2A4A))),
                      // Drawn, not an emoji: an emoji glyph would make the web
                      // build fetch a font it does not bundle.
                      if (n == v.at) _Frog(size: cell * 0.4) else SizedBox(height: cell * 0.4),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

const _ink = Color(0xFF3A2A4A);

/// A number, or a glowing "?" for the one the round asks for.
Widget _slot(int? n, double size, String language, Color fill) => Container(
  width: size,
  height: size,
  alignment: Alignment.center,
  decoration: BoxDecoration(
    color: n == null ? const Color(0xFFFFF4B8) : fill,
    shape: BoxShape.circle,
    border: Border.all(color: n == null ? const Color(0xFFE08A00) : _ink, width: n == null ? 4 : 2.5),
  ),
  child: Text(n == null ? '?' : numeral(n, language), style: novaText(size * 0.46, weight: 800, color: _ink)),
);

/// さくらんぼ計算: "8 + 5" with the 5 hanging as two cherries, "2" (to make
/// ten) and "3". Always left to right, as sums are written in both
/// languages' school maths.
class _Cherries extends StatelessWidget {
  const _Cherries(this.v, this.size, this.language);
  final CherryVisual v;
  final double size;
  final String language;

  @override
  Widget build(BuildContext context) {
    final u = size * 0.34;
    final text = novaText(u * 0.8, weight: 800, color: _ink);
    const cherry = Color(0xFFFF8A8A);
    return Semantics(
      label: '${numeral(v.a, language)} + ${numeral(v.b, language)}',
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(numeral(v.a, language), style: text),
                SizedBox(width: u * 0.3),
                Text('+', style: text),
                SizedBox(width: u * 0.3),
                Text(numeral(v.b, language), style: text),
                SizedBox(width: u * 0.3),
                Text('=', style: text),
                SizedBox(width: u * 0.3),
                v.askTotal ? _slot(null, u, language, Colors.white) : Text('…', style: text),
              ],
            ),
            // The stems: from the second number down to its two cherries.
            SizedBox(
              width: u * 4.2,
              height: u * 0.9,
              child: CustomPaint(painter: _Stems(color: const Color(0xFF3C8F4A))),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _slot(v.first, u, language, cherry),
                SizedBox(width: u * 0.9),
                // While the first cherry is asked, the second stays blank, so
                // the way in is making ten, not taking away.
                v.first == null && !v.askTotal
                    ? Container(width: u, height: u, decoration: BoxDecoration(color: cherry.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: _ink, width: 2.5)))
                    : _slot(v.second, u, language, cherry),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stems extends CustomPainter {
  _Stems({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    // The second number sits a little right of centre in the row above.
    final top = Offset(s.width * 0.56, 0);
    canvas.drawLine(top, Offset(s.width * 0.33, s.height), p);
    canvas.drawLine(top, Offset(s.width * 0.67, s.height), p);
  }

  @override
  bool shouldRepaint(_Stems old) => old.color != color;
}

/// テープ図: the whole as one bracket over a tape cut into two parts drawn
/// to scale; the missing number is a "?".
class _Tape extends StatelessWidget {
  const _Tape(this.v, this.size, this.language);
  final TapeVisual v;
  final double size;
  final String language;

  @override
  Widget build(BuildContext context) {
    final unit = size * 0.26;
    final total = v.sizeA + v.sizeB;
    final label = novaText(unit * 0.62, weight: 800, color: _ink);
    Widget part(int? n, int len, Color c) => Container(
      width: unit * len,
      height: unit * 1.1,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c, border: Border.all(color: _ink, width: 2.5)),
      child: Text(n == null ? '?' : numeral(n, language), style: label),
    );
    return Semantics(
      label: [v.partA, v.partB, v.whole].map((n) => n == null ? '?' : numeral(n, language)).join(' , '),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(v.whole == null ? '?' : numeral(v.whole!, language), style: label.copyWith(color: v.whole == null ? const Color(0xFFE08A00) : _ink)),
            Container(
              width: unit * total,
              height: unit * 0.35,
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: _ink, width: 2.5), right: BorderSide(color: _ink, width: 2.5), top: BorderSide(color: _ink, width: 2.5))),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                part(v.partA, v.sizeA, const Color(0xFFB8E27A)),
                part(v.partB, v.sizeB, const Color(0xFFFFC83D)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A little frog face for the number path.
class _Frog extends StatelessWidget {
  const _Frog({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.3,
    height: size,
    child: Stack(
      children: [
        Positioned(left: size * 0.05, right: size * 0.05, top: size * 0.25, bottom: 0, child: Container(decoration: BoxDecoration(color: const Color(0xFF34C77B), borderRadius: BorderRadius.circular(size)))),
        for (final x in [0.1, 0.7])
          Positioned(
            left: size * x,
            top: 0,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: Center(child: Container(width: size * 0.2, height: size * 0.2, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2E2440)))),
            ),
          ),
      ],
    ),
  );
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

/// A short sentence on a card: wrapped at a readable width, scaled down only
/// if it still does not fit.
class _SentenceCard extends StatelessWidget {
  const _SentenceCard(this.text, {required this.size});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final width = size;
    return SizedBox(
      width: width,
      height: size,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: width,
            child: Text(
              text,
              textAlign: TextAlign.center,
              textDirection: RegExp(r'[؀-ۿ]').hasMatch(text) ? TextDirection.rtl : TextDirection.ltr,
              style: novaText(size * 0.15, weight: 800, color: const Color(0xFF3A2A4A)),
            ),
          ),
        ),
      ),
    );
  }
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

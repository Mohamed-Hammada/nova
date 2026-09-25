import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/graphics.dart';
import '../theme/motion.dart';
import '../theme/nova_theme.dart';

/// Small decorations that give each place its character.
enum SceneProp { fruitTrees, roundTrees, pines, mushrooms, notes, hearts, shells, crystals, lilyPads, flowers }

/// The look of one storybook place: a few colours and a few props. Every
/// Nova place is drawn by the same [StoryScene] with a different theme, so
/// all of them belong to one world.
class SceneTheme {
  const SceneTheme({
    required this.skyTop,
    required this.skyBottom,
    required this.hillFar,
    required this.hillMid,
    required this.ground,
    required this.groundLight,
    required this.foliage,
    required this.accent,
    this.props = const [SceneProp.roundTrees, SceneProp.flowers],
    this.sun = const Color(0xFFFFF3C4),
    this.water,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color hillFar;
  final Color hillMid;
  final Color ground;
  final Color groundLight;
  final Color foliage;
  final Color accent;
  final List<SceneProp> props;
  final Color sun;

  /// A lake or sea across the middle distance.
  final Color? water;

  /// Home: a bright morning meadow.
  static const meadow = SceneTheme(
    skyTop: Color(0xFF6CC3FF),
    skyBottom: Color(0xFFE4F6FF),
    hillFar: Color(0xFFA9DDB0),
    hillMid: Color(0xFF86CF73),
    ground: Color(0xFF79C75A),
    groundLight: Color(0xFFA6DE78),
    foliage: Color(0xFF4FAE52),
    accent: Color(0xFFFF7A59),
    props: [SceneProp.roundTrees, SceneProp.pines, SceneProp.flowers],
  );
}

/// A layered 2.5D storybook environment: graded sky with a soft sun, drifting
/// clouds, rolling hills with rounded trees, a foreground meadow and a few
/// floating motes of light. The static layers are painted once and cached;
/// only clouds and motes move, and nothing moves when motion is reduced or
/// graphics are set low.
class StoryScene extends StatefulWidget {
  const StoryScene({super.key, required this.theme, this.horizon = 0.62, this.child});

  final SceneTheme theme;

  /// Where the foreground meadow begins, as a fraction of the height.
  final double horizon;
  final Widget? child;

  @override
  State<StoryScene> createState() => _StorySceneState();
}

class _StorySceneState extends State<StoryScene> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((e) => _time.value = e.inMicroseconds / 1e6);
  final _time = ValueNotifier<double>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = AmbientMotion.of(context) && Graphics.of(context).animatedBackdrop;
    if (on && !_ticker.isActive) _ticker.start();
    if (!on && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quality = Graphics.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: CustomPaint(painter: _LandscapePainter(widget.theme, widget.horizon, rtl))),
        if (quality != GraphicsQuality.low)
          RepaintBoundary(child: CustomPaint(painter: _SkyLifePainter(widget.theme, widget.horizon, _time, quality))),
        ?widget.child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Static landscape
// ---------------------------------------------------------------------------

class _LandscapePainter extends CustomPainter {
  _LandscapePainter(this.t, this.horizon, this.rtl);
  final SceneTheme t;
  final double horizon;

  /// Mirrors the composition, so the sun and the big tree sit on the side a
  /// reader of the current language looks at last.
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (rtl) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    final horizonY = h * horizon;

    // Sky.
    canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, horizonY), [t.skyTop, t.skyBottom]));

    // Sun: a soft disc with a wide bloom.
    final sun = Offset(w * 0.84, h * 0.14);
    canvas.drawCircle(sun, h * 0.34, Paint()..shader = ui.Gradient.radial(sun, h * 0.34, [t.sun.withValues(alpha: 0.55), t.sun.withValues(alpha: 0)]));
    canvas.drawCircle(sun, h * 0.055, Paint()..color = t.sun);

    // Far hills: two soft layers with aerial haze.
    _hills(canvas, size, horizonY - h * 0.16, h * 0.07, 1.3, 0.4, Color.lerp(t.hillFar, t.skyBottom, 0.45)!);
    _hills(canvas, size, horizonY - h * 0.1, h * 0.06, 1.8, 1.7, t.hillFar);

    if (t.water != null) {
      final water = Rect.fromLTRB(0, horizonY - h * 0.06, w, horizonY + h * 0.04);
      canvas.drawRect(water, Paint()..shader = ui.Gradient.linear(water.topCenter, water.bottomCenter, [shade(t.water!, 0.25), t.water!]));
      for (var i = 0; i < 6; i++) {
        final y = water.top + (i + 1) * water.height / 7;
        canvas.drawLine(Offset(w * (0.1 + 0.13 * i), y), Offset(w * (0.18 + 0.13 * i), y), Paint()..color = Colors.white.withValues(alpha: 0.35)..strokeWidth = 2..strokeCap = StrokeCap.round);
      }
    }

    // Mid hills with rounded trees.
    final midTop = horizonY - h * 0.03;
    _hills(canvas, size, midTop, h * 0.05, 2.4, 0.9, t.hillMid);
    final rand = math.Random(3);
    final treeCount = (w / 90).clamp(5, 18).round();
    for (var i = 0; i < treeCount; i++) {
      final x = (i + 0.5 + (rand.nextDouble() - 0.5) * 0.6) * w / treeCount;
      final y = midTop + h * 0.025 * math.sin(x / w * math.pi * 2.4 + 0.9) + h * 0.02;
      final r = h * (0.028 + rand.nextDouble() * 0.02);
      final prop = t.props.contains(SceneProp.pines) && i.isOdd ? SceneProp.pines : SceneProp.roundTrees;
      _tree(canvas, Offset(x, y), r, prop, t.props.contains(SceneProp.fruitTrees) && i % 3 == 0);
    }

    // Foreground meadow.
    final ground = Path()..moveTo(0, horizonY);
    for (var x = 0.0; x <= w; x += 8) {
      ground.lineTo(x, horizonY + h * 0.018 * math.sin(x / w * math.pi * 1.6 + 0.4));
    }
    ground
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ground, Paint()..shader = ui.Gradient.linear(Offset(0, horizonY), Offset(0, h), [t.groundLight, t.ground, shade(t.ground, -0.12)], [0, 0.35, 1]));

    // A winding path through the meadow toward the viewer.
    final path = Path()
      ..moveTo(w * 0.58, horizonY + h * 0.01)
      ..cubicTo(w * 0.42, horizonY + h * 0.12, w * 0.72, horizonY + h * 0.2, w * 0.46, h)
      ..lineTo(w * 0.78, h)
      ..cubicTo(w * 0.9, horizonY + h * 0.2, w * 0.56, horizonY + h * 0.12, w * 0.62, horizonY + h * 0.01)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF3D9A4).withValues(alpha: 0.85));

    // Big foreground tree at the far side, framing the scene.
    _tree(canvas, Offset(w * 0.93, horizonY + h * 0.08), h * 0.12, SceneProp.roundTrees, t.props.contains(SceneProp.fruitTrees));

    // Props scattered across the meadow.
    final r2 = math.Random(11);
    for (var i = 0; i < (w / 70).clamp(6, 22).round(); i++) {
      final p = Offset(r2.nextDouble() * w, horizonY + h * 0.05 + r2.nextDouble() * (h - horizonY) * 0.85);
      final prop = t.props[i % t.props.length];
      _prop(canvas, p, h * 0.014 * (0.8 + r2.nextDouble() * 0.6) * (0.6 + (p.dy - horizonY) / (h - horizonY)), prop, i);
    }
  }

  void _hills(Canvas canvas, Size size, double top, double amp, double freq, double phase, Color color) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 8) {
      path.lineTo(x, top + amp * math.sin(x / size.width * math.pi * freq + phase));
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..shader = ui.Gradient.linear(Offset(0, top - amp), Offset(0, top + amp * 4), [shade(color, 0.08), color]));
  }

  void _tree(Canvas canvas, Offset base, double r, SceneProp kind, bool fruit) {
    canvas.drawOval(Rect.fromCenter(center: base + Offset(0, r * 0.1), width: r * 2.2, height: r * 0.5), Paint()..color = const Color(0x22000000));
    final trunk = RRect.fromRectAndRadius(Rect.fromCenter(center: base - Offset(0, r * 0.55), width: r * 0.36, height: r * 1.2), Radius.circular(r * 0.18));
    canvas.drawRRect(trunk, Paint()..color = const Color(0xFF9A6440));
    if (kind == SceneProp.pines) {
      for (var i = 0; i < 3; i++) {
        final y = base.dy - r * (1.0 + i * 0.7);
        final wv = r * (1.3 - i * 0.3);
        final tri = Path()
          ..moveTo(base.dx, y - r * 0.9)
          ..quadraticBezierTo(base.dx + wv * 0.2, y - r * 0.4, base.dx + wv, y)
          ..quadraticBezierTo(base.dx, y + r * 0.25, base.dx - wv, y)
          ..quadraticBezierTo(base.dx - wv * 0.2, y - r * 0.4, base.dx, y - r * 0.9)
          ..close();
        canvas.drawPath(tri, Paint()..shader = ui.Gradient.linear(Offset(base.dx - wv, y), Offset(base.dx + wv, y), [shade(t.foliage, 0.12), shade(t.foliage, -0.18)]));
      }
      return;
    }
    final c = base - Offset(0, r * 1.55);
    // A cluster of soft balls, lit from the sun side.
    for (final (dx, dy, rr) in [(-0.55, 0.15, 0.7), (0.55, 0.15, 0.7), (0.0, -0.3, 0.85), (0.0, 0.2, 0.8)]) {
      final cc = c + Offset(dx * r, dy * r);
      canvas.drawCircle(cc, rr * r, Paint()..shader = ui.Gradient.radial(cc + Offset(r * 0.25, -r * 0.35), rr * r * 1.3, [shade(t.foliage, 0.28), t.foliage, shade(t.foliage, -0.2)], [0, 0.55, 1]));
    }
    if (fruit) {
      for (final (dx, dy) in [(-0.6, 0.1), (0.4, -0.35), (0.55, 0.35), (-0.15, 0.45)]) {
        final f = c + Offset(dx * r, dy * r);
        canvas.drawCircle(f, r * 0.16, Paint()..color = const Color(0xFFFF9A2E));
        canvas.drawCircle(f + Offset(-r * 0.05, -r * 0.05), r * 0.05, Paint()..color = Colors.white.withValues(alpha: 0.7));
      }
    }
  }

  void _prop(Canvas canvas, Offset p, double s, SceneProp prop, int i) {
    switch (prop) {
      case SceneProp.flowers || SceneProp.roundTrees || SceneProp.pines || SceneProp.fruitTrees:
        const colours = [Color(0xFFFFFFFF), Color(0xFFFFD84D), Color(0xFFFF8FB8), Color(0xFFB69CFF)];
        for (var k = 0; k < 5; k++) {
          final a = k * math.pi * 2 / 5;
          canvas.drawCircle(p + Offset(math.cos(a), math.sin(a)) * s * 0.7, s * 0.55, Paint()..color = colours[i % colours.length]);
        }
        canvas.drawCircle(p, s * 0.45, Paint()..color = const Color(0xFFFFB02E));
      case SceneProp.mushrooms:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: s * 0.9, height: s * 1.6), Radius.circular(s * 0.3)), Paint()..color = const Color(0xFFFFF3E0));
        canvas.drawPath(
          Path()..addArc(Rect.fromCenter(center: p - Offset(0, s * 0.6), width: s * 3, height: s * 2.4), math.pi, math.pi),
          Paint()..color = const Color(0xFFF2508B),
        );
        canvas.drawCircle(p - Offset(s * 0.5, s * 1.1), s * 0.25, Paint()..color = Colors.white);
      case SceneProp.notes:
        final paint = Paint()..color = t.accent;
        canvas.drawOval(Rect.fromCenter(center: p, width: s * 1.5, height: s * 1.1), paint);
        canvas.drawRect(Rect.fromLTWH(p.dx + s * 0.55, p.dy - s * 2.4, s * 0.3, s * 2.4), paint);
        canvas.drawRect(Rect.fromLTWH(p.dx + s * 0.55, p.dy - s * 2.4, s * 1.1, s * 0.4), paint);
      case SceneProp.hearts:
        final path = Path()
          ..moveTo(p.dx, p.dy + s)
          ..cubicTo(p.dx - s * 1.8, p.dy - s * 0.2, p.dx - s * 0.8, p.dy - s * 1.6, p.dx, p.dy - s * 0.5)
          ..cubicTo(p.dx + s * 0.8, p.dy - s * 1.6, p.dx + s * 1.8, p.dy - s * 0.2, p.dx, p.dy + s);
        canvas.drawPath(path, Paint()..color = i.isEven ? const Color(0xFFFF7FA8) : const Color(0xFFFFB3C9));
      case SceneProp.shells:
        canvas.drawPath(Path()..addArc(Rect.fromCenter(center: p, width: s * 2.4, height: s * 2), math.pi, math.pi), Paint()..color = const Color(0xFFFFC7B0));
        for (var k = -2; k <= 2; k++) {
          canvas.drawLine(p, p + Offset(k * s * 0.45, -s * 0.9), Paint()..color = const Color(0xFFE59478)..strokeWidth = 1.2);
        }
      case SceneProp.crystals:
        final c = i.isEven ? const Color(0xFF9FE6FF) : const Color(0xFFD6B8FF);
        final path = Path()
          ..moveTo(p.dx, p.dy - s * 2.2)
          ..lineTo(p.dx + s * 0.8, p.dy - s * 0.8)
          ..lineTo(p.dx + s * 0.5, p.dy + s * 0.4)
          ..lineTo(p.dx - s * 0.5, p.dy + s * 0.4)
          ..lineTo(p.dx - s * 0.8, p.dy - s * 0.8)
          ..close();
        canvas.drawPath(path, Paint()..color = c);
        canvas.drawLine(Offset(p.dx, p.dy - s * 2.2), Offset(p.dx, p.dy + s * 0.4), Paint()..color = Colors.white.withValues(alpha: 0.6)..strokeWidth = 1.2);
      case SceneProp.lilyPads:
        canvas.drawOval(Rect.fromCenter(center: p, width: s * 3, height: s * 1.4), Paint()..color = const Color(0xFF5DBB63));
        canvas.drawCircle(p - Offset(0, s * 0.3), s * 0.4, Paint()..color = const Color(0xFFFF9EC4));
    }
  }

  @override
  bool shouldRepaint(_LandscapePainter old) => old.t != t || old.horizon != horizon || old.rtl != rtl;
}

// ---------------------------------------------------------------------------
// Moving sky: clouds and motes of light
// ---------------------------------------------------------------------------

class _SkyLifePainter extends CustomPainter {
  _SkyLifePainter(this.t, this.horizon, this.time, this.quality) : super(repaint: time);
  final SceneTheme t;
  final double horizon;
  final ValueNotifier<double> time;
  final GraphicsQuality quality;

  static final _rand = math.Random(5);
  static final _motes = List.generate(24, (_) => (_rand.nextDouble(), _rand.nextDouble(), 0.5 + _rand.nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final s = time.value;
    for (var i = 0; i < quality.clouds; i++) {
      final speed = 6.0 + i * 2.5;
      final x = ((i * 0.27 + 0.05) * (w + 260) + s * speed) % (w + 260) - 130;
      final y = h * (0.07 + 0.08 * (i % 3));
      _cloud(canvas, Offset(x, y), h * (0.045 + 0.012 * (i % 2)));
    }
    final motes = quality.particles;
    for (var i = 0; i < motes && i < _motes.length; i++) {
      final (mx, my, sp) = _motes[i];
      final y = (my * h * horizon * 1.3 - s * 8 * sp) % (h * horizon * 1.3);
      final x = mx * w + 10 * math.sin(s * 0.6 * sp + i);
      final a = 0.25 + 0.2 * math.sin(s * 1.3 * sp + i);
      canvas.drawCircle(Offset(x, y), 2.2 * sp, Paint()..color = Colors.white.withValues(alpha: a));
    }
  }

  void _cloud(Canvas canvas, Offset c, double r) {
    final shadow = Paint()..color = const Color(0xFFDDE7F7);
    final light = Paint()..color = Colors.white;
    for (final (dx, dy, rr) in [(-1.2, 0.2, 0.7), (-0.4, -0.25, 0.95), (0.55, -0.1, 0.85), (1.3, 0.25, 0.6)]) {
      canvas.drawCircle(c + Offset(dx * r, dy * r + r * 0.12), rr * r, shadow);
    }
    for (final (dx, dy, rr) in [(-1.2, 0.2, 0.7), (-0.4, -0.25, 0.95), (0.55, -0.1, 0.85), (1.3, 0.25, 0.6)]) {
      canvas.drawCircle(c + Offset(dx * r, dy * r), rr * r, light);
    }
  }

  @override
  bool shouldRepaint(_SkyLifePainter old) => old.t != t || old.quality != quality;
}

// ---------------------------------------------------------------------------
// Floating island
// ---------------------------------------------------------------------------

/// A little floating island of meadow with a rocky underside -- the stage a
/// companion stands on, and the shape every place on the home screen takes.
class FloatingIsland extends StatelessWidget {
  const FloatingIsland({super.key, required this.width, this.grass = const Color(0xFF7BCB5C), this.child, this.childHeight = 0, this.decoration = SceneProp.flowers});

  final double width;
  final Color grass;

  /// Stands on the island's top surface.
  final Widget? child;
  final double childHeight;
  final SceneProp decoration;

  @override
  Widget build(BuildContext context) {
    final islandHeight = width * 0.5;
    final top = width * 0.1;
    return SizedBox(
      width: width,
      height: childHeight + islandHeight - top,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, right: 0, bottom: 0, height: islandHeight, child: CustomPaint(painter: _IslandPainter(grass, decoration))),
          if (child != null) Positioned(left: 0, right: 0, top: 0, height: childHeight, child: child!),
        ],
      ),
    );
  }
}

class _IslandPainter extends CustomPainter {
  _IslandPainter(this.grass, this.decoration);
  final Color grass;
  final SceneProp decoration;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final topH = h * 0.36;
    final top = Rect.fromLTWH(w * 0.02, h * 0.02, w * 0.96, topH);

    // Rocky underside: rounded strata tapering to a point.
    final under = Path()
      ..moveTo(top.left + w * 0.04, top.center.dy)
      ..quadraticBezierTo(w * 0.18, h * 0.78, w * 0.46, h * 0.98)
      ..quadraticBezierTo(w * 0.52, h * 1.02, w * 0.58, h * 0.94)
      ..quadraticBezierTo(w * 0.84, h * 0.72, top.right - w * 0.04, top.center.dy)
      ..close();
    canvas.drawPath(under, Paint()..shader = ui.Gradient.linear(Offset(0, top.center.dy), Offset(0, h), [const Color(0xFF9A6A4A), const Color(0xFF6B4632)]));
    for (final (y, a) in [(0.52, 0.18), (0.68, 0.12)]) {
      canvas.drawLine(Offset(w * 0.2, h * y), Offset(w * 0.8, h * y + 4), Paint()..color = Colors.black.withValues(alpha: a)..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
    // Pebbles on the underside.
    for (final (x, y, r) in [(0.3, 0.6, 0.03), (0.62, 0.72, 0.025), (0.45, 0.82, 0.02)]) {
      canvas.drawCircle(Offset(w * x, h * y), w * r, Paint()..color = const Color(0xFFB88A66));
    }

    // Grass top: a thick lip in a darker green, then the lit surface.
    canvas.drawOval(top.translate(0, topH * 0.16), Paint()..color = shade(grass, -0.25));
    canvas.drawOval(top, Paint()..shader = ui.Gradient.radial(top.center - Offset(w * 0.1, topH * 0.3), w * 0.6, [shade(grass, 0.28), grass, shade(grass, -0.08)], [0, 0.6, 1]));
    // Grass drips over the lip.
    for (var i = 0; i < 9; i++) {
      final x = top.left + w * 0.08 + i * w * 0.1;
      final y = top.center.dy + topH * 0.42 * math.sqrt(math.max(0, 1 - math.pow((x - top.center.dx) / (top.width / 2), 2)));
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y + topH * 0.08), width: w * 0.07, height: topH * 0.3), Paint()..color = shade(grass, -0.12));
    }
    // Tufts and flowers.
    final tuft = Paint()..color = shade(grass, -0.18);
    for (final (x, y) in [(0.16, 0.45), (0.8, 0.4), (0.7, 0.6)]) {
      final c = Offset(top.left + top.width * x, top.top + top.height * y);
      for (var k = -1; k <= 1; k++) {
        canvas.drawOval(Rect.fromCenter(center: c + Offset(k * w * 0.012, -topH * 0.06), width: w * 0.014, height: topH * 0.22), tuft);
      }
    }
    if (decoration == SceneProp.flowers) {
      for (final (x, y, col) in [(0.24, 0.62, 0xFFFFFFFF), (0.86, 0.55, 0xFFFFD84D), (0.12, 0.5, 0xFFFF8FB8)]) {
        final c = Offset(top.left + top.width * x, top.top + top.height * y);
        for (var k = 0; k < 5; k++) {
          final a = k * math.pi * 2 / 5;
          canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * w * 0.012, w * 0.01, Paint()..color = Color(col));
        }
        canvas.drawCircle(c, w * 0.008, Paint()..color = const Color(0xFFFFB02E));
      }
    }
  }

  @override
  bool shouldRepaint(_IslandPainter old) => old.grass != grass || old.decoration != decoration;
}

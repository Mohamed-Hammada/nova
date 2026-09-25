import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';

import '../art/pic_art.dart';
import '../characters/character_view.dart';
import '../play/visual_view.dart';
import '../scene/world_backdrop.dart';
import '../theme/age_band.dart';
import '../theme/motion.dart';
import '../theme/nova_theme.dart';
import '../game/game_catalog.dart';
import '../game/game_screen.dart';
import '../l10n.dart';
import 'package:nova_app/core/play/session.dart';
import '../widgets/jelly_button.dart';
import '../widgets/props.dart';
import 'level_screen.dart';
import 'package:nova_app/core/play/lexicon.dart';

/// Loads the stars earned so far on every level.
final levelStarsProvider = FutureProvider<Map<String, int>>((ref) => ref.watch(playerStatePortProvider).levelStars(childId: currentChildId));

/// The level map for the child's age group: a winding path of levels in
/// chapters of ten. A level opens when the one before it is finished.
class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  final _scroll = ScrollController();
  bool _scrolled = false;

  static const _nodeGap = 118.0;
  static const _chapterGap = 90.0;

  double _nodeY(int i) => 150 + i * _nodeGap + (i ~/ 10) * _chapterGap;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(Journey journey, int index) async {
    final level = journey.levels[index];
    final gameId = level.gameFor(ref.read(languageProvider));
    final state = ref.read(playerStatePortProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        // Games with their own dedicated screen (Bear's Apples on the 3D
        // stage) play there; every other game plays through LevelScreen.
        builder: (_) => playableGames.containsKey(gameId)
            ? GameScreen(
                gameId: gameId,
                skillId: ref.read(contentRuntimeProvider).game(gameId).primarySkillIds.first,
                onComplete: (accuracy) => state.saveLevel(childId: currentChildId, levelId: level.id, stars: starsFor(accuracy)),
              )
            : LevelScreen(journey: journey, levelIndex: index),
      ),
    );
    ref.invalidate(levelStarsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final band = ref.watch(ageBandProvider);
    final lang = ref.watch(languageProvider);
    final l10n = context.l10n;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final p = ref.watch(paletteProvider);
    final companion = ref.watch(companionProvider);
    final content = ref.watch(contentRuntimeProvider);
    final journey = content.journeyForAge(ref.watch(childAgeProvider) ?? band.minAge) ?? content.journeyForAge(band.minAge);
    final starsAsync = ref.watch(levelStarsProvider);
    final stars = starsAsync.value ?? const <String, int>{};

    return Scaffold(
      body: WorldBackdrop(
        world: ref.watch(worldProvider),
        groundLevel: 0.95,
        child: SafeArea(
          child: journey == null
              ? const SizedBox.shrink()
              : LayoutBuilder(
                  builder: (context, box) {
                    final levels = journey.levels;
                    var current = levels.indexWhere((l) => !stars.containsKey(l.id));
                    if (current < 0) current = levels.length - 1;
                    final total = stars.values.fold<int>(0, (a, b) => a + b);
                    final height = _nodeY(levels.length) + 120;
                    final width = box.maxWidth;
                    Offset node(int i) => Offset(width / 2 + math.sin(i * 0.9) * math.min(width * 0.28, 220), height - _nodeY(i));

                    // Scroll to the next level once, after the saved stars have loaded.
                    if (!_scrolled && starsAsync.hasValue) {
                      _scrolled = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scroll.hasClients) {
                          final target = (node(current).dy - box.maxHeight * 0.6).clamp(0.0, _scroll.position.maxScrollExtent);
                          _scroll.jumpTo(target);
                        }
                      });
                    }

                    return Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _scroll,
                          child: SizedBox(
                            width: width,
                            height: height,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(child: CustomPaint(painter: _PathPainter([for (var i = 0; i < levels.length; i++) node(i)], current, p))),
                                for (var c = 0; c * 10 < levels.length; c++)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: height - _nodeY(c * 10) + 44,
                                    child: Center(
                                      child: _ChapterBanner(text: l10n.chapter(numeral(c + 1, lang)), color: p.accentDeep),
                                    ),
                                  ),
                                for (var i = 0; i < levels.length; i++)
                                  Positioned(
                                    left: node(i).dx - 40,
                                    top: node(i).dy - 40,
                                    child: _LevelNode(
                                      number: i + 1,
                                      language: lang,
                                      stars: stars[levels[i].id],
                                      locked: i > current,
                                      current: i == current,
                                      palette: p,
                                      onTap: i > current ? null : () => _open(journey, i),
                                    ),
                                  ),
                                Positioned(
                                  left: node(current).dx + 34,
                                  top: node(current).dy - 120,
                                  width: 100,
                                  height: 120,
                                  child: IgnorePointer(
                                    child: CharacterView(kind: companion, rimColor: p.glow),
                                  ),
                                ),
                                for (final (i, pic) in [(4, Pic.tree), (13, Pic.flower), (22, Pic.shell), (31, Pic.star), (44, Pic.moon)])
                                  if (i < levels.length)
                                    Positioned(
                                      left: node(i).dx < width / 2 ? node(i).dx + 90 : node(i).dx - 150,
                                      top: node(i).dy - 30,
                                      child: Opacity(opacity: 0.9, child: PicArt(pic, size: 60)),
                                    ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 10,
                          child: Row(
                            children: [
                              JellyButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                color: p.accent,
                                circle: true,
                                size: 48,
                                child: Icon(rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: p.isNight ? 0.14 : 0.85),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          content.i18n(journey.nameKey, lang),
                                          overflow: TextOverflow.ellipsis,
                                          style: novaText(20, weight: 800, color: p.isNight ? Colors.white : p.onSurface),
                                        ),
                                      ),
                                      const StarShape(size: 24),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.starsCount(numeral(total, lang), numeral(levels.length * 3, lang)),
                                        style: novaText(15, weight: 700, color: p.isNight ? Colors.white70 : p.onSurface),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.points, this.current, this.palette);
  final List<Offset> points;
  final int current;
  final WorldPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    Path through(List<Offset> pts) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1], b = pts[i];
        final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        path.quadraticBezierTo(a.dx, mid.dy, mid.dx, mid.dy);
        path.quadraticBezierTo(b.dx, mid.dy, b.dx, b.dy);
      }
      return path;
    }

    final all = through(points);
    canvas.drawPath(
      all,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2A1640).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      all,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..color = palette.isNight ? const Color(0xFF3B2F7A) : const Color(0xFFF5E1B8),
    );
    if (current > 0) {
      canvas.drawPath(
        through(points.sublist(0, current + 1)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..color = palette.accent,
      );
    }
    // Dashes along the path, like footprints.
    for (final metric in all.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 26) {
        final t = metric.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, 2.5, Paint()..color = Colors.white.withValues(alpha: 0.6));
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.current != current || old.points.length != points.length;
}

class _ChapterBanner extends StatelessWidget {
  const _ChapterBanner({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [BoxShadow(color: shade(color, -0.6).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Text(text, style: novaText(18, weight: 800, color: Colors.white)),
  );
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.number,
    required this.language,
    required this.stars,
    required this.locked,
    required this.current,
    required this.palette,
    this.onTap,
  });
  final int number;
  final String language;
  final int? stars;
  final bool locked;
  final bool current;
  final WorldPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final color = locked ? const Color(0xFFB9B2C8) : (stars != null ? p.accent : const Color(0xFFFFB12E));
    final node = Semantics(
      button: !locked,
      label: locked ? context.l10n.levelLocked(numeral(number, language)) : context.l10n.levelOpen(numeral(number, language)),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 80,
          height: 96,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    colors: [shade(color, 0.45), color, shade(color, -0.3)],
                    stops: const [0, 0.55, 1],
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(color: shade(color, -0.6).withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 6)),
                    if (current) BoxShadow(color: p.glow.withValues(alpha: 0.9), blurRadius: 26, spreadRadius: 4),
                  ],
                ),
                child: locked
                    ? const Icon(Icons.lock_rounded, color: Colors.white, size: 30)
                    : Text(
                        numeral(number, language),
                        style: novaText(30, weight: 800, color: Colors.white).copyWith(shadows: const [Shadow(blurRadius: 3, color: Color(0x66000000))]),
                      ),
              ),
              if (stars != null)
                Positioned(
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (var k = 0; k < 3; k++) StarShape(size: 22, filled: k < stars!)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!current) return node;
    return _Bob(child: node);
  }
}

/// The level to play next bobs gently to invite a tap.
class _Bob extends StatefulWidget {
  const _Bob({required this.child});
  final Widget child;

  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = AmbientMotion.of(context);
    if (on && !_c.isAnimating) _c.repeat(reverse: true);
    if (!on && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)), child: child),
    child: widget.child,
  );
}

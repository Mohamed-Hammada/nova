import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_view.dart';
import '../design/nova_design.dart';
import '../l10n.dart';
import '../play/visual_view.dart';
import '../scene/story_scene.dart';
import '../world/activity_world.dart';
import 'journey_labels.dart';
import 'journey_providers.dart';
import 'stage_screen.dart';

/// The child's adventure map: every stage from where they started to the
/// end of the journey, as islands along a winding path. Finished stages
/// keep their tick, the companion stands where the child is, and the
/// adventures ahead wait behind a lock. History never disappears.
class JourneyMapScreen extends ConsumerStatefulWidget {
  const JourneyMapScreen({super.key});

  @override
  ConsumerState<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends ConsumerState<JourneyMapScreen> {
  final _scroll = ScrollController();
  bool _scrolled = false;

  static const _gap = 210.0;
  static const _top = 40.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = ref.watch(journeyProgressProvider);
    return Scaffold(
      body: StoryScene(
        theme: SceneTheme.meadow,
        horizon: 0.3,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(NovaSpace.md, NovaSpace.sm, NovaSpace.md, 0),
              child: Row(children: [
                NovaRoundButton(
                  icon: Directionality.of(context) == TextDirection.rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  label: l10n.backHome,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: NovaSpace.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: NovaSpace.md, vertical: NovaSpace.xs),
                  decoration: BoxDecoration(color: NovaStory.cloud.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(NovaRadius.pill)),
                  child: Semantics(header: true, child: Text(l10n.myJourney, style: NovaType.title(context))),
                ),
              ]),
            ),
            Expanded(
              child: progress == null
                  ? const SizedBox.shrink()
                  : LayoutBuilder(builder: (context, box) {
                      final stages = progress.visible;
                      final height = _top * 2 + stages.length * _gap;
                      if (!_scrolled) {
                        _scrolled = true;
                        final current = progress.currentIndex - progress.firstVisibleIndex;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scroll.hasClients) _scroll.jumpTo((_top + current * _gap - box.maxHeight * 0.3).clamp(0.0, _scroll.position.maxScrollExtent));
                        });
                      }
                      return SingleChildScrollView(
                        controller: _scroll,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: SizedBox(
                              height: height,
                              child: JourneyPath(progress: progress, width: math.min(box.maxWidth, 820), gap: _gap, top: _top),
                            ),
                          ),
                        ),
                      );
                    }),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The stages laid out along a winding path, top (where the child
/// started) to bottom (the adventures still ahead).
class JourneyPath extends ConsumerWidget {
  const JourneyPath({super.key, required this.progress, required this.width, required this.gap, required this.top});
  final JourneyProgress progress;
  final double width;
  final double gap;
  final double top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final stages = progress.visible;
    final island = width < 500 ? 118.0 : 150.0;
    final swing = math.min(width * 0.22, 190.0);
    // Zig-zag from the reading-start side.
    double sideOf(int i) => (i.isEven ? -1 : 1) * (rtl ? -1 : 1);
    Offset centre(int i) => Offset(width / 2 + sideOf(i) * swing, top + i * gap + island * 0.45);
    final currentLocal = progress.currentIndex - progress.firstVisibleIndex;

    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: CustomPaint(painter: _PathPainter([for (var i = 0; i < stages.length; i++) centre(i)], progress.finished ? stages.length : currentLocal))),
      for (var i = 0; i < stages.length; i++)
        Positioned(
          left: centre(i).dx - island / 2,
          top: centre(i).dy - island * 0.45,
          child: _StageNode(key: ValueKey('stage.${stages[i].stage.id}'), progress: stages[i], island: island, here: i == currentLocal && !progress.finished),
        ),
      for (var i = 0; i < stages.length; i++)
        Positioned(
          top: centre(i).dy + island * 0.55,
          left: sideOf(i) < 0 ? null : 0,
          right: sideOf(i) < 0 ? 0 : null,
          width: width / 2 + swing - island * 0.2,
          child: Align(
            alignment: sideOf(i) < 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: _StageSign(progress: stages[i], here: i == currentLocal && !progress.finished),
          ),
        ),
    ]);
  }
}

class _StageNode extends ConsumerWidget {
  const _StageNode({super.key, required this.progress, required this.island, required this.here});
  final StageProgress progress;
  final double island;
  final bool here;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = ref.watch(contentRuntimeProvider);
    final lang = ref.watch(languageProvider);
    final place = ActivityCategory.fromPlace(progress.stage.place);
    final locked = progress.status == StageStatus.locked;
    final name = contentText(content, progress.stage.nameKey, lang);
    final status = switch (progress.status) {
      StageStatus.completed => l10n.statusCompleted,
      StageStatus.current => l10n.youAreHere,
      StageStatus.locked => l10n.statusLocked,
      StageStatus.earlier => l10n.statusEarlier,
    };
    final node = Stack(clipBehavior: Clip.none, children: [
      if (here)
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: NovaShadow.glow(NovaStory.sunshine, strength: 0.65))),
        ),
      ColorFiltered(
        // Locked places are drawn in soft, misty colours: still solid, so
        // the trail passes behind them, but clearly not open yet.
        colorFilter: locked ? lockedMist : noFilter,
        child: NovaFloat(
          amplitude: locked ? 0 : 3,
          phase: progress.stage.index * 0.19,
          child: FloatingIsland(
            width: island,
            grass: locked ? const Color(0xFFB9C4B0) : place.scene.ground,
            childHeight: island * 0.72,
            child: Center(child: CategoryLandmark(category: place, size: island * 0.62)),
          ),
        ),
      ),
      if (here)
        PositionedDirectional(
          start: -island * 0.42,
          bottom: island * 0.2,
          child: SizedBox(width: island * 0.62, height: island * 0.62, child: ExcludeSemantics(child: CharacterView(kind: ref.watch(companionProvider), mood: CharacterMood.happy))),
        ),
      PositionedDirectional(
        top: 0,
        end: 0,
        child: _StatusDot(status: progress.status),
      ),
    ]);
    return Semantics(
      button: !locked,
      label: '$name. $status. ${l10n.stageDoneCount(numeral(progress.requiredDone, lang), numeral(progress.requiredTotal, lang))}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: locked ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => StageScreen(stageId: progress.stage.id))),
        child: SizedBox(width: island, child: node),
      ),
    );
  }
}


class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final StageStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      StageStatus.completed => (NovaStory.yes, Icons.check_rounded),
      StageStatus.current => (NovaStory.coral, Icons.flag_rounded),
      StageStatus.locked => (NovaStory.inkSoft, Icons.lock_rounded),
      StageStatus.earlier => (NovaStory.ocean, Icons.history_rounded),
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: NovaStory.cloud, width: 3), boxShadow: NovaShadow.contact),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _StageSign extends ConsumerWidget {
  const _StageSign({required this.progress, required this.here});
  final StageProgress progress;
  final bool here;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = ref.watch(contentRuntimeProvider);
    final lang = ref.watch(languageProvider);
    final locked = progress.status == StageStatus.locked;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: NovaSpace.md, vertical: NovaSpace.xs),
        decoration: BoxDecoration(
          color: here ? NovaStory.sunshine : NovaStory.cloud.withValues(alpha: locked ? 0.7 : 0.95),
          borderRadius: BorderRadius.circular(NovaRadius.lg),
          boxShadow: NovaShadow.contact,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contentText(content, progress.stage.nameKey, lang), style: NovaType.label(context, color: locked ? NovaStory.inkSoft : NovaStory.ink)),
          if (here) Text(l10n.youAreHere, style: NovaType.of(context, 12, weight: FontWeight.w800, color: NovaStory.plumDeep)),
          if (!locked && !here) Text(l10n.stageDoneCount(numeral(progress.requiredDone, lang), numeral(progress.requiredTotal, lang)), style: NovaType.of(context, 12, color: NovaStory.inkSoft)),
        ]),
      ),
    );
  }
}

/// The trail between stages: a sunny, solid path where the child has
/// been, and a dotted one to where they are going.
class _PathPainter extends CustomPainter {
  _PathPainter(this.points, this.walked);
  final List<Offset> points;

  /// Segments before this index have been travelled.
  final int walked;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i + 1 < points.length; i++) {
      final a = points[i], b = points[i + 1];
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, a.dy + (b.dy - a.dy) * 0.6, b.dx, a.dy + (b.dy - a.dy) * 0.4, b.dx, b.dy);
      final travelled = i < walked;
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x332E1A5C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round,
      );
      if (travelled) {
        canvas.drawPath(
          path,
          Paint()
            ..color = NovaStory.sunshine
            ..style = PaintingStyle.stroke
            ..strokeWidth = 16
            ..strokeCap = StrokeCap.round,
        );
      } else {
        for (final metric in path.computeMetrics()) {
          for (var d = 0.0; d < metric.length; d += 26) {
            final t = metric.getTangentForOffset(d);
            if (t != null) canvas.drawCircle(t.position, 5.5, Paint()..color = NovaStory.cloud);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.walked != walked || old.points.length != points.length || (points.isNotEmpty && old.points.first != points.first);
}

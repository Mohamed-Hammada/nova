import 'dart:async';

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
import '../world/category_screen.dart';
import 'journey_labels.dart';
import 'journey_providers.dart';
import 'play_activity.dart';

/// One adventure of the journey: its activities as stations in the
/// stage's place, each marked done, next, ready or locked.
class StageScreen extends ConsumerStatefulWidget {
  const StageScreen({super.key, required this.stageId});
  final String stageId;

  @override
  ConsumerState<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends ConsumerState<StageScreen> {
  final _guide = CharacterController();
  String? _say;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    _guide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = ref.watch(contentRuntimeProvider);
    final lang = ref.watch(languageProvider);
    final progress = ref.watch(journeyProgressProvider);
    final stageProgress = progress?.stages.where((s) => s.stage.id == widget.stageId).firstOrNull;
    if (progress == null || stageProgress == null) return const Scaffold(body: SizedBox.shrink());
    final stage = stageProgress.stage;
    final place = ActivityCategory.fromPlace(stage.place);
    final name = contentText(content, stage.nameKey, lang);

    return Scaffold(
      body: StoryScene(
        theme: place.scene,
        horizon: 0.42,
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth >= 760;
                  final gutter = wide ? NovaSpace.xl : NovaSpace.md;
                  final width = (box.maxWidth - gutter * 2).clamp(0.0, 1120.0);
                  final columns = (width / 240).floor().clamp(2, 4);
                  const gap = NovaSpace.md;
                  final stationWidth = (width - gap * (columns - 1)) / columns;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: width + gutter * 2,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(gutter, NovaSpace.sm, gutter, NovaSpace.xxl),
                        children: [
                          Row(
                            children: [
                              NovaRoundButton(
                                icon: Directionality.of(context) == TextDirection.rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                                label: l10n.myJourney,
                                color: place.deep,
                                onPressed: () => Navigator.of(context).maybePop(),
                              ),
                              const SizedBox(width: NovaSpace.md),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: NovaSpace.md, vertical: NovaSpace.xs),
                                  decoration: BoxDecoration(color: NovaStory.cloud.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(NovaRadius.lg), boxShadow: NovaShadow.contact),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Semantics(header: true, child: Text(name, style: NovaType.title(context))),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        height: 22,
                                        child: Align(
                                          alignment: AlignmentDirectional.centerStart,
                                          child: NovaTrailProgress(
                                            done: stageProgress.requiredDone,
                                            total: stageProgress.requiredTotal,
                                            semanticLabel: l10n.stageDoneCount(numeral(stageProgress.requiredDone, lang), numeral(stageProgress.requiredTotal, lang)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: NovaSpace.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: wide ? 140 : 100,
                                height: wide ? 140 : 100,
                                child: ExcludeSemantics(
                                  child: CharacterView(kind: ref.watch(companionProvider), controller: _guide, mood: CharacterMood.happy, entrance: Reaction.wave),
                                ),
                              ),
                              const SizedBox(width: NovaSpace.xs),
                              Flexible(
                                child: NovaSpeechBubble(text: l10n.weAreIn(name), size: wide ? 18 : 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: NovaSpace.lg),
                          Wrap(
                            spacing: gap,
                            runSpacing: gap * 1.5,
                            children: [
                              for (var i = 0; i < stage.activities.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(top: i.isOdd ? NovaSpace.lg : 0),
                                  child: _station(context, stage.activities[i], stageProgress.activities[stage.activities[i].id]!, stationWidth, i, lang),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // A hint pops up where the child is looking, not at the top of
              // a scrolled-away page.
              if (_say != null)
                PositionedDirectional(
                  start: NovaSpace.md,
                  end: NovaSpace.md,
                  bottom: NovaSpace.md,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: ExcludeSemantics(
                            child: CharacterView(kind: ref.watch(companionProvider), mood: CharacterMood.thinking),
                          ),
                        ),
                        Flexible(child: NovaSpeechBubble(text: _say!, size: 17)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _station(BuildContext context, Activity activity, ActivityStatus status, double width, int i, String lang) {
    final l10n = context.l10n;
    final content = ref.read(contentRuntimeProvider);
    final gameId = activity.gameFor(lang);
    if (!content.hasGame(gameId)) return const SizedBox.shrink();
    final game = content.game(gameId);
    return ActivityStation(
      key: ValueKey('activity.${activity.id}'),
      game: game,
      category: ActivityCategory.of(game),
      width: width,
      phase: i * 0.21,
      locked: status == ActivityStatus.locked,
      highlight: status == ActivityStatus.recommended,
      status: '${activityStatusLabel(l10n, status)}. ${roleLabel(l10n, activity.role)}',
      badge: JourneyBadge(status: status),
      onTap: () async {
        if (status == ActivityStatus.locked) {
          // A locked activity explains itself instead of doing nothing.
          setState(() => _say = l10n.unlockHint);
          _guide.setMood(CharacterMood.thinking, hold: const Duration(milliseconds: 1500));
          _hide?.cancel();
          _hide = Timer(const Duration(seconds: 4), () {
            if (mounted) setState(() => _say = null);
          });
          return;
        }
        _guide.setMood(CharacterMood.excited, hold: const Duration(milliseconds: 700));
        await playJourneyActivity(context, ref, activity);
        if (mounted) setState(() => _say = null);
      },
    );
  }
}

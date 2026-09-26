import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/characters/character_rig.dart';
import 'package:nova_app/ui/characters/character_view.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/ui/journey/journey_labels.dart';
import 'package:nova_app/ui/journey/journey_map_screen.dart';
import 'package:nova_app/ui/journey/journey_providers.dart';
import 'package:nova_app/ui/journey/play_activity.dart';
import 'package:nova_app/ui/journey/stage_screen.dart';
import 'package:nova_app/ui/play/visual_view.dart';
import 'package:nova_app/ui/progress/progress_screen.dart';
import 'package:nova_app/ui/scene/story_scene.dart';
import 'package:nova_app/ui/settings/face_play.dart';
import 'package:nova_app/ui/settings/profile_screen.dart';
import 'package:nova_app/ui/shell/language_menu.dart';
import 'package:nova_app/ui/widgets/props.dart';
import 'package:nova_app/ui/world/activity_world.dart';
import 'package:nova_app/ui/world/activity_station.dart';
import 'package:nova_app/ui/world/open_activity.dart';
import 'package:nova_app/ui/world/world_providers.dart';

/// Home: the child's own corner of the Nova world, built around their
/// journey.
///
/// Read top to bottom it answers, in order: who is my friend (the companion
/// greeting the child by name), what should I do next (one big "continue"
/// action on the adventure the child is on), where am I on my journey (done,
/// here, ahead), a few other things Nova offers right now, and what have I
/// done (stars and badges). The child never picks a developmental area: the
/// curriculum engine decides what comes next and what else is open, and
/// Home only shows its answer.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final journey = ref.watch(journeyProgressProvider);
    final explore = ref.watch(exploreActivitiesProvider);
    // Without a curriculum (an older bundle) there is still one next game.
    final empty = journey == null && ref.watch(offeredGamesProvider).isEmpty;
    return Scaffold(
      body: StoryScene(
        theme: SceneTheme.meadow,
        horizon: 0.5,
        child: SafeArea(
          child: empty
              ? NovaEmptyView(title: l10n.emptyGamesTitle, body: l10n.emptyGamesBody, icon: Icons.extension_rounded)
              : LayoutBuilder(
                  builder: (context, box) {
                    final wide = box.maxWidth >= 760;
                    final gutter = wide ? NovaSpace.xl : NovaSpace.md;
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(gutter, NovaSpace.sm, gutter, NovaSpace.xxl),
                          children: [
                            const _TopBar(),
                            const SizedBox(height: NovaSpace.md),
                            _Hero(wide: wide),
                            if (journey != null) ...[const SizedBox(height: NovaSpace.xl), _SectionTitle(l10n.myJourney), const SizedBox(height: NovaSpace.sm), _JourneyStrip(progress: journey)],
                            if (journey != null && explore.isNotEmpty) ...[
                              const SizedBox(height: NovaSpace.xl),
                              _SectionTitle(l10n.exploreMore),
                              const SizedBox(height: NovaSpace.sm),
                              _Explore(progress: journey, activities: explore),
                            ],
                            const SizedBox(height: NovaSpace.xl),
                            _SectionTitle(l10n.myTreasures),
                            const SizedBox(height: NovaSpace.sm),
                            const _Treasures(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: NovaSpace.md, vertical: NovaSpace.xxs),
      decoration: BoxDecoration(color: NovaStory.cloud.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(NovaRadius.pill)),
      child: Semantics(header: true, child: Text(text, style: NovaType.title(context))),
    ),
  );
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final stars = (ref.watch(levelStarsProvider).value ?? const <String, int>{}).values.fold<int>(0, (a, b) => a + b);
    final name = ref.watch(childNameProvider).trim();
    // With very large text on a phone the name would crowd the controls;
    // the face alone still opens "About me".
    final showName = MediaQuery.sizeOf(context).width >= 600 || MediaQuery.textScalerOf(context).scale(10) <= 13;
    return Row(
      children: [
        // The child's own badge: their friend's face and their name. It takes
        // all the free space (aligned to the start), so the name has room.
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              button: true,
              label: l10n.aboutMe,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
                child: Container(
                  padding: EdgeInsetsDirectional.fromSTEB(4, 4, showName ? 16 : 4, 4),
                  constraints: const BoxConstraints(minHeight: NovaSize.childTouch - 8),
                  decoration: BoxDecoration(color: NovaStory.cloud, borderRadius: BorderRadius.circular(NovaRadius.pill), boxShadow: NovaShadow.soft),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Avatar(kind: ref.watch(companionProvider), size: 48),
                      if (showName) const SizedBox(width: NovaSpace.xs),
                      if (showName)
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(name.isEmpty ? l10n.aboutMe : name, style: NovaType.label(context), overflow: TextOverflow.ellipsis, maxLines: 1),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: NovaSpace.xs),
        NovaStarBadge(label: numeral(stars, lang), semanticLabel: l10n.starsCollected(numeral(stars, lang))),
        const SizedBox(width: NovaSpace.xs),
        DecoratedBox(
          decoration: BoxDecoration(color: NovaStory.cloud, shape: BoxShape.circle, boxShadow: NovaShadow.soft),
          child: const SizedBox(width: 52, height: 52, child: Center(child: LanguageMenuButton(iconOnly: true))),
        ),
        const SizedBox(width: NovaSpace.xs),
        NovaRoundButton(
          icon: Icons.family_restroom_rounded,
          label: l10n.grownUps,
          color: NovaStory.plum,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProgressScreen())),
        ),
      ],
    );
  }
}

/// A character's head and shoulders in a round frame.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.kind, required this.size});
  final CharacterKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFE9B8)),
    clipBehavior: Clip.antiAlias,
    // Framed on the head: the head sits about 40% down the character's box.
    child: OverflowBox(
      maxHeight: size * 2.6,
      maxWidth: size * 2.6,
      alignment: const Alignment(0, -0.36),
      child: SizedBox(
        width: size * 2.6,
        height: size * 2.6,
        child: ExcludeSemantics(child: CharacterView(kind: kind)),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Hero: companion + the next adventure
// ---------------------------------------------------------------------------

class _Hero extends ConsumerStatefulWidget {
  const _Hero({required this.wide});
  final bool wide;

  @override
  ConsumerState<_Hero> createState() => _HeroState();
}

class _HeroState extends ConsumerState<_Hero> {
  final _guide = CharacterController();

  @override
  void dispose() {
    _guide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final companion = ref.watch(companionProvider);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final friend = rtl ? companion.displayNameAr : companion.displayName;
    final child = ref.watch(childNameProvider).trim();
    // "Welcome back" once the child has played; before that, a beginning.
    final returning = (ref.watch(activityRecordsProvider).value ?? const {}).isNotEmpty;
    final greeting = returning ? (child.isEmpty ? l10n.welcomeBackNoName : l10n.welcomeBack(child)) : (child.isEmpty ? l10n.onboardingReadyNoName : l10n.onboardingReady(child));
    // The companion names the adventure the child is on.
    final journey = ref.watch(journeyProgressProvider);
    // The companion says why the next activity was chosen -- from the same
    // curriculum/adaptive recommendation the button plays.
    final adventure = journey == null
        ? l10n.letsExplore
        : journey.finished
        ? l10n.journeyAllDone
        : switch (journey.recommendation?.reason) {
            RecommendationReason.practice => l10n.recPractice,
            RecommendationReason.tryAgainEasier => l10n.recTryAgain,
            RecommendationReason.stretch => l10n.scaffoldIndependent,
            _ => l10n.weAreIn(contentText(ref.watch(contentRuntimeProvider), journey.current.stage.nameKey, ref.watch(languageProvider))),
          };

    final stage = FloatingIsland(
      width: widget.wide ? 300 : 170,
      childHeight: widget.wide ? 290 : 170,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _guide.react(Reaction.wave),
              child: Semantics(
                label: friend,
                child: CharacterView(key: ValueKey(companion), kind: companion, controller: _guide, entrance: Reaction.wave),
              ),
            ),
          ),
          PositionedDirectional(top: 0, end: 0, child: FacePlay(controller: _guide)),
        ],
      ),
    );

    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            greeting,
            style: NovaType.of(context, widget.wide ? 30 : 23, weight: FontWeight.w800, color: NovaStory.plumDeep).copyWith(shadows: const [Shadow(color: Color(0xCCFFFFFF), blurRadius: 12)]),
          ),
        ),
        const SizedBox(height: NovaSpace.xs),
        NovaSpeechBubble(text: '${l10n.companionHello(friend)} $adventure', tail: BubbleTail.start, size: widget.wide ? 18 : 15),
      ],
    );

    final next = _NextAdventure(onPlay: () => _guide.setMood(CharacterMood.excited, hold: const Duration(milliseconds: 900)));

    if (widget.wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NovaFloat(amplitude: 5, child: stage),
          const SizedBox(width: NovaSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                words,
                const SizedBox(height: NovaSpace.lg),
                next,
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            NovaFloat(amplitude: 4, child: stage),
            const SizedBox(width: NovaSpace.xs),
            Expanded(child: words),
          ],
        ),
        const SizedBox(height: NovaSpace.md),
        next,
      ],
    );
  }
}

/// The one thing to do next: the activity the curriculum engine recommends
/// (or, without a curriculum, the first activity), with one big button.
class _NextAdventure extends ConsumerWidget {
  const _NextAdventure({required this.onPlay});
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final content = ref.watch(contentRuntimeProvider);
    final progress = ref.watch(journeyProgressProvider);
    final activity = progress?.recommended;

    Game? game;
    if (activity != null && content.hasGame(activity.gameFor(lang))) game = content.game(activity.gameFor(lang));
    final fallback = ref.watch(offeredGamesProvider);
    final useJourney = game != null;
    game ??= fallback.isEmpty ? null : fallback.first;
    if (game == null) return const SizedBox.shrink();
    final stage = useJourney ? progress!.current : null;
    // The adventure's place dresses the card; outside a journey, the game's.
    final category = stage != null ? ActivityCategory.fromPlace(stage.stage.place) : ActivityCategory.of(game);
    final gameName = contentText(content, game.nameKey, lang);
    final started = (ref.watch(activityRecordsProvider).value ?? const {}).isNotEmpty;

    Future<void> play() async {
      onPlay();
      if (useJourney) {
        await playJourneyActivity(context, ref, activity!);
      } else {
        await openActivity(context, game!);
      }
    }

    return NovaPanel(
      padding: const EdgeInsets.all(NovaSpace.md),
      child: LayoutBuilder(
        builder: (context, box) {
          final narrow = box.maxWidth < 420;
          final info = Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: category.color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(NovaRadius.md)),
                child: Center(child: CategoryLandmark(category: category, size: 62)),
              ),
              const SizedBox(width: NovaSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stage != null) ...[
                      Text(l10n.currentAdventure, style: NovaType.label(context, color: category.deep)),
                      Text(contentText(content, stage.stage.nameKey, lang), key: const ValueKey('home.stage'), style: NovaType.title(context), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ] else
                      Text(started ? l10n.continueJourney : l10n.startJourney, style: NovaType.title(context)),
                    const SizedBox(height: 2),
                    Text(gameName, key: const ValueKey('home.next'), style: NovaType.body(context), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    if (stage != null)
                      SizedBox(
                        height: 22,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: NovaTrailProgress(
                            done: stage.requiredDone,
                            total: stage.requiredTotal,
                            semanticLabel: l10n.stageDoneCount(numeral(stage.requiredDone, lang), numeral(stage.requiredTotal, lang)),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: category.color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(NovaRadius.pill)),
                        child: Text(category.title(l10n), style: NovaType.label(context, color: category.deep)),
                      ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: NovaSpace.sm,
            runSpacing: NovaSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [NovaPlayButton(key: const ValueKey('home.continue'), label: started ? l10n.continueJourney : l10n.letsGo, onPressed: play, size: 56)],
          );
          return narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: NovaSpace.md),
                    actions,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: NovaSpace.md),
                    actions,
                  ],
                );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My journey: past, here, ahead
// ---------------------------------------------------------------------------

/// A glance at the journey around where the child is: the adventures just
/// finished, the one they are on, and the ones waiting -- each a little
/// island on a path. Tapping opens the full map.
class _JourneyStrip extends ConsumerWidget {
  const _JourneyStrip({required this.progress});
  final JourneyProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final content = ref.watch(contentRuntimeProvider);
    final from = (progress.currentIndex - 2).clamp(progress.firstVisibleIndex, progress.currentIndex);
    final to = (progress.currentIndex + 2).clamp(progress.currentIndex, progress.stages.length - 1);
    final shown = progress.stages.sublist(from, to + 1);
    Future<void> openMap() async {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const JourneyMapScreen()));
      ref.invalidate(activityRecordsProvider);
    }

    return NovaPanel(
      padding: const EdgeInsets.fromLTRB(NovaSpace.sm, NovaSpace.md, NovaSpace.sm, NovaSpace.sm),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final slot = box.maxWidth / shown.length;
              final island = (slot * 0.78).clamp(56.0, 120.0);
              return SizedBox(
                height: island * 0.62 + island * 0.32 + 44,
                child: Stack(
                  children: [
                    // The path runs through the islands, sunny where the child has been.
                    Positioned(
                      left: slot / 2,
                      right: slot / 2,
                      top: island * 0.5,
                      child: Row(
                        children: [
                          for (var i = 0; i < shown.length - 1; i++)
                            Expanded(
                              child: Container(
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: shown[i + 1].status == StageStatus.locked ? NovaStory.cloud : NovaStory.sunshine,
                                  borderRadius: BorderRadius.circular(NovaRadius.pill),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        for (final s in shown)
                          SizedBox(
                            width: slot,
                            child: _StripStop(progress: s, island: island, name: contentText(content, s.stage.nameKey, lang), l10n: l10n),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: NovaSpace.xs),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const ValueKey('home.map'),
              onPressed: openMap,
              icon: const Icon(Icons.map_rounded),
              label: Text(l10n.journeyMap),
              style: TextButton.styleFrom(foregroundColor: NovaStory.plum, textStyle: NovaType.label(context), minimumSize: const Size(NovaSize.minTouch, NovaSize.minTouch)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripStop extends ConsumerWidget {
  const _StripStop({required this.progress, required this.island, required this.name, required this.l10n});
  final StageProgress progress;
  final double island;
  final String name;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ActivityCategory.fromPlace(progress.stage.place);
    final locked = progress.status == StageStatus.locked;
    final here = progress.status == StageStatus.current;
    final status = switch (progress.status) {
      StageStatus.completed => l10n.statusCompleted,
      StageStatus.current => l10n.youAreHere,
      StageStatus.locked => l10n.statusLocked,
      StageStatus.earlier => l10n.statusEarlier,
    };
    return Semantics(
      key: ValueKey('home.stage.${progress.stage.id}'),
      button: !locked,
      label: '$name. $status',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: locked ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => StageScreen(stageId: progress.stage.id))),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ColorFiltered(
                  colorFilter: locked ? lockedMist : noFilter,
                  child: FloatingIsland(
                    width: island,
                    grass: locked ? const Color(0xFFB9C4B0) : place.scene.ground,
                    childHeight: island * 0.62,
                    child: Center(
                      child: CategoryLandmark(category: place, size: island * 0.56),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: -4,
                  end: -4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: switch (progress.status) {
                        StageStatus.completed => NovaStory.yes,
                        StageStatus.current => NovaStory.coral,
                        StageStatus.locked => NovaStory.inkSoft,
                        StageStatus.earlier => NovaStory.ocean,
                      },
                      border: Border.all(color: NovaStory.cloud, width: 2),
                    ),
                    child: Icon(
                      switch (progress.status) {
                        StageStatus.completed => Icons.check_rounded,
                        StageStatus.current => Icons.flag_rounded,
                        StageStatus.locked => Icons.lock_rounded,
                        StageStatus.earlier => Icons.history_rounded,
                      },
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: here ? NovaStory.sunshine : Colors.transparent, borderRadius: BorderRadius.circular(NovaRadius.pill)),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: NovaType.of(context, 12, weight: FontWeight.w800, color: locked ? NovaStory.inkSoft : NovaStory.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Explore more
// ---------------------------------------------------------------------------

/// A few other activities Nova offers right now, small beside the journey:
/// extra work in the current adventure and favourites to replay. They come
/// from the curriculum engine (never the whole catalog), so each is open,
/// made for the child's age and played as part of the journey.
class _Explore extends ConsumerWidget {
  const _Explore({required this.progress, required this.activities});
  final JourneyProgress progress;
  final List<Activity> activities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentRuntimeProvider);
    final lang = ref.watch(languageProvider);
    final stages = {for (final s in progress.stages) s.stage.id: s.stage};
    return NovaPanel(
      padding: const EdgeInsets.all(NovaSpace.md),
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = NovaSpace.md;
          final columns = (box.maxWidth / 170).floor().clamp(2, 4);
          final w = (box.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < activities.length; i++)
                if (content.hasGame(activities[i].gameFor(lang)))
                  ActivityStation(
                    key: ValueKey('explore.${activities[i].id}'),
                    game: content.game(activities[i].gameFor(lang)),
                    category: ActivityCategory.fromPlace(stages[activities[i].stageId]?.place ?? 'numbers'),
                    width: w,
                    phase: i * 0.21,
                    onTap: () => playJourneyActivity(context, ref, activities[i]),
                  ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Treasures
// ---------------------------------------------------------------------------

class _Treasures extends ConsumerWidget {
  const _Treasures();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final stars = ref.watch(levelStarsProvider).value ?? const <String, int>{};
    final total = stars.values.fold<int>(0, (a, b) => a + b);
    final levels = stars.length;
    final badges = [
      (l10n.badgeFirstSteps, Icons.directions_walk_rounded, NovaStory.coral, levels >= 1),
      (l10n.badgeStarCatcher, Icons.auto_awesome_rounded, NovaStory.honey, total >= 10),
      (l10n.badgeExplorer, Icons.explore_rounded, NovaStory.teal, levels >= 10),
    ];
    return NovaPanel(
      padding: const EdgeInsets.all(NovaSpace.md),
      child: Wrap(
        spacing: NovaSpace.lg,
        runSpacing: NovaSpace.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StarShape(size: 44),
              const SizedBox(width: NovaSpace.xs),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.starsCollected(numeral(total, lang)), style: NovaType.title(context)),
                    Text(l10n.levelsExplored(numeral(levels, lang)), style: NovaType.body(context)),
                  ],
                ),
              ),
            ],
          ),
          for (final (label, icon, color, earned) in badges)
            Tooltip(
              message: earned ? label : l10n.badgeLocked,
              child: Semantics(
                label: earned ? label : '$label. ${l10n.badgeLocked}',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: earned ? color : const Color(0xFFE7E1EF), boxShadow: earned ? NovaShadow.glow(color, strength: 0.4) : null),
                      child: Icon(earned ? icon : Icons.lock_rounded, color: earned ? Colors.white : const Color(0xFF9D93AE), size: 28),
                    ),
                    const SizedBox(width: NovaSpace.xs),
                    Flexible(
                      child: Text(label, style: NovaType.label(context, color: earned ? NovaStory.ink : NovaStory.inkSoft)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

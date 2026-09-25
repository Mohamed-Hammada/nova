import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/characters/character_rig.dart';
import 'package:nova_app/ui/characters/character_view.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/play/journey_screen.dart';
import 'package:nova_app/ui/play/visual_view.dart';
import 'package:nova_app/ui/progress/progress_screen.dart';
import 'package:nova_app/ui/scene/story_scene.dart';
import 'package:nova_app/ui/settings/face_play.dart';
import 'package:nova_app/ui/settings/profile_screen.dart';
import 'package:nova_app/ui/shell/language_menu.dart';
import 'package:nova_app/ui/widgets/props.dart';
import 'package:nova_app/ui/world/activity_world.dart';
import 'package:nova_app/ui/world/category_screen.dart';
import 'package:nova_app/ui/world/open_activity.dart';
import 'package:nova_app/ui/world/world_providers.dart';

/// Home: the child's own corner of the Nova world.
///
/// Read top to bottom it answers, in order: who is my friend (the companion
/// greeting the child by name), what should I do next (one big "continue"
/// action), where can I go (the places, each a floating island), and what
/// have I done (stars and badges). Only the next step is loud; everything
/// else waits a scroll away.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final places = ref.watch(placesProvider);
    return Scaffold(
      body: StoryScene(
        theme: SceneTheme.meadow,
        horizon: 0.5,
        child: SafeArea(
          child: places.isEmpty
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
                            const SizedBox(height: NovaSpace.xl),
                            _SectionTitle(l10n.placesToExplore),
                            const SizedBox(height: NovaSpace.sm),
                            LayoutBuilder(
                              builder: (context, inner) => _Places(places: places, width: inner.maxWidth),
                            ),
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
        // The child's own badge: their friend's face and their name.
        Flexible(
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
        const SizedBox(width: NovaSpace.xs),
        const Spacer(),
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
    final greeting = child.isEmpty ? l10n.welcomeBackNoName : l10n.welcomeBack(child);

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
            style: NovaType.display(context, color: NovaStory.plumDeep).copyWith(shadows: const [Shadow(color: Color(0xCCFFFFFF), blurRadius: 12)]),
          ),
        ),
        const SizedBox(height: NovaSpace.xs),
        NovaSpeechBubble(text: '${l10n.companionHello(friend)} ${l10n.letsExplore}', tail: BubbleTail.start, size: widget.wide ? 18 : 15),
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

/// The one thing to do next: the next level of the child's journey (or,
/// without a journey, the first activity), with one big button.
class _NextAdventure extends ConsumerWidget {
  const _NextAdventure({required this.onPlay});
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final content = ref.watch(contentRuntimeProvider);
    final journey = ref.watch(currentJourneyProvider);
    final stars = ref.watch(levelStarsProvider).value ?? const <String, int>{};
    final index = nextLevelIndex(journey, stars);
    final started = stars.isNotEmpty;

    Game? game;
    if (journey != null && index != null) {
      final id = journey.levels[index].gameFor(lang);
      if (content.hasGame(id)) game = content.game(id);
    }
    final fallback = ref.watch(offeredGamesProvider);
    final useJourney = game != null;
    game ??= fallback.isEmpty ? null : fallback.first;
    if (game == null) return const SizedBox.shrink();
    final category = ActivityCategory.of(game);
    final gameName = contentText(content, game.nameKey, lang);
    final subtitle = useJourney ? '${l10n.levelLabel(numeral(index! + 1, lang))} · $gameName' : gameName;

    Future<void> play() async {
      onPlay();
      if (useJourney) {
        await openJourneyLevel(context, ref, journey!, index!);
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
                    Text(started ? l10n.continueJourney : l10n.startJourney, style: NovaType.title(context)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: NovaType.body(context), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
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
            children: [
              NovaPlayButton(label: l10n.playGame, onPressed: play, size: 56),
              if (journey != null)
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const JourneyScreen()));
                    ref.invalidate(levelStarsProvider);
                  },
                  icon: const Icon(Icons.map_rounded),
                  label: Text(l10n.journeyMap),
                  style: TextButton.styleFrom(foregroundColor: NovaStory.plum, textStyle: NovaType.label(context)),
                ),
            ],
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
// Places
// ---------------------------------------------------------------------------

class _Places extends ConsumerWidget {
  const _Places({required this.places, required this.width});
  final Map<ActivityCategory, List<Game>> places;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = (width / 170).floor().clamp(2, 4);
    const gap = NovaSpace.md;
    final w = (width - gap * (columns - 1)) / columns;
    var i = 0;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final MapEntry(key: category, value: games) in places.entries) _Place(key: ValueKey('place.${category.name}'), category: category, count: games.length, width: w, phase: (i++) * 0.17),
      ],
    );
  }
}

/// One place: its landmark on a floating island, its name and how many
/// activities wait there.
class _Place extends ConsumerWidget {
  const _Place({super.key, required this.category, required this.count, required this.width, required this.phase});
  final ActivityCategory category;
  final int count;
  final double width;
  final double phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final name = category.title(l10n);
    final islandWidth = width * 0.78;
    return Semantics(
      button: true,
      label: '$name. ${l10n.activitiesCount(numeral(count, lang))}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CategoryScreen(category: category))),
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(NovaSpace.xs, NovaSpace.sm, NovaSpace.xs, NovaSpace.sm),
          decoration: BoxDecoration(color: NovaStory.cloud.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(NovaRadius.xl)),
          child: Column(
            children: [
              NovaFloat(
                phase: phase,
                amplitude: 4,
                child: FloatingIsland(
                  width: islandWidth,
                  grass: category.scene.ground,
                  childHeight: islandWidth * 0.78,
                  child: Center(
                    child: CategoryLandmark(category: category, size: islandWidth * 0.72),
                  ),
                ),
              ),
              const SizedBox(height: NovaSpace.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(NovaRadius.pill), boxShadow: NovaShadow.contact),
                child: Text(
                  name,
                  style: NovaType.label(context, color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.activitiesCount(numeral(count, lang)),
                style: NovaType.of(context, 13, weight: FontWeight.w700, color: NovaStory.ink),
              ),
            ],
          ),
        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_view.dart';
import '../design/nova_design.dart';
import '../game/game_catalog.dart';
import '../l10n.dart';
import '../play/game_art.dart';
import '../journey/journey_providers.dart';
import '../scene/story_scene.dart';
import 'activity_world.dart';
import 'open_activity.dart';
import 'world_providers.dart';

/// One place in the Nova world. Its activities stand on little islands in
/// the place's own landscape, and the companion is there to welcome the
/// child in.
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.category});
  final ActivityCategory category;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _guide = CharacterController();

  @override
  void dispose() {
    _guide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.category;
    final games = ref.watch(placesProvider)[c] ?? const <Game>[];
    return Scaffold(
      body: StoryScene(
        theme: c.scene,
        horizon: 0.42,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 760;
              final gutter = wide ? NovaSpace.xl : NovaSpace.md;
              final width = (box.maxWidth - gutter * 2).clamp(0.0, 1120.0);
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
                            label: l10n.backHome,
                            color: c.deep,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: NovaSpace.md),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                c.title(l10n),
                                style: NovaType.display(context, color: Colors.white).copyWith(
                                  shadows: const [Shadow(color: Color(0x662E1A5C), blurRadius: 10, offset: Offset(0, 2))],
                                ),
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
                            width: wide ? 150 : 104,
                            height: wide ? 150 : 104,
                            child: ExcludeSemantics(
                              child: CharacterView(kind: ref.watch(companionProvider), controller: _guide, mood: CharacterMood.curious, entrance: Reaction.wave),
                            ),
                          ),
                          const SizedBox(width: NovaSpace.xs),
                          Flexible(
                            child: NovaSpeechBubble(text: c.tagline(l10n), size: wide ? 18 : 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: NovaSpace.lg),
                      _Stations(
                        games: games,
                        category: c,
                        width: width,
                        onOpen: (game) async {
                          _guide.setMood(CharacterMood.excited, hold: const Duration(milliseconds: 700));
                          await openActivity(context, game);
                          ref.invalidate(levelStarsProvider);
                          ref.invalidate(activityRecordsProvider);
                        },
                      ),
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

class _Stations extends StatelessWidget {
  const _Stations({required this.games, required this.category, required this.width, required this.onOpen});
  final List<Game> games;
  final ActivityCategory category;
  final double width;
  final ValueChanged<Game> onOpen;

  /// Columns for the space available: two on a phone, up to four on a wide
  /// screen, never narrower than a comfortable station.
  static int columnsFor(double width) => (width / 240).floor().clamp(2, 4);

  @override
  Widget build(BuildContext context) {
    final columns = columnsFor(width);
    const gap = NovaSpace.md;
    final w = (width - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap * 1.5,
      children: [
        for (var i = 0; i < games.length; i++)
          // A gentle zig-zag breaks the grid's rhythm: stations sit at
          // slightly different heights, like stops along a path.
          Padding(
            padding: EdgeInsets.only(top: i.isOdd ? NovaSpace.lg : 0),
            child: ActivityStation(key: ValueKey('station.${games[i].id}'), game: games[i], category: category, width: w, phase: i * 0.21, onTap: () => onOpen(games[i])),
          ),
      ],
    );
  }
}

/// One activity: its picture in a round window standing on an island, with
/// its name on a signboard below. The whole station is one big button.
class ActivityStation extends ConsumerWidget {
  const ActivityStation({
    super.key,
    required this.game,
    required this.category,
    required this.width,
    required this.onTap,
    this.phase = 0,
    this.badge,
    this.locked = false,
    this.highlight = false,
    this.status,
  });
  final Game game;
  final ActivityCategory category;
  final double width;
  final VoidCallback onTap;
  final double phase;

  /// A corner badge: done, next, locked...
  final Widget? badge;

  /// Shown faded; still tappable (the screen explains why it is locked).
  final bool locked;

  /// The recommended activity glows.
  final bool highlight;

  /// Spoken status, added to the screen-reader label.
  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = ref.watch(contentRuntimeProvider);
    final lang = ref.watch(languageProvider);
    final name = contentText(content, game.nameKey, lang);
    final island = width * 0.86;
    final window = island * 0.66;
    final art = playableGames[game.id]?.cardArt(context) ?? gameArt(game, window, lang);
    return Semantics(
      button: true,
      label: status == null ? '$name. ${l10n.playGame}' : '$name. $status',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: locked ? 0.55 : 1,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                NovaFloat(
                  phase: phase,
                  amplitude: locked ? 0 : 4,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FloatingIsland(
                        width: island,
                        grass: category.scene.ground,
                        childHeight: window * 1.02,
                        child: Center(
                          child: Container(
                            width: window,
                            height: window,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [Color.lerp(category.color, Colors.white, 0.9)!, Color.lerp(category.color, Colors.white, 0.62)!]),
                              border: Border.all(color: highlight ? NovaStory.sunshine : NovaStory.cloud, width: highlight ? 7 : 5),
                              boxShadow: highlight ? NovaShadow.glow(NovaStory.sunshine) : NovaShadow.soft,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: EdgeInsets.all(window * 0.12),
                              child: FittedBox(fit: BoxFit.contain, child: art),
                            ),
                          ),
                        ),
                      ),
                      if (badge != null) PositionedDirectional(top: 0, end: (width - island) / 2, child: badge!),
                    ],
                  ),
                ),
                const SizedBox(height: NovaSpace.xs),
                Container(
                  constraints: const BoxConstraints(minHeight: NovaSize.childTouch),
                  padding: const EdgeInsets.symmetric(horizontal: NovaSpace.md, vertical: NovaSpace.xs),
                  decoration: BoxDecoration(color: NovaStory.cloud, borderRadius: BorderRadius.circular(NovaRadius.lg), boxShadow: NovaShadow.soft),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(name, style: NovaType.label(context), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: NovaSpace.xs),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: locked ? NovaStory.inkSoft : category.color, shape: BoxShape.circle),
                        child: Icon(locked ? Icons.lock_rounded : Icons.play_arrow_rounded, color: Colors.white, size: locked ? 20 : 26),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

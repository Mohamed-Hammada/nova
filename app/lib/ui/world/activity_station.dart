import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';

import '../design/nova_design.dart';
import '../game/game_catalog.dart';
import '../l10n.dart';
import '../play/game_art.dart';
import '../scene/story_scene.dart';
import 'activity_world.dart';

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

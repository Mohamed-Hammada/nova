import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';
import 'package:nova_app/ui/game/art/game_art.dart';

/// A reusable multi-layered illustrated game scene viewport.
/// Renders environment layers (sky, hills, foliage), floor mats,
/// interactive playfield, and overlay effects with responsive layout.
class GameScene extends StatelessWidget {
  const GameScene({
    super.key,
    required this.backgroundId,
    required this.pileZone,
    required this.targetZone,
    this.environmentElements = const [],
    this.promptWidget,
    this.overlay,
  });

  final String backgroundId;
  final Widget pileZone;
  final Widget targetZone;
  final List<String> environmentElements;
  final Widget? promptWidget;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;

      Widget playfield = wide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: pileZone),
                  const SizedBox(width: NovaSpace.lg),
                  Expanded(child: targetZone),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                targetZone,
                const SizedBox(height: NovaSpace.md),
                pileZone,
              ],
            );

      final sceneContent = Stack(
        children: [
          // Background layer
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(NovaRadius.lg),
              child: GameArt.environment(
                environmentId: backgroundId.contains('bg') ? backgroundId : '${backgroundId}_bg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Environment decorations (e.g. sun, clouds, tree branch)
          if (environmentElements.contains('sun'))
            PositionedDirectional(
              top: NovaSpace.sm,
              end: NovaSpace.xl,
              child: Opacity(
                opacity: 0.9,
                child: GameArt.environment(
                  environmentId: 'sun_warm',
                  width: 90,
                  height: 90,
                ),
              ),
            ),

          if (environmentElements.contains('cloud'))
            PositionedDirectional(
              top: NovaSpace.md,
              start: NovaSpace.lg,
              child: Opacity(
                opacity: 0.85,
                child: GameArt.environment(
                  environmentId: 'cloud_fluffy',
                  width: 140,
                  height: 75,
                ),
              ),
            ),

          if (environmentElements.contains('tree_branch'))
            PositionedDirectional(
              top: 0,
              start: 0,
              child: GameArt.environment(
                environmentId: 'tree_branch',
                width: 220,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),

          // Interactive playfield
          Padding(
            padding: const EdgeInsets.all(NovaSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (promptWidget != null) ...[
                  promptWidget!,
                  const SizedBox(height: NovaSpace.md),
                ],
                playfield,
              ],
            ),
          ),

          // Feedback / celebration overlay
          if (overlay != null) Positioned.fill(child: overlay!),
        ],
      );

      return sceneContent;
    });
  }
}

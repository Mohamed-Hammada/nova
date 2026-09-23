import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/game/art/game_art.dart';

/// A joyful celebration screen for session completion with animated particles,
/// celebrating character, and child-optimized navigation buttons.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.characterId,
    required this.title,
    required this.subtitle,
    required this.playAgainLabel,
    required this.homeLabel,
    required this.grownUpsLabel,
    required this.onPlayAgain,
    required this.onHome,
    required this.onGrownUps,
  });

  final String characterId;
  final String title;
  final String subtitle;
  final String playAgainLabel;
  final String homeLabel;
  final String grownUpsLabel;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;
  final VoidCallback onGrownUps;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _playCelebration();
  }

  void _playCelebration() {
    if (!mounted) return;
    _celebrationController.forward().then((_) {
      if (mounted) {
        _celebrationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = NovaMotion.reduced(context);

    Widget characterArt = GameArt.character(
      characterId: widget.characterId,
      state: CharacterVisualState.celebrate,
      size: 180,
    );

    if (!reduced) {
      characterArt = AnimatedBuilder(
        animation: _celebrationController,
        builder: (context, child) {
          final t = _celebrationController.value;
          final bounce = math.sin(t * math.pi) * 12.0;
          return Transform.translate(
            offset: Offset(0, -bounce),
            child: child,
          );
        },
        child: characterArt,
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: NovaSpace.xl, horizontal: NovaSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (!reduced) ...[
                  PositionedDirectional(
                    top: -10,
                    start: 20,
                    child: GameArt.feedback(effectId: 'star_gold', size: 42),
                  ),
                  PositionedDirectional(
                    top: 10,
                    end: 30,
                    child: GameArt.feedback(effectId: 'sparkle', size: 36),
                  ),
                ],
                Center(child: characterArt),
              ],
            ),
            const SizedBox(height: NovaSpace.lg),
            Semantics(
              liveRegion: true,
              header: true,
              child: Text(
                widget.title,
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: NovaSpace.xs),
            Text(
              widget.subtitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NovaSpace.xl),
            NovaButton(
              label: widget.playAgainLabel,
              icon: Icons.replay_rounded,
              size: NovaButtonSize.child,
              expand: true,
              autofocus: true,
              onPressed: widget.onPlayAgain,
            ),
            const SizedBox(height: NovaSpace.sm),
            NovaButton(
              label: widget.homeLabel,
              icon: Icons.home_rounded,
              variant: NovaButtonVariant.secondary,
              size: NovaButtonSize.child,
              expand: true,
              onPressed: widget.onHome,
            ),
            const SizedBox(height: NovaSpace.lg),
            Center(
              child: NovaButton(
                label: widget.grownUpsLabel,
                icon: Icons.family_restroom_rounded,
                variant: NovaButtonVariant.quiet,
                onPressed: widget.onGrownUps,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

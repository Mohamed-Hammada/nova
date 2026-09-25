import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';
import 'package:nova_app/ui/game/art/game_art.dart';

import 'game_animation.dart';

/// An expressive illustrated game character with ambient breathing,
/// state-based reactions, and optional attached request/speech bubble.
class GameCharacter extends StatefulWidget {
  const GameCharacter({
    super.key,
    required this.characterId,
    required this.state,
    required this.semanticLabel,
    this.size = 120,
    this.requestWidget,
  });

  final String characterId;
  final CharacterVisualState state;
  final String semanticLabel;
  final double size;
  final Widget? requestWidget;

  @override
  State<GameCharacter> createState() => _GameCharacterState();
}

class _GameCharacterState extends State<GameCharacter> with SingleTickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _breathingAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: GameAnimation.breatheCurve),
    );

    _cycleBreathing();
  }

  void _cycleBreathing() {
    if (!mounted) return;
    _breathingController.forward().then((_) {
      if (mounted) {
        _breathingController.reverse();
      }
    });
  }

  @override
  void didUpdateWidget(covariant GameCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _cycleBreathing();
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = NovaMotion.reduced(context);
    final isIdle = widget.state == CharacterVisualState.idle;

    Widget characterArt = GameArt.character(
      characterId: widget.characterId,
      state: widget.state,
      size: widget.size,
      animate: true,
    );

    if (isIdle && !reduced) {
      characterArt = AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (context, child) => Transform.scale(
          scaleY: _breathingAnimation.value,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
        child: characterArt,
      );
    }

    final content = widget.requestWidget == null
        ? characterArt
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              characterArt,
              const SizedBox(width: NovaSpace.sm),
              widget.requestWidget!,
            ],
          );

    return Semantics(
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: content,
    );
  }
}

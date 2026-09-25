import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';

import 'art/game_art.dart';

export 'art/game_art.dart';

/// Illustrations for game.math.bear-apples, backed by the extensible GameArt system:
/// local illustrated assets with procedural vector fallbacks.
enum Fruit { apple, pear }

class FruitArt extends StatelessWidget {
  const FruitArt({super.key, required this.fruit, this.size = NovaSize.gameItem});
  final Fruit fruit;
  final double size;

  @override
  Widget build(BuildContext context) => GameArt.object(
        objectId: fruit == Fruit.apple ? 'apple' : 'pear',
        size: size,
      );
}

/// The plate or basket target area, backed by GameArt.
class PlateArt extends StatelessWidget {
  const PlateArt({super.key, required this.highlighted, required this.child, this.containerId = 'basket'});
  final bool highlighted;
  final Widget child;
  final String containerId;

  @override
  Widget build(BuildContext context) => GameArt.container(
        containerId: containerId,
        highlighted: highlighted,
        child: child,
      );
}

enum BearMood { waiting, happy, thinking }

class BearArt extends StatelessWidget {
  const BearArt({super.key, required this.mood, this.size = 120});
  final BearMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final state = switch (mood) {
      BearMood.happy => CharacterVisualState.happy,
      BearMood.thinking => CharacterVisualState.thinking,
      BearMood.waiting => CharacterVisualState.idle,
    };
    return GameArt.character(characterId: 'bear', state: state, size: size);
  }
}


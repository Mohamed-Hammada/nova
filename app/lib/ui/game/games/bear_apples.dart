import 'package:flutter/material.dart';
import 'package:nova_app/core/game/bear_apples_trials.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/mechanics_flutter/drag_to_count_mechanic.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/l10n.dart';

import '../bear_apples_art.dart';
import '../game_catalog.dart';

/// game.math.bear-apples: the bear asks for a number of apples; the child
/// gives exactly that many from a larger pile (with pears as distractors on
/// higher rungs).
final bearApplesGame = PlayableGame(
  gameId: 'game.math.bear-apples',
  trialGenerator: bearApplesTrials,
  signalMapper: bearApplesSignalMapper,
  skin: _skin,
  receiver: (context, mood, requested) => _BearWithRequest(mood: mood, requested: requested),
  prompt: (context, requested) => context.l10n.gamePrompt(requested, NovaNumbers.format(context, requested)),
  howTo: (context) => context.l10n.gameHowTo,
  cardArt: (context) => const _CardArt(),
);

DragToCountSkin _skin(BuildContext context) {
  final l10n = context.l10n;
  return DragToCountSkin(
    itemBuilder: (context, item, size) => FruitArt(fruit: item.isDistractor ? Fruit.pear : Fruit.apple, size: size),
    plateBuilder: (context, highlighted, contents) => PlateArt(highlighted: highlighted, child: contents),
    itemLabel: (item) => item.isDistractor ? l10n.itemPear : l10n.itemApple,
    itemOnPlateLabel: (item) => item.isDistractor ? l10n.itemOnPlatePear : l10n.itemOnPlateApple,
    giveHint: l10n.itemGiveHint,
    takeBackHint: l10n.itemTakeBackHint,
    plateLabel: l10n.plateLabel,
    plateEmptyLabel: l10n.plateEmpty,
    pileLabel: l10n.pileLabel,
    formatNumber: (n) => NovaNumbers.format(context, n),
  );
}

/// The bear with a speech bubble holding the requested number: large enough
/// for a pre-reader to recognise the numeral, and paired with the written
/// prompt (and narration, when its audio asset exists).
class _BearWithRequest extends StatelessWidget {
  const _BearWithRequest({required this.mood, required this.requested});
  final BearMood mood;
  final int requested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = NovaWidthClass.of(context) == NovaWidthClass.compact;
    return Semantics(
      label: context.l10n.bearLabel,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: NovaSpace.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BearArt(mood: mood, size: compact ? 88 : 116),
            const SizedBox(width: NovaSpace.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: NovaSpace.lg, vertical: NovaSpace.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(NovaRadius.md),
                border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  NovaNumbers.format(context, requested),
                  style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(width: NovaSpace.xs),
                const FruitArt(fruit: Fruit.apple, size: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardArt extends StatelessWidget {
  const _CardArt();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BearArt(mood: BearMood.happy, size: 96),
        SizedBox(width: NovaSpace.xs),
        FruitArt(fruit: Fruit.apple, size: 48),
        FruitArt(fruit: Fruit.apple, size: 48),
      ],
    );
  }
}

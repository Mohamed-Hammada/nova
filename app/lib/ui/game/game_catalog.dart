import 'package:flutter/widgets.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/mechanics_flutter/drag_to_count_mechanic.dart';

import 'bear_apples_art.dart';
import 'games/bear_apples.dart';

/// A game the app can actually run: its content id (the game's definition,
/// rungs, skills and names come from the compiled bundle), plus the few
/// per-game pieces that are code -- how its rungs become trials, how its raw
/// events map to curriculum signals, and how it looks.
class PlayableGame {
  const PlayableGame({
    required this.gameId,
    required this.trialGenerator,
    required this.signalMapper,
    required this.skin,
    required this.receiver,
    this.companionReceiver,
    required this.prompt,
    required this.howTo,
    required this.cardArt,
    this.characterId = 'bear',
    this.backgroundId = 'forest_clearing',
    this.containerId = 'basket',
    this.environmentElements = const ['sun', 'cloud', 'tree_branch'],
  });

  final String gameId;
  final TrialGenerator trialGenerator;
  final SignalMapper signalMapper;
  final DragToCountSkin Function(BuildContext context) skin;

  /// The character the child is helping, shown above the plate (legacy signature).
  final Widget Function(BuildContext context, BearMood mood, int requested) receiver;

  /// Rich character companion receiver supporting full [CharacterVisualState] and active gestures.
  final Widget Function(BuildContext context, CharacterVisualState state, int requested, {bool pointing})? companionReceiver;

  /// The request, written out (e.g. "Give the bear 3 apples").
  final String Function(BuildContext context, int requested) prompt;
  final String Function(BuildContext context) howTo;
  final WidgetBuilder cardArt;

  /// Visual theme identifiers declared in content or defaulted.
  final String characterId;
  final String backgroundId;
  final String containerId;
  final List<String> environmentElements;
}

/// Games in the bundle without an entry here are not shown: their mechanic
/// has no implementation in this app yet.
final Map<String, PlayableGame> playableGames = {
  bearApplesGame.gameId: bearApplesGame,
};

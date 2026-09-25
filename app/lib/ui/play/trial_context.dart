import 'package:flutter/material.dart';

import '../l10n.dart';
import 'stage/choice_look.dart';

/// Help given at the start of a round, from the scaffold the Adaptive
/// Engine chose: none (independent or hint on request), a first step
/// (guided: one wrong answer leaves) or a demonstration (modelled: the
/// companion's hand shows the answer).
enum RoundHelp { none, firstStep, show }

/// Moments in a round the companion takes part in.
enum PlayMoment {
  /// One answer that is not it floated away (a first-step hint).
  firstStep,

  /// The companion's hand shows the answer (a demonstration or a hint).
  show,

  /// After two tries the hand shows where the answer is; the child taps it.
  reveal,
}

/// What every round view gets from the level screen.
class TrialContext {
  const TrialContext({
    required this.language,
    required this.onResponse,
    required this.onDone,
    required this.hint,
    required this.speak,
    required this.accent,
    required this.l10n,
    this.voicePick,
    this.look = ChoiceLook.plain,
    this.startHelp = RoundHelp.none,
    this.onMoment,
  });
  final String language;
  final AppLocalizations l10n;

  /// Log one response (correct or not). Some rounds log several. [attempt]
  /// is 2 or more for a second try in the same round.
  final void Function(bool correct, {int attempt}) onResponse;

  /// The round is over; move to the next.
  final VoidCallback onDone;

  /// Ticks each time the child asks for a hint.
  final ValueNotifier<int> hint;
  final void Function(String text) speak;
  final Color accent;

  /// A spoken answer, already matched: an option index for choice rounds,
  /// the number said for counting rounds.
  final ValueNotifier<int?>? voicePick;

  /// How choice answers look in this game and place.
  final ChoiceLook look;

  /// Help to give as the round begins.
  final RoundHelp startHelp;

  /// A moment the companion should take part in, with where it happens on
  /// screen (global coordinates) so the companion can look there.
  final void Function(PlayMoment moment, Offset? at)? onMoment;
}

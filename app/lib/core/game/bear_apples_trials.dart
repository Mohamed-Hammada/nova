import 'dart:math';

import 'package:nova_app/core/content/models.dart';

import 'session_plan.dart';

/// How game.math.bear-apples reads its own rung values. The anchors in the
/// game's data are prose ("requests of 1 to 3", "requests of 1 to 5"; "only
/// apples in the pile", "apples mixed with pears"); this is their one
/// executable interpretation, kept beside the game's signal mapping rather
/// than in a widget. A rung value with no entry here fails loudly -- the
/// real-bundle test walks every declared rung, so new content cannot drift
/// silently past it.
const _maxRequestByItemComplexity = {0: 3, 1: 5};
const _pearsByDistractors = {0: 0, 1: 2};

/// The pile always holds 1 to this many more apples than requested: the
/// mechanic's point is stopping at the requested number, and a varying
/// surplus keeps "take all but two" from ever being a shortcut.
const _maxExtraApples = 3;

List<TrialSpec> bearApplesTrials({required Rung rung, required int count, required int seed}) {
  final itemComplexity = rung.values['item_complexity'] ?? 0;
  final distractors = rung.values['distractors'] ?? 0;
  final maxRequest = _maxRequestByItemComplexity[itemComplexity] ??
      (throw StateError('bear-apples has no request range for item_complexity=$itemComplexity (rung ${rung.id})'));
  final pears = _pearsByDistractors[distractors] ??
      (throw StateError('bear-apples has no pear count for distractors=$distractors (rung ${rung.id})'));

  final random = Random(seed);
  final trials = <TrialSpec>[];
  int? previous;
  for (var i = 0; i < count; i++) {
    var requested = 1 + random.nextInt(maxRequest);
    // Never the same request twice in a row, so each trial asks for a fresh count.
    if (requested == previous && maxRequest > 1) requested = requested % maxRequest + 1;
    previous = requested;
    trials.add(TrialSpec(requested: requested, targetsInPile: requested + 1 + random.nextInt(_maxExtraApples), distractorsInPile: pears));
  }
  return trials;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/game/bear_apples_trials.dart';

import '../../support/fixture_content.dart';

Rung _rung(int itemComplexity, int distractors) =>
    Rung(id: 'r', values: {'item_complexity': itemComplexity, 'distractors': distractors});

void main() {
  test('the same seed always produces the same trials (deterministic gameplay)', () {
    expect(bearApplesTrials(rung: _rung(1, 1), count: 20, seed: 42), bearApplesTrials(rung: _rung(1, 1), count: 20, seed: 42));
  });

  test('item_complexity 0 asks for 1 to 3; item_complexity 1 asks for 1 to 5', () {
    final low = bearApplesTrials(rung: _rung(0, 0), count: 300, seed: 1).map((t) => t.requested).toSet();
    final high = bearApplesTrials(rung: _rung(1, 0), count: 300, seed: 1).map((t) => t.requested).toSet();
    expect(low, {1, 2, 3});
    expect(high, {1, 2, 3, 4, 5});
  });

  test('the pile always holds more apples than requested, so stopping is part of the task', () {
    for (final trial in bearApplesTrials(rung: _rung(1, 0), count: 300, seed: 7)) {
      expect(trial.targetsInPile, greaterThan(trial.requested));
      expect(trial.targetsInPile, lessThanOrEqualTo(trial.requested + 3));
    }
  });

  test('the surplus varies, so "take all but N" is never a shortcut', () {
    final surpluses = bearApplesTrials(rung: _rung(1, 0), count: 100, seed: 3).map((t) => t.targetsInPile - t.requested).toSet();
    expect(surpluses.length, greaterThan(1));
  });

  test('pears appear only on a distractor rung', () {
    expect(bearApplesTrials(rung: _rung(1, 0), count: 10, seed: 1).every((t) => t.distractorsInPile == 0), isTrue);
    expect(bearApplesTrials(rung: _rung(1, 1), count: 10, seed: 1).every((t) => t.distractorsInPile == 2), isTrue);
  });

  test('the same request never repeats back to back', () {
    final trials = bearApplesTrials(rung: _rung(0, 0), count: 200, seed: 9);
    for (var i = 1; i < trials.length; i++) {
      expect(trials[i].requested, isNot(trials[i - 1].requested));
    }
  });

  test('a rung value the game has no interpretation for fails loudly instead of guessing', () {
    expect(() => bearApplesTrials(rung: _rung(2, 0), count: 1, seed: 1), throwsStateError);
    expect(() => bearApplesTrials(rung: _rung(0, 5), count: 1, seed: 1), throwsStateError);
  });

  test('every rung of the REAL compiled bear-apples game produces valid trials', () {
    final game = loadRealBundle().game('game.math.bear-apples');
    expect(game.rungIds, isNotEmpty);
    for (final rungId in game.rungIds) {
      final trials = bearApplesTrials(rung: game.rungsById[rungId]!, count: 6, seed: 1);
      expect(trials, hasLength(6), reason: rungId);
    }
  });
}

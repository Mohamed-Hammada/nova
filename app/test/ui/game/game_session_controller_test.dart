import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/game/bear_apples_trials.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/ui/game/game_session_controller.dart';

import '../../support/fake_clock.dart';
import '../../support/fixture_content.dart';
import '../../support/in_memory_persistence_port.dart';
import '../../support/runtime.dart';

const _game = 'game.math.bear-apples';
const _skill = 'math.count.one-to-one-5';

/// Every trial asks for 2 out of a pile of 3 apples and [pears] pears, so
/// tests can place exact counts without reading the random trial list.
TrialGenerator _fixed({int pears = 0}) =>
    ({required rung, required count, required seed}) => List.filled(count, TrialSpec(requested: 2, targetsInPile: 3, distractorsInPile: pears));

class _FailingSavePersistence extends InMemoryPersistencePort {
  int failuresLeft = 1;
  @override
  Future<void> saveSession({
    required String childId,
    required String skillId,
    required MasteryRecord mastery,
    required DimensionEstimate? performance,
    required DimensionEstimate? independence,
    required DimensionEstimate? transfer,
    required AdaptiveDecision decision,
  }) async {
    if (failuresLeft-- > 0) throw StateError('disk full');
    return super.saveSession(
      childId: childId, skillId: skillId, mastery: mastery,
      performance: performance, independence: independence, transfer: transfer, decision: decision,
    );
  }
}

void main() {
  final clock = FakeClock(DateTime(2026, 1, 1));
  late List<GameCue> cues;

  GameSessionController session({PersistencePort? persistence, int minTrials = 2, int pears = 0, TrialGenerator? trials}) {
    cues = [];
    final controller = GameSessionController(
      runtime: buildRuntime(fixtureContent(minTrials: minTrials), persistence ?? InMemoryPersistencePort(), clock),
      childId: 'c1', gameId: _game, skillId: _skill,
      trialGenerator: trials ?? _fixed(pears: pears),
      signalMapper: bearApplesSignalMapper,
      seed: 1,
      onCue: cues.add,
      now: clock.now,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  void give(GameSessionController s, int apples, {int pears = 0}) {
    final targets = s.items.where((i) => !i.isDistractor && !i.onPlate).take(apples).toList();
    final distractors = s.items.where((i) => i.isDistractor && !i.onPlate).take(pears).toList();
    for (final item in [...targets, ...distractors]) {
      s.place(item.id);
    }
  }

  test('start plans the session through GameRuntime: trial count from min-trials, first rung', () async {
    final s = session(minTrials: 3, trials: bearApplesTrials);
    expect(s.phase, GamePhase.loading);
    await s.start();
    expect(s.phase, GamePhase.playing);
    expect(s.trialCount, 3);
    expect(s.plan!.rung.id, 'r1');
    expect(s.items.where((i) => !i.isDistractor).length, s.currentTrial!.targetsInPile);
    expect(cues, [GameCue.sessionStart, GameCue.trialStart]);
  });

  test('Done is unavailable until something is on the plate', () async {
    final s = session();
    await s.start();
    expect(s.canSubmit, isFalse);
    s.submit();
    expect(s.phase, GamePhase.playing);
    give(s, 1);
    expect(s.canSubmit, isTrue);
  });

  test('a full correct session completes and commits Secure through the real engines', () async {
    final persistence = InMemoryPersistencePort();
    final s = session(persistence: persistence);
    await s.start();
    for (var t = 0; t < 2; t++) {
      give(s, 2);
      s.submit();
      expect(s.feedback, TrialFeedback.correct);
      await s.next();
    }
    expect(s.phase, GamePhase.complete);
    expect(s.completedTrials, 2);
    expect((await persistence.currentMastery(childId: 'c1', skillId: _skill))!.state, 'secure');
    expect(cues.last, GameCue.sessionComplete);
  });

  test('wrong then fixed: retry keeps the plate, and the first attempt is what gets assessed', () async {
    final persistence = InMemoryPersistencePort();
    final s = session(persistence: persistence);
    await s.start();

    give(s, 3); // one too many
    s.submit();
    expect(s.feedback, TrialFeedback.tryAgain);
    expect(s.phase, GamePhase.feedback);
    s.remove(s.items.firstWhere((i) => i.onPlate).id);
    expect(s.targetsOnPlate, 3, reason: 'the board is frozen while feedback shows');

    s.retry();
    expect(s.phase, GamePhase.playing);
    expect(s.targetsOnPlate, 3, reason: 'the child fixes the plate rather than starting over');
    s.remove(s.items.firstWhere((i) => i.onPlate).id);
    s.submit();
    expect(s.feedback, TrialFeedback.correct);
    await s.next();

    give(s, 2);
    s.submit();
    await s.next();
    expect(s.phase, GamePhase.complete);
    // First attempts: 1 miss + 1 hit = 0.5 accuracy over 2 trials -> no
    // better than Emerging; the corrected retry did not count as a hit.
    final mastery = await persistence.currentMastery(childId: 'c1', skillId: _skill);
    expect(mastery!.state, 'emerging');
    final performance = await persistence.currentDimension(childId: 'c1', skillId: _skill, dimension: 'performance');
    expect(performance!.metrics['trials'], 2);
  });

  test('a pear on the plate gets its own feedback', () async {
    final s = session(pears: 2);
    await s.start();
    give(s, 2, pears: 1);
    s.submit();
    expect(s.feedback, TrialFeedback.onlyTargets);
  });

  test('after the last allowed attempt the session moves on kindly instead of retrying forever', () async {
    final s = session();
    await s.start();
    give(s, 1);
    s.submit();
    s.retry();
    s.submit(); // still wrong, second attempt
    expect(s.feedback, TrialFeedback.moveOn);
    s.retry(); // not allowed now
    expect(s.phase, GamePhase.feedback);
    await s.next();
    expect(s.trialIndex, 1);
    expect(s.targetsOnPlate, 0);
  });

  test('a hint shows the count until the plate changes, and is recorded as support', () async {
    final persistence = InMemoryPersistencePort();
    final s = session(persistence: persistence);
    await s.start();
    give(s, 1);
    s.useHint();
    expect(s.hintVisible, isTrue);
    expect(cues, contains(GameCue.hint));
    give(s, 1);
    expect(s.hintVisible, isFalse);
    s.submit();
    await s.next();
    give(s, 2);
    s.submit();
    await s.next();
    final independence = await persistence.currentDimension(childId: 'c1', skillId: _skill, dimension: 'independence');
    expect(independence!.metrics['hintsPerTrial'], 0.5);
    expect((await persistence.currentMastery(childId: 'c1', skillId: _skill))!.state, 'developing',
        reason: 'perfect accuracy with hints is not Secure');
  });

  test('a failed save shows a recoverable state; retrying saves the same session', () async {
    final persistence = _FailingSavePersistence();
    final s = session(persistence: persistence, minTrials: 1);
    await s.start();
    give(s, 2);
    s.submit();
    await s.next();
    expect(s.phase, GamePhase.failed);
    expect(s.failure, GameFailure.couldNotSave);
    await s.retrySave();
    expect(s.phase, GamePhase.complete);
    expect((await persistence.currentMastery(childId: 'c1', skillId: _skill))!.state, 'secure');
  });

  test('a game that cannot be planned fails with couldNotStart rather than crashing', () async {
    final s = session(trials: ({required rung, required count, required seed}) => throw StateError('bad rung'));
    await s.start();
    expect(s.phase, GamePhase.failed);
    expect(s.failure, GameFailure.couldNotStart);
  });

  test('intents outside the playing phase are ignored', () async {
    final s = session();
    s.place(0);
    s.useHint();
    s.submit();
    await s.next();
    expect(s.phase, GamePhase.loading);
    expect(cues, isEmpty);
  });
}

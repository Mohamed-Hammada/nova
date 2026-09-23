import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/content/criterion_parameters.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';

import '../../support/fake_clock.dart';
import '../../support/fixture_content.dart';
import '../../support/in_memory_persistence_port.dart';
import '../../support/runtime.dart';

const _game = 'game.math.bear-apples';
const _skill = 'math.count.one-to-one-5';

void main() {
  final clock = FakeClock(DateTime(2026, 1, 1));

  group('planSession', () {
    test('before any session: the first rung, and as many trials as the rule\'s min-trials', () async {
      final runtime = buildRuntime(fixtureContent(minTrials: 4), InMemoryPersistencePort(), clock);
      final plan = await runtime.planSession(childId: 'c1', gameId: _game, skillId: _skill);
      expect(plan.rung.id, 'r1');
      expect(plan.trialCount, 4);
      expect(plan.game.id, _game);
    });

    test('uses the rung the adaptive engine last committed (it is handed a rung, it does not pick one)', () async {
      final persistence = InMemoryPersistencePort();
      await persistence.saveSession(
        childId: 'c1', skillId: _skill,
        mastery: MasteryRecord(childId: 'c1', skillId: _skill, state: null, confidence: 0, updatedAt: clock.now()),
        performance: null, independence: null, transfer: null,
        decision: const AdaptiveDecision(childId: 'c1', gameId: _game, nextRungId: 'r2', scaffold: 'guided', reason: 'x'),
      );
      final plan = await buildRuntime(fixtureContent(), persistence, clock).planSession(childId: 'c1', gameId: _game, skillId: _skill);
      expect(plan.rung.id, 'r2');
    });

    test('a persisted rung that no longer exists in the content falls back to the first rung', () async {
      final persistence = InMemoryPersistencePort();
      await persistence.saveSession(
        childId: 'c1', skillId: _skill,
        mastery: MasteryRecord(childId: 'c1', skillId: _skill, state: null, confidence: 0, updatedAt: clock.now()),
        performance: null, independence: null, transfer: null,
        decision: const AdaptiveDecision(childId: 'c1', gameId: _game, nextRungId: 'r-removed', scaffold: 'guided', reason: 'x'),
      );
      final runtime = buildRuntime(fixtureContent(), persistence, clock);
      expect((await runtime.planSession(childId: 'c1', gameId: _game, skillId: _skill)).rung.id, 'r1');

      // And completing a session from there makes a decision from r1, not
      // from an index of -1.
      final decision = await runtime.completeSession(
        childId: 'c1', gameId: _game, skillId: _skill,
        rawEvents: [TrialSubmitted(correct: true, hintsUsedThisTrial: 0, at: clock.now())],
        mapper: bearApplesSignalMapper,
      );
      expect(decision.nextRungId, 'r2');
    });

    test('with the REAL bundle, a session is long enough for the rule to evaluate Secure', () async {
      final content = loadRealBundle();
      final plan = await buildRuntime(content, InMemoryPersistencePort(), clock).planSession(childId: 'c1', gameId: _game, skillId: _skill);
      expect(plan.trialCount, minTrialsFor(content.assessmentRuleFor(_skill), content.allParameters()));
      expect(plan.trialCount, greaterThanOrEqualTo(1));
    });
  });

  test('currentMastery reads through the runtime (widgets never touch PersistencePort)', () async {
    final persistence = InMemoryPersistencePort();
    final runtime = buildRuntime(fixtureContent(), persistence, clock);
    expect(await runtime.currentMastery(childId: 'c1', skillId: _skill), isNull);
    await runtime.completeSession(
      childId: 'c1', gameId: _game, skillId: _skill,
      rawEvents: [TrialSubmitted(correct: true, hintsUsedThisTrial: 0, at: clock.now())],
      mapper: bearApplesSignalMapper,
    );
    expect((await runtime.currentMastery(childId: 'c1', skillId: _skill))!.state, 'secure');
  });

  group('educational invariants through the full pipeline', () {
    Future<String?> stateAfter(List<RawMechanicEvent> events, {SignalMapper mapper = bearApplesSignalMapper, int minTrials = 6}) async {
      final persistence = InMemoryPersistencePort();
      await buildRuntime(fixtureContent(minTrials: minTrials), persistence, clock).completeSession(
        childId: 'c1', gameId: _game, skillId: _skill, rawEvents: events, mapper: mapper,
      );
      return (await persistence.currentMastery(childId: 'c1', skillId: _skill))!.state;
    }

    TrialSubmitted trial({required bool correct, int hints = 0, int attempt = 1}) =>
        TrialSubmitted(correct: correct, hintsUsedThisTrial: hints, attempt: attempt, at: clock.now());

    test('engagement signals cannot change mastery, however many or large', () async {
      final events = [for (var i = 0; i < 6; i++) trial(correct: i.isEven)];
      // The same trials, through a mapper that ALSO emits engagement signals
      // (completion, stars, streak) with extreme values on every event.
      List<SignalDraft> noisy(RawMechanicEvent e) => [
            ...bearApplesSignalMapper(e),
            const SignalDraft('completion', 1000),
          ];
      expect(await stateAfter(events, mapper: noisy), await stateAfter(events));
    });

    test('a failed trial rescued by a correct retry is still a miss: retries cannot manufacture Secure', () async {
      final events = [
        for (var i = 0; i < 5; i++) trial(correct: true),
        trial(correct: false),
        trial(correct: true, attempt: 2),
      ];
      // 5/6 first-attempt accuracy (0.83) is below secure-accuracy (0.85).
      expect(await stateAfter(events), 'developing');
    });

    test('retries do not add trials toward min-trials', () async {
      final events = [
        for (var i = 0; i < 3; i++) ...[trial(correct: false), trial(correct: true, attempt: 2)],
      ];
      // 3 real trials < min-trials 6: not even Emerging.
      expect(await stateAfter(events), isNull);
    });

    test('heavy hint use keeps a perfect performer below Secure (performance alone is not enough)', () async {
      final events = [for (var i = 0; i < 6; i++) trial(correct: true, hints: 1)];
      expect(await stateAfter(events), 'developing');
    });
  });
}

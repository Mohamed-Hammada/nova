import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/core/play/session.dart';
import 'package:nova_app/core/skills/error_types.dart';
import 'package:nova_app/core/skills/skill_profile.dart';

import '../../support/fake_clock.dart';
import '../../support/fixture_content.dart';
import '../../support/in_memory_persistence_port.dart';
import '../../support/runtime.dart';

/// GameRuntime turns every session into Skill Evidence and judges mastery
/// on the accumulated profile, on the real content (min-trials 6).
void main() {
  final content = loadRealBundle();
  const game = 'game.math.bear-apples';
  const skill = 'math.count.one-to-one-5';

  List<RawMechanicEvent> session(DateTime at, {required int correct, int trials = 6, List<String> missErrors = const [ErrorType.overCount], int hints = 0}) => [
        for (var i = 0; i < trials; i++)
          TrialSubmitted(correct: i < correct, hintsUsedThisTrial: i < hints ? 1 : 0, hintRequestsThisTrial: i < hints ? 1 : 0, errors: i < correct ? const [] : missErrors, at: at),
      ];

  late InMemoryPersistencePort persistence;
  late FakeClock clock;
  setUp(() {
    persistence = InMemoryPersistencePort();
    clock = FakeClock(DateTime(2026, 7, 1, 9));
  });

  Future<void> play(int correct, {List<String> missErrors = const [ErrorType.overCount], int hints = 0, String? context}) async {
    final runtime = buildRuntime(content, persistence, clock);
    clock.advance(const Duration(hours: 1));
    await runtime.completeSession(childId: 'c', gameId: game, skillId: skill, rawEvents: session(clock.now(), correct: correct, missErrors: missErrors, hints: hints), mapper: trialSignalMapper, activityId: 'explorer-001', context: context);
  }

  Future<SkillProfile> profile() => buildRuntime(content, persistence, clock).skillProfile(childId: 'c', skillId: skill);

  test('each session is appended as evidence, with what the game reported', () async {
    await play(4, context: 'carrots');
    await play(5, context: 'fish');
    final evidence = await persistence.skillEvidence(childId: 'c', skillId: skill);
    expect(evidence, hasLength(2));
    expect(evidence.first.trials, 6);
    expect(evidence.first.correct, 4);
    expect(evidence.first.errors[ErrorType.overCount], 2);
    expect(evidence.first.mechanicId, 'drag-to-count');
    expect(evidence.first.activityId, 'explorer-001');
    expect(evidence.map((e) => e.contextKey), ['$game#carrots', '$game#fish']);
    final p = await profile();
    expect(p.sessions, 2);
    expect(p.attempts, 12);
    expect(p.contexts, hasLength(2));
  });

  test('mastery comes from the accumulated profile: one bad session does not erase Secure', () async {
    await play(6);
    await play(6);
    await play(6);
    expect((await persistence.currentMastery(childId: 'c', skillId: skill))!.state, 'secure');
    await play(1);
    expect((await persistence.currentMastery(childId: 'c', skillId: skill))!.state, 'secure', reason: 'one bad day');
    await play(1);
    expect((await persistence.currentMastery(childId: 'c', skillId: skill))!.state, 'developing', reason: 'a real change, one step');
    expect((await profile()).trend, Trend.declining);
  });

  test('repeated errors become part of the profile and bring back guidance on the first round', () async {
    await play(3);
    await play(4);
    final p = await profile();
    expect(p.repeatedErrors, [ErrorType.overCount]);
    final plan = await buildRuntime(content, persistence, clock).planSession(childId: 'c', gameId: game, skillId: skill);
    expect(plan.scaffold, ScaffoldLevel.guided);
  });

  test('a grown-up\'s passed probe task lifts a Secure skill to Transfer', () async {
    await play(6);
    await play(6);
    final runtime = buildRuntime(content, persistence, clock);
    expect((await runtime.skillProfile(childId: 'c', skillId: skill)).state, SkillState.secure);
    final after = await runtime.recordTransferProbe(childId: 'c', skillId: skill, passed: true);
    expect(after.state, SkillState.transfer);
    // A later "not yet" never takes a pass away.
    final again = await runtime.recordTransferProbe(childId: 'c', skillId: skill, passed: false);
    expect(again.state, SkillState.transfer);
  });

  test('the child\'s skills and recent sessions come back together, newest first', () async {
    await play(4);
    await play(5);
    final result = await buildRuntime(content, persistence, clock).childSkills(childId: 'c', skillIds: [skill, 'math.compare.more-fewer']);
    expect(result.profiles.keys, [skill], reason: 'no evidence, no profile');
    expect(result.history, hasLength(2));
    expect(result.history.first.at.isAfter(result.history.last.at), isTrue);
    expect(result.profiles[skill]!.recentRun, 2);
  });

  group('a play session reports what it saw', () {
    test('errors from the round, a hint the child asked for, and a quick wrong answer', () {
      var now = DateTime(2026, 1, 1, 10);
      final s = PlaySession(mechanicId: 'm', trials: const [], now: () => now)..start(rngSeed: 1);
      final events = <RawMechanicEvent>[];
      s.rawEvents.listen(events.add);
      // A fast miss: impulsive.
      now = now.add(const Duration(milliseconds: 300));
      s.record(false, errors: [ErrorType.distractorSelected]);
      // The same mistake again on the retry.
      now = now.add(const Duration(seconds: 3));
      s.record(false, attempt: 2, errors: [ErrorType.distractorSelected]);
      // A requested hint, then a thought-through right answer.
      s.useHint();
      s.useHint(requested: false);
      now = now.add(const Duration(seconds: 4));
      s.record(true);
      return Future<void>.delayed(Duration.zero, () {
        final submissions = events.cast<TrialSubmitted>();
        expect(submissions.first.errors, containsAll([ErrorType.distractorSelected, ErrorType.impulsiveResponse]));
        expect(submissions.elementAt(1).errors, contains(ErrorType.repeatedError));
        expect(submissions.last.errors, isEmpty);
        expect(submissions.last.hintsUsedThisTrial, 2);
        expect(submissions.last.hintRequestsThisTrial, 1);
      });
    });
  });
}

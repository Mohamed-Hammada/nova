import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/core/skills/skill_evidence.dart';

/// A live adapter under test, plus how to release it.
class PersistenceHarness {
  PersistenceHarness(this.port, {Future<void> Function()? close}) : close = close ?? (() async {});
  final PersistencePort port;
  final Future<void> Function() close;
}

/// The behavioural contract every PersistencePort adapter must satisfy.
///
/// Run against the in-memory fake, native drift/SQLite, and (in a browser)
/// drift on WebAssembly, so "the web build persists progress the same way the
/// native build does" is a checked claim rather than an assumption: the
/// same expectations, byte for byte, pass against every adapter.
void persistencePortContract(String adapterName, Future<PersistenceHarness> Function() open) {
  group('PersistencePort contract: $adapterName', () {
    late PersistenceHarness harness;
    setUp(() async => harness = await open());
    tearDown(() async => harness.close());

    final now = DateTime.utc(2026, 1, 1, 9, 30);
    const skill = 'math.count.one-to-one-5';
    const game = 'game.math.bear-apples';

    AdaptiveDecision decision(String rung, {String childId = 'c1'}) =>
        AdaptiveDecision(childId: childId, gameId: game, nextRungId: rung, scaffold: 'guided', reason: 'x');

    DimensionEstimate estimate(String dimension, Map<String, num> metrics, {int evidence = 6}) =>
        DimensionEstimate(skillId: skill, dimension: dimension, metrics: metrics, evidenceCount: evidence, lastUpdated: now);

    test('reads return null before anything is saved', () async {
      final port = harness.port;
      expect(await port.currentMastery(childId: 'c1', skillId: skill), isNull);
      expect(await port.currentDimension(childId: 'c1', skillId: skill, dimension: 'performance'), isNull);
      expect(await port.currentRung(childId: 'c1', gameId: game), isNull);
      expect(await port.currentScaffold(childId: 'c1', gameId: game), isNull);
    });

    test('round-trips mastery, every dimension, and the rung exactly', () async {
      final port = harness.port;
      await port.saveSession(
        childId: 'c1', skillId: skill,
        mastery: MasteryRecord(childId: 'c1', skillId: skill, state: 'developing', confidence: 0.6, updatedAt: now),
        performance: estimate('performance', const {'accuracy': 0.75, 'trials': 8}, evidence: 8),
        independence: estimate('independence', const {'hintsPerTrial': 0.125, 'adultAssistPerTrial': 0}),
        transfer: estimate('transfer', const {'passed': 1}, evidence: 1),
        decision: decision('r2'),
      );

      final mastery = (await port.currentMastery(childId: 'c1', skillId: skill))!;
      expect(mastery.childId, 'c1');
      expect(mastery.skillId, skill);
      expect(mastery.state, 'developing');
      expect(mastery.confidence, 0.6);
      expect(mastery.updatedAt.isAtSameMomentAs(now), isTrue);

      final performance = (await port.currentDimension(childId: 'c1', skillId: skill, dimension: 'performance'))!;
      expect(performance.metrics, {'accuracy': 0.75, 'trials': 8});
      expect(performance.evidenceCount, 8);
      expect(performance.lastUpdated.isAtSameMomentAs(now), isTrue);

      final independence = (await port.currentDimension(childId: 'c1', skillId: skill, dimension: 'independence'))!;
      expect(independence.metrics, {'hintsPerTrial': 0.125, 'adultAssistPerTrial': 0});

      final transfer = (await port.currentDimension(childId: 'c1', skillId: skill, dimension: 'transfer'))!;
      expect(transfer.metrics['passed'], 1);
      expect(transfer.evidenceCount, 1);

      expect(await port.currentRung(childId: 'c1', gameId: game), 'r2');
      // The scaffold travels with the rung, so the next session applies it.
      expect(await port.currentScaffold(childId: 'c1', gameId: game), decision('r2').scaffold);
    });

    test('"Not yet" (a null state) survives a round trip as null, not a string', () async {
      final port = harness.port;
      await port.saveSession(
        childId: 'c1', skillId: skill,
        mastery: MasteryRecord(childId: 'c1', skillId: skill, state: null, confidence: 0, updatedAt: now),
        performance: null, independence: null, transfer: null,
        decision: decision('r1'),
      );
      final mastery = await port.currentMastery(childId: 'c1', skillId: skill);
      expect(mastery, isNotNull);
      expect(mastery!.state, isNull);
    });

    test('a later session overwrites the earlier one instead of duplicating it', () async {
      final port = harness.port;
      Future<void> save(String? state, String rung, num accuracy) => port.saveSession(
            childId: 'c1', skillId: skill,
            mastery: MasteryRecord(childId: 'c1', skillId: skill, state: state, confidence: 0.1, updatedAt: now),
            performance: estimate('performance', {'accuracy': accuracy, 'trials': 6}),
            independence: null, transfer: null,
            decision: decision(rung),
          );
      await save('emerging', 'r1', 0.5);
      await save('secure', 'r3', 1);
      expect((await port.currentMastery(childId: 'c1', skillId: skill))!.state, 'secure');
      expect((await port.currentDimension(childId: 'c1', skillId: skill, dimension: 'performance'))!.metrics['accuracy'], 1);
      expect(await port.currentRung(childId: 'c1', gameId: game), 'r3');
    });

    test('a session that omits a dimension leaves the previously saved one intact', () async {
      final port = harness.port;
      await port.saveSession(
        childId: 'c1', skillId: skill,
        mastery: MasteryRecord(childId: 'c1', skillId: skill, state: 'developing', confidence: 0.1, updatedAt: now),
        performance: null, independence: null,
        transfer: estimate('transfer', const {'passed': 1}, evidence: 1),
        decision: decision('r1'),
      );
      await port.saveSession(
        childId: 'c1', skillId: skill,
        mastery: MasteryRecord(childId: 'c1', skillId: skill, state: 'developing', confidence: 0.2, updatedAt: now),
        performance: estimate('performance', const {'accuracy': 1, 'trials': 6}),
        independence: null, transfer: null,
        decision: decision('r1'),
      );
      expect((await port.currentDimension(childId: 'c1', skillId: skill, dimension: 'transfer'))!.metrics['passed'], 1);
    });

    test('children, skills, and games are isolated from one another', () async {
      final port = harness.port;
      await port.saveSession(
        childId: 'c1', skillId: skill,
        mastery: MasteryRecord(childId: 'c1', skillId: skill, state: 'secure', confidence: 0.6, updatedAt: now),
        performance: estimate('performance', const {'accuracy': 1, 'trials': 6}),
        independence: null, transfer: null,
        decision: decision('r3'),
      );
      expect(await port.currentMastery(childId: 'c2', skillId: skill), isNull);
      expect(await port.currentMastery(childId: 'c1', skillId: 'math.count.cardinality'), isNull);
      expect(await port.currentDimension(childId: 'c2', skillId: skill, dimension: 'performance'), isNull);
      expect(await port.currentRung(childId: 'c2', gameId: game), isNull);
      expect(await port.currentRung(childId: 'c1', gameId: 'game.math.number-match'), isNull);
    });

    SkillEvidence evidence(String session, DateTime at, {String childId = 'c1', String skillId = skill, Map<String, int> errors = const {}}) => SkillEvidence(
          childId: childId, skillId: skillId, sessionId: session, at: at,
          gameId: game, mechanicId: 'drag-to-count', activityId: 'explorer-001', context: 'apples',
          rungId: 'r2', scaffold: 'guided', trials: 6, correct: 4, hints: 2, hintRequests: 1,
          adultAssists: 0, retries: 1, selfCorrections: 1, errors: errors,
        );

    test('skill evidence is appended with the session and read back in order, field for field', () async {
      final port = harness.port;
      expect(await port.skillEvidence(childId: 'c1'), isEmpty);
      for (final (i, at) in [now, now.add(const Duration(hours: 1))].indexed) {
        await port.saveSession(
          childId: 'c1', skillId: skill,
          mastery: MasteryRecord(childId: 'c1', skillId: skill, state: 'developing', confidence: 0.5, updatedAt: at),
          performance: null, independence: null, transfer: null, decision: decision('r2'),
          evidence: [evidence('s$i', at, errors: {'over_count': i + 1})],
        );
      }
      final all = await port.skillEvidence(childId: 'c1', skillId: skill);
      expect(all.map((e) => e.sessionId), ['s0', 's1']);
      final e = all.last;
      expect(e.at.isAtSameMomentAs(now.add(const Duration(hours: 1))), isTrue);
      expect([e.gameId, e.mechanicId, e.activityId, e.context, e.rungId, e.scaffold], [game, 'drag-to-count', 'explorer-001', 'apples', 'r2', 'guided']);
      expect([e.trials, e.correct, e.hints, e.hintRequests, e.adultAssists, e.retries, e.selfCorrections], [6, 4, 2, 1, 0, 1, 1]);
      expect(e.errors, {'over_count': 2});
      // Isolated per child and per skill.
      expect(await port.skillEvidence(childId: 'c2'), isEmpty);
      expect(await port.skillEvidence(childId: 'c1', skillId: 'math.count.cardinality'), isEmpty);
    });

    test("a dimension saved on its own (a grown-up's probe report) reads back", () async {
      final port = harness.port;
      await port.saveDimension(childId: 'c1', estimate: estimate('transfer', const {'passed': 1}, evidence: 2));
      final t = (await port.currentDimension(childId: 'c1', skillId: skill, dimension: 'transfer'))!;
      expect(t.metrics['passed'], 1);
      expect(t.evidenceCount, 2);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/skills/error_types.dart';
import 'package:nova_app/core/skills/skill_evidence.dart';
import 'package:nova_app/core/skills/skill_profile.dart';
import 'package:nova_app/core/skills/skill_profile_builder.dart';

import '../../support/fixture_content.dart';

/// The Skill Profile, against the real assessment rules and thresholds
/// (min-trials 6, emerging 0.4, developing 0.6, secure 0.85 with at most
/// 0.2 hints per round, transfer pass mark 0.7).
void main() {
  final content = loadRealBundle();
  const skill = 'math.count.one-to-one-5';
  final rule = content.assessmentRuleFor(skill);
  final params = content.allParameters();
  const builder = SkillProfileBuilder();
  final t0 = DateTime(2026, 5, 1, 9);
  var n = 0;

  SkillEvidence session(int correct, {int trials = 6, int hints = 0, String mechanic = 'drag-to-count', String game = 'game.math.bear-apples', String? skin, Map<String, int> errors = const {}, int day = 0}) =>
      SkillEvidence(
        childId: 'c',
        skillId: skill,
        sessionId: 's${n++}',
        at: t0.add(Duration(days: day, minutes: n)),
        gameId: game,
        mechanicId: mechanic,
        context: skin,
        trials: trials,
        correct: correct,
        hints: hints,
        errors: errors,
      );

  SkillProfile build(List<SkillEvidence> evidence, {DimensionEstimate? probe}) =>
      builder.build(skillId: skill, evidence: evidence, rule: rule, parameters: params, probe: probe);

  test('no evidence: Not yet, no confidence', () {
    final p = build(const []);
    expect(p.state, SkillState.notYet);
    expect(p.hasEvidence, isFalse);
    expect(p.confidence, 0);
  });

  test('evidence accumulates across sessions', () {
    final one = build([session(4)]);
    final three = build([session(4), session(5, skin: 'shells'), session(5, skin: 'fish')]);
    expect(one.sessions, 1);
    expect(three.sessions, 3);
    expect(three.attempts, 18);
    expect(three.rollingAccuracy, closeTo(14 / 18, 1e-9));
    expect(three.recentAccuracy, closeTo(5 / 6, 1e-9));
    expect(three.contexts, hasLength(3));
    expect(three.confidence, greaterThan(one.confidence));
  });

  test('a single session is judged exactly as the Mastery Engine judges it', () {
    expect(build([session(6)]).state, SkillState.secure);
    expect(build([session(4)]).state, SkillState.developing);
    expect(build([session(3)]).state, SkillState.emerging);
    expect(build([session(1)]).state, SkillState.notYet);
  });

  test('one bad session does not erase mastery; two in a row step it down one level', () {
    final good = [session(6), session(6), session(6)];
    expect(build(good).state, SkillState.secure);
    final oneBad = [...good, session(1)];
    expect(build(oneBad).state, SkillState.secure, reason: 'one bad day is not the child\'s ability');
    final twoBad = [...oneBad, session(1)];
    expect(build(twoBad).state, SkillState.developing, reason: 'down one step, not straight to Not yet');
  });

  test('the recent trend is calculated from the last sessions against the ones before', () {
    expect(build([session(3), session(3), session(5), session(6)]).trend, Trend.improving);
    expect(build([session(6), session(6), session(3), session(2)]).trend, Trend.declining);
    expect(build([session(5), session(5), session(5)]).trend, Trend.steady);
    expect(build([session(5)]).trend, Trend.unknown);
  });

  test('independence affects mastery: accurate with lots of help is not Secure', () {
    final helped = build([session(6, hints: 4), session(6, hints: 4)]);
    expect(helped.rollingAccuracy, 1);
    expect(helped.state, SkillState.developing);
    expect(helped.independence, isNot(Independence.independent));
    expect(helped.needsIndependence, isTrue);
    final alone = build([session(6), session(6)]);
    expect(alone.state, SkillState.secure);
    expect(alone.independence, Independence.independent);
  });

  test('consistency reflects how alike the sessions are', () {
    expect(build([session(5), session(5), session(5)]).consistency, Consistency.strong);
    expect(build([session(6), session(1), session(6), session(1)]).consistency, Consistency.weak);
  });

  test('repeated errors are detected -- a pattern across sessions, not a one-off slip', () {
    final slip = build([session(5, errors: {ErrorType.overCount: 1}), session(6)]);
    expect(slip.repeatedErrors, isEmpty);
    final pattern = build([session(3, errors: {ErrorType.overCount: 2}), session(4, errors: {ErrorType.overCount: 2, ErrorType.underCount: 1})]);
    expect(pattern.repeatedErrors, [ErrorType.overCount]);
    expect(pattern.errorCounts[ErrorType.overCount], 4);
    // Once the child stops making it, it is no longer a live pattern.
    final stopped = build([session(3, errors: {ErrorType.overCount: 2}), session(4, errors: {ErrorType.overCount: 2}), session(6)]);
    expect(stopped.repeatedErrors, isEmpty);
    // Support is not a mistake.
    final helped = build([session(6, errors: {ErrorType.hintRequested: 3}), session(6, errors: {ErrorType.hintRequested: 3})]);
    expect(helped.repeatedErrors, isEmpty);
  });

  test('transfer requires evidence in another mechanic, never accuracy alone or a new skin', () {
    final secure = [session(6), session(6), session(6)];
    expect(build(secure).state, SkillState.secure);
    // Perfect again, even in new picture skins: still Secure.
    final reskinned = [...secure, session(6, skin: 'shells'), session(6, skin: 'stars')];
    expect(build(reskinned).state, SkillState.secure);
    expect(build(reskinned).transferEvidence, 0);
    // A pass in a different mechanic: Transfer.
    final elsewhere = [...reskinned, session(5, mechanic: 'match-symbol-to-quantity', game: 'game.math.number-match')];
    final p = build(elsewhere);
    expect(p.state, SkillState.transfer);
    expect(p.transferEvidence, 1);
    expect(p.secureMechanics, {'drag-to-count'});
  });

  test('a new mechanic before Secure is practice, not transfer', () {
    final p = build([session(5, mechanic: 'match-symbol-to-quantity'), session(6), session(6)]);
    expect(p.state, SkillState.secure);
    expect(p.transferEvidence, 0);
  });

  test('a failed check in a new mechanic is not a pass', () {
    final p = build([session(6), session(6), session(6), session(3, mechanic: 'match-symbol-to-quantity')]);
    expect(p.state, SkillState.secure);
    expect(p.transferEvidence, 0);
  });

  test('a grown-up\'s passed probe gives Transfer only on top of Secure', () {
    final probe = DimensionEstimate(skillId: skill, dimension: 'transfer', metrics: const {'passed': 1}, evidenceCount: 1, lastUpdated: t0);
    expect(build([session(6), session(6)], probe: probe).state, SkillState.transfer);
    expect(build([session(4)], probe: probe).state, SkillState.developing);
    expect(build(const [], probe: probe).state, SkillState.notYet);
  });

  test('the recent run counts sessions in a row on the skill', () {
    final history = [
      PlayedSession(at: t0.add(const Duration(minutes: 3)), gameId: 'g', mechanicId: 'm', skills: const [skill]),
      PlayedSession(at: t0.add(const Duration(minutes: 2)), gameId: 'g', mechanicId: 'm', skills: const [skill]),
      PlayedSession(at: t0.add(const Duration(minutes: 1)), gameId: 'h', mechanicId: 'm', skills: const ['other']),
    ];
    final p = builder.build(skillId: skill, evidence: [session(5)], rule: rule, parameters: params, history: history);
    expect(p.recentRun, 2);
  });
}

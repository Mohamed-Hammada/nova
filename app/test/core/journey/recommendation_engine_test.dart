import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/journey/curriculum_engine.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/skills/error_types.dart';
import 'package:nova_app/core/skills/skill_evidence.dart';
import 'package:nova_app/core/skills/skill_profile.dart';

import '../../support/fixture_content.dart';

/// The scored recommendation, against the real curriculum. The age-4
/// adventure "Counting Orchard" is: 001 Bear's Apples (one-to-one counting,
/// required), 002 Word Hunt, 003 More or Less (compare, which builds on
/// one-to-one counting), 004 Feelings, 005 Clap Syllables, 006 Peekaboo
/// Pairs (all required), 007 Pattern Train (practice), 008 challenge, 009
/// optional, 010 Bear's Apples again in a new skin (review).
void main() {
  final content = loadRealBundle();
  final curriculum = Curriculum.fromContent(content);
  final engine = CurriculumEngine(curriculum);
  final t0 = DateTime(2026, 6, 1, 9);
  ChildProfile child(int age) => ChildProfile(id: 'c', name: 'Sara', age: age);
  Activity act(String id) => curriculum.activity(id)!;
  const oneToOne = 'math.count.one-to-one-5';
  const compare = 'math.compare.more-fewer';

  ActivityRecord played(String id, DateTime at, {AdaptiveMove move = AdaptiveMove.stay, int attempts = 1, int stars = 2}) {
    var r = ActivityRecord.fresh('c', id, at);
    for (var i = 0; i < attempts; i++) {
      r = r.started(at);
    }
    return r.finished(at, completed: true, stars: stars, accuracy: 0.7, outcome: SessionOutcome(stars: stars, accuracy: 0.7, move: move, scaffold: ScaffoldLevel.hintOnRequest));
  }

  PlayedSession session(String activityId, DateTime at) {
    final a = act(activityId);
    return PlayedSession(at: at, activityId: a.id, gameId: a.gameFor('en'), mechanicId: a.mechanics.first, skills: a.skills);
  }

  JourneyProgress evaluate(Map<String, ActivityRecord> records, ChildEvidence evidence, {int age = 4}) =>
      engine.evaluate(child(age), records, evidence: evidence, language: 'en');

  test('every recommendation explains itself, internally', () {
    final p = evaluate(const {}, const ChildEvidence());
    final why = p.recommendation!.why!;
    expect(why.activity.id, p.recommended!.id);
    expect(why.reason, SelectionReason.nextRequired);
    expect(why.explain(), contains('next_required'));
    expect(p.recommendation!.candidates.first.score, greaterThanOrEqualTo(p.recommendation!.candidates.last.score));
  });

  test('a weak skill receives reinforcement: its prerequisite comes first', () {
    // More or Less went poorly, and one-to-one counting underneath it is shaky.
    final records = {'explorer-003': played('explorer-003', t0)};
    final evidence = ChildEvidence(
      profiles: {
        compare: const SkillProfile(skillId: compare, state: SkillState.emerging, sessions: 1),
        oneToOne: const SkillProfile(skillId: oneToOne, state: SkillState.emerging, sessions: 1),
      },
      history: [session('explorer-003', t0)],
    );
    final p = evaluate(records, evidence);
    expect(p.recommended!.skills, contains(oneToOne));
    expect(p.recommendation!.why!.reason, SelectionReason.practiceMissingSkill);
    expect(p.recommendation!.reason, RecommendationReason.practice);
    // Without that evidence the journey simply moves on to another area.
    final plain = evaluate(records, ChildEvidence(history: [session('explorer-003', t0)]));
    expect(plain.recommended!.skills, isNot(contains(oneToOne)));
  });

  test('prerequisite skills influence recommendations: nothing is built on a shaky prerequisite', () {
    final evidence = ChildEvidence(profiles: {oneToOne: const SkillProfile(skillId: oneToOne, state: SkillState.emerging, sessions: 2)});
    final ranked = evaluate(const {}, evidence).recommendation!.candidates;
    final moreOrLess = ranked.firstWhere((c) => c.activity.id == 'explorer-003');
    expect(moreOrLess.factors.map((f) => f.name), contains('prerequisite_not_ready'));
    final bear = ranked.firstWhere((c) => c.activity.id == 'explorer-001');
    expect(bear.score, greaterThan(moreOrLess.score));
  });

  test('repeated errors influence selection: the same skill, in another setting', () {
    final records = {'explorer-001': played('explorer-001', t0)};
    final evidence = ChildEvidence(
      profiles: {oneToOne: const SkillProfile(skillId: oneToOne, state: SkillState.developing, sessions: 2, repeatedErrors: [ErrorType.overCount], errorCounts: {ErrorType.overCount: 4})},
      history: [session('explorer-001', t0)],
    );
    final p = evaluate(records, evidence);
    expect(p.recommendation!.why!.reason, SelectionReason.addressRepeatedError);
    expect(p.recommended!.skills, contains(oneToOne));
    expect(p.recommended!.id, isNot('explorer-001'), reason: 'not the very same activity again');
    expect(p.recommendation!.reason, RecommendationReason.practice);
  });

  test('a strong skill can move to transfer: a secure skill is checked in a new mechanic', () {
    // Counting Orchard done; Story Bridge has Number Match, which trains
    // cardinality with a different mechanic than Bear's Apples.
    final orchard = curriculum.stages.firstWhere((s) => s.id == 'stage.explorer.counting-orchard');
    final records = {for (final (i, a) in orchard.required.indexed) a.id: played(a.id, t0.add(Duration(minutes: i)))};
    const cardinality = 'math.count.cardinality';
    final evidence = ChildEvidence(profiles: {
      cardinality: const SkillProfile(skillId: cardinality, state: SkillState.secure, sessions: 3, mechanics: {'drag-to-count'}, secureMechanics: {'drag-to-count'}),
    });
    final p = evaluate(records, evidence);
    expect(p.current.stage.id, 'stage.explorer.story-bridge');
    expect(p.recommended!.mechanics, isNot(contains('drag-to-count')));
    expect(p.recommended!.skills, contains(cardinality));
    expect(p.recommendation!.why!.reason, SelectionReason.transferProbe);
    expect(p.recommendation!.reason, RecommendationReason.newWay);
    // Already Transfer: no more checking needed.
    final done = evaluate(records, ChildEvidence(profiles: {cardinality: const SkillProfile(skillId: cardinality, state: SkillState.transfer, sessions: 4, secureMechanics: {'drag-to-count'})}));
    expect(done.recommendation!.why!.reason, isNot(SelectionReason.transferProbe));
  });

  test('accurate but helped: build independence', () {
    final records = {'explorer-002': played('explorer-002', t0)};
    final evidence = ChildEvidence(
      profiles: {oneToOne: const SkillProfile(skillId: oneToOne, state: SkillState.developing, sessions: 2, rollingAccuracy: 0.95, independence: Independence.needsHelp)},
      history: [session('explorer-002', t0)],
    );
    final p = evaluate(records, evidence);
    expect(p.recommended!.skills, contains(oneToOne));
    expect(p.recommendation!.why!.reason, SelectionReason.buildIndependence);
  });

  test('recommendations avoid unnecessary repetition', () {
    // Bear's Apples three times in a row, played well.
    final records = {'explorer-001': played('explorer-001', t0, attempts: 3, move: AdaptiveMove.stay)};
    final history = [for (var i = 2; i >= 0; i--) session('explorer-001', t0.subtract(Duration(minutes: i)))];
    final p = evaluate(records, ChildEvidence(history: history, profiles: {oneToOne: SkillProfile(skillId: oneToOne, state: SkillState.developing, sessions: 3, recentRun: 3)}));
    expect(p.recommended!.gameFor('en'), isNot('game.math.bear-apples'));
    expect(p.recommended!.skills, isNot(contains(oneToOne)));
    expect(p.recommended!.domain, isNot(DevelopmentalDomain.numeracy));
  });

  test('variety: after one activity, the next differs in game and area', () {
    var records = <String, ActivityRecord>{};
    var history = <PlayedSession>[];
    final seen = <String>[];
    for (var i = 0; i < 4; i++) {
      final p = evaluate(records, ChildEvidence(history: history));
      final a = p.recommended!;
      seen.add(a.gameFor('en'));
      final at = t0.add(Duration(minutes: i));
      records = {...records, a.id: played(a.id, at)};
      history = [session(a.id, at), ...history];
    }
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], isNot(seen[i - 1]), reason: 'no game twice in a row: $seen');
    }
  });

  test('recommendations stay within the curriculum and the child\'s age, whatever the evidence', () {
    // Strong evidence for skills far ahead, a repeated error, a secure skill.
    final evidence = ChildEvidence(profiles: {
      'math.add-sub.within-20': const SkillProfile(skillId: 'math.add-sub.within-20', state: SkillState.emerging, sessions: 3, repeatedErrors: [ErrorType.overCount]),
      'lit.en.read-words': const SkillProfile(skillId: 'lit.en.read-words', state: SkillState.secure, sessions: 3, secureMechanics: {'x'}),
      oneToOne: const SkillProfile(skillId: oneToOne, state: SkillState.secure, sessions: 3, secureMechanics: {'drag-to-count'}),
    });
    for (final age in [2, 3, 4, 5, 6, 7, 8]) {
      final p = evaluate(const {}, evidence, age: age);
      final rec = p.recommended!;
      expect(rec.stageId, p.current.stage.id, reason: 'age $age');
      expect(engine.canStart(p, rec.id), isTrue, reason: 'age $age');
      expect(rec.supportsLanguage('en'), isTrue);
      for (final c in p.recommendation!.candidates) {
        expect(c.activity.stageId, p.current.stage.id);
        expect(p.statusOf(c.activity.id), isNot(ActivityStatus.locked), reason: '${c.activity.id} at age $age');
      }
    }
  });

  test('locked activities remain impossible, even after brilliant play', () {
    final challenge = act('explorer-008');
    expect(challenge.prerequisites, isNotEmpty);
    final records = {'explorer-004': played('explorer-004', t0, move: AdaptiveMove.advance, stars: 3)};
    final evidence = ChildEvidence(profiles: {
      for (final s in challenge.skills) s: SkillProfile(skillId: s, state: SkillState.secure, sessions: 5, secureMechanics: const {'other'}),
    });
    final p = evaluate(records, evidence);
    expect(p.statusOf(challenge.id), ActivityStatus.locked);
    expect(p.recommendation!.candidates.map((c) => c.activity.id), isNot(contains(challenge.id)));
    expect(engine.canStart(p, challenge.id), isFalse);
  });

  test('the recommendation keeps to the child\'s language', () {
    final p = engine.evaluate(child(4), const {}, language: 'ar');
    for (final c in p.recommendation!.candidates) {
      expect(c.activity.supportsLanguage('ar'), isTrue);
    }
  });
}

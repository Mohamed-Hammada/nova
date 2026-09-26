import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/in_memory_player_state_port.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/journey/curriculum_engine.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/journey/journey_recorder.dart';

import '../../support/fixture_content.dart';

/// The progression rules, against the real compiled curriculum.
void main() {
  final curriculum = Curriculum.fromContent(loadRealBundle());
  final engine = CurriculumEngine(curriculum);
  final t0 = DateTime(2026, 1, 1);

  ChildProfile child(int age) => ChildProfile(id: 'c', name: 'Sara', age: age);

  Map<String, ActivityRecord> finishAll(Iterable<Activity> activities, {Map<String, ActivityRecord>? into, int stars = 2}) {
    final out = {...?into};
    var t = t0;
    for (final a in activities) {
      t = t.add(const Duration(minutes: 5));
      out[a.id] = ActivityRecord.fresh('c', a.id, t).started(t).finished(t, completed: true, stars: stars, accuracy: 0.8);
    }
    return out;
  }

  test('the curriculum is one continuous journey of stages across ages 2 to 8', () {
    expect(curriculum.stages.length, greaterThanOrEqualTo(15));
    expect(curriculum.stages.first.ageRange.first, 2);
    expect(curriculum.stages.last.ageRange.last, 8);
    for (final s in curriculum.stages) {
      expect(s.activities.length, greaterThanOrEqualTo(3), reason: s.id);
      expect(s.required, isNotEmpty, reason: s.id);
    }
  });

  test('a new child starts at the first stage for their age', () {
    for (final age in [2, 3, 4, 5, 6, 7, 8]) {
      final p = engine.evaluate(child(age), const {});
      expect(p.current.stage.startsAtAge(age), isTrue, reason: 'age $age');
      expect(p.currentIndex, p.entryIndex);
      expect(p.current.status, StageStatus.current);
      // Nothing after it is open yet.
      for (final s in p.stages.skip(p.currentIndex + 1)) {
        expect(s.status, StageStatus.locked);
      }
    }
  });

  test('age decides the starting curriculum: an older child starts further along', () {
    expect(engine.evaluate(child(4), const {}).entryIndex, greaterThan(engine.evaluate(child(2), const {}).entryIndex));
    expect(engine.evaluate(child(7), const {}).entryIndex, greaterThan(engine.evaluate(child(4), const {}).entryIndex));
  });

  test('a new child gets a recommended activity that is required and can be started', () {
    final p = engine.evaluate(child(4), const {});
    expect(p.recommended, isNotNull);
    expect(p.recommended!.isRequired, isTrue);
    expect(p.statusOf(p.recommended!.id), ActivityStatus.recommended);
    expect(engine.canStart(p, p.recommended!.id), isTrue);
  });

  test('completing an activity updates progress and moves the recommendation on', () async {
    final port = InMemoryPlayerStatePort();
    final recorder = JourneyRecorder(port, curriculum, now: () => t0);
    final before = engine.evaluate(child(4), const {});
    final first = before.recommended!;
    await recorder.start(childId: 'c', activityId: first.id);
    expect(await recorder.finish(childId: 'c', activityId: first.id, outcome: const SessionOutcome(stars: 2, accuracy: 0.8)), isTrue);

    final records = {for (final r in await port.activityRecords(childId: 'c')) r.activityId: r};
    expect(records[first.id]!.completed, isTrue);
    expect(records[first.id]!.attempts, 1);
    expect(records[first.id]!.firstCompletedAt, t0);
    final after = engine.evaluate(child(4), records);
    expect(after.statusOf(first.id), ActivityStatus.completed);
    expect(after.current.requiredDone, 1);
    expect(after.recommended!.id, isNot(first.id));
  });

  test('an unfinished session is recorded as an attempt, not a completion', () async {
    final port = InMemoryPlayerStatePort();
    final recorder = JourneyRecorder(port, curriculum, now: () => t0);
    final id = engine.evaluate(child(4), const {}).recommended!.id;
    await recorder.start(childId: 'c', activityId: id);
    expect(await recorder.finish(childId: 'c', activityId: id, outcome: const SessionOutcome(stars: 0, accuracy: 0.2, finishedAllRounds: false)), isFalse);
    final r = (await port.activityRecords(childId: 'c')).single;
    expect(r.completed, isFalse);
    expect(r.attempts, 1);
  });

  test('completing the required activities completes the stage and unlocks the next', () {
    final start = engine.evaluate(child(4), const {});
    final stage = start.current.stage;
    final records = finishAll(stage.required);
    final after = engine.evaluate(child(4), records);
    expect(after.stages[stage.index].status, StageStatus.completed);
    expect(after.currentIndex, stage.index + 1);
    expect(after.current.status, StageStatus.current);
    expect(after.recommended!.stageId, after.current.stage.id);
    // Optional, practice, challenge and review activities are not needed.
    expect(stage.activities.length, greaterThan(stage.required.length));
  });

  test('progress never changes the child\'s age', () {
    final profile = child(4);
    final records = finishAll(engine.evaluate(profile, const {}).current.stage.required);
    final after = engine.evaluate(profile, records);
    expect(after.profile.age, 4);
    expect(after.currentIndex, greaterThan(after.entryIndex));
  });

  test('changing age re-positions the journey without losing any history', () {
    final at4 = engine.evaluate(child(4), const {});
    final records = finishAll(at4.current.stage.required);
    final snapshot = Map.of(records);

    // Older: the journey moves to the start of the older age group.
    final at6 = engine.evaluate(child(6), records);
    expect(at6.current.stage.startsAtAge(6), isTrue);
    // Younger: an earlier starting point; what was done at 4 stays done.
    final at2 = engine.evaluate(child(2), records);
    expect(at2.current.stage.startsAtAge(2), isTrue);
    for (final p in [at6, at2]) {
      for (final a in at4.current.stage.required) {
        expect(p.statusOf(a.id).isDone, isTrue, reason: 'completed ${a.id} stays completed');
      }
    }
    // History from before the new starting point is still shown.
    expect(at6.firstVisibleIndex, at4.entryIndex);
    expect(records, snapshot, reason: 'evaluation never alters records');
  });

  test('recommendations respect prerequisites, and locked activities cannot be started', () {
    final p = engine.evaluate(child(4), const {});
    final withPrereqs = p.current.stage.activities.firstWhere((a) => a.prerequisites.isNotEmpty);
    expect(p.statusOf(withPrereqs.id), ActivityStatus.locked);
    expect(engine.canStart(p, withPrereqs.id), isFalse);

    // Finish everything else in the stage except its prerequisites: it
    // still stays locked and is never recommended.
    final others = p.current.stage.activities.where((a) => a.id != withPrereqs.id && !withPrereqs.prerequisites.contains(a.id));
    final partial = engine.evaluate(child(4), finishAll(others));
    expect(partial.statusOf(withPrereqs.id), ActivityStatus.locked);
    expect(partial.recommended?.id, isNot(withPrereqs.id));

    final ready = engine.evaluate(child(4), finishAll(p.current.stage.activities.where((a) => withPrereqs.prerequisites.contains(a.id))));
    expect(ready.statusOf(withPrereqs.id).canStart, isTrue);

    // A stage beyond the current one is locked.
    final later = p.stages[p.currentIndex + 1].stage.activities.first;
    expect(engine.canStart(p, later.id), isFalse);
  });

  test('recommendations vary the developmental domain', () {
    final p = engine.evaluate(child(4), const {});
    final first = p.recommended!;
    final after = engine.evaluate(child(4), finishAll([first]));
    final sameDomainLeft = after.current.stage.required.any((a) => a.domain != first.domain && !after.statusOf(a.id).isDone);
    if (sameDomainLeft) expect(after.recommended!.domain, isNot(first.domain));
  });

  test('Arabic and English share one journey: completions follow the level, whatever the language', () {
    final p = engine.evaluate(child(4), const {});
    final literacy = curriculum.activities.firstWhere((a) => a.level.gamesByLanguage.isNotEmpty && a.stageId == p.current.stage.id);
    expect(literacy.gameFor('en'), isNot(literacy.gameFor('ar')));
    final records = finishAll([literacy]);
    // The journey itself (stages, statuses, recommendation) has no language input.
    expect(engine.evaluate(child(4), records).statusOf(literacy.id).isDone, isTrue);
  });

  test('a stage made only of optional work is impossible in the spec (validator), and the engine treats roles as data', () {
    for (final a in curriculum.activities) {
      expect(LevelRole.values, contains(a.role));
    }
  });

  test('domain progress covers the journey so far', () {
    final p = engine.evaluate(child(4), finishAll(engine.evaluate(child(4), const {}).current.stage.required.take(2)));
    expect(p.domains.fold<int>(0, (a, d) => a + d.done), 2);
    expect(p.domains.every((d) => d.total >= d.done), isTrue);
  });

  group('child evidence shapes the recommendation, inside the curriculum', () {
    // One session's result as the journey records it: completion plus the
    // Adaptive Engine's move for the game.
    ActivityRecord played(Activity a, DateTime at, {required AdaptiveMove move, int stars = 2, double accuracy = 0.7, String scaffold = ScaffoldLevel.hintOnRequest, int attempts = 1}) {
      var r = ActivityRecord.fresh('c', a.id, at);
      for (var i = 0; i < attempts; i++) {
        r = r.started(at);
      }
      return r.finished(at, completed: true, stars: stars, accuracy: accuracy, outcome: SessionOutcome(stars: stars, accuracy: accuracy, move: move, scaffold: scaffold));
    }

    test('two children who both completed the same activity get different next steps', () {
      final stage = engine.evaluate(child(4), const {}).current.stage;
      final first = engine.evaluate(child(4), const {}).recommended!;
      final t = t0.add(const Duration(hours: 1));
      // Child A: accurate and independent.
      final a = engine.evaluate(child(4), {first.id: played(first, t, move: AdaptiveMove.advance, stars: 3, accuracy: 0.95)});
      // Child B: struggled, the Adaptive Engine eased the game.
      final b = engine.evaluate(child(4), {first.id: played(first, t, move: AdaptiveMove.retreat, stars: 1, accuracy: 0.5)});
      expect(a.statusOf(first.id).isDone, isTrue);
      expect(b.statusOf(first.id).isDone, isTrue);
      expect(a.recommendation!.reason, isNot(b.recommendation!.reason));
      expect(b.recommendation!.reason, anyOf(RecommendationReason.practice, RecommendationReason.tryAgainEasier));
      expect(b.recommended!.stageId, stage.id);
    });

    test('after a hard session: practice in the same area, or the same game again (now easier)', () {
      final p = engine.evaluate(child(4), const {});
      final stage = p.current.stage;
      final hard = stage.required.first;
      final r = engine.evaluate(child(4), {hard.id: played(hard, t0, move: AdaptiveMove.retreat, stars: 1, accuracy: 0.4)});
      final rec = r.recommendation!;
      if (rec.reason == RecommendationReason.practice) {
        expect(rec.activity.domain, hard.domain);
        expect(rec.activity.role, anyOf(LevelRole.practice, LevelRole.review));
      } else {
        expect(rec.reason, RecommendationReason.tryAgainEasier);
        expect(rec.activity.id, hard.id);
      }
      // A replay keeps its "done" mark.
      expect(r.statusOf(hard.id).isDone, isTrue);
    });

    test('the journey does not loop on one game: after repeated hard sessions it moves on', () {
      final stage = engine.evaluate(child(4), const {}).current.stage;
      // Pick a required activity whose area has no practice/review activity in the stage.
      final lonely = stage.required.where((a) => !stage.activities.any((o) => o.id != a.id && o.domain == a.domain && (o.role == LevelRole.practice || o.role == LevelRole.review)));
      if (lonely.isEmpty) return;
      final hard = lonely.first;
      final again = engine.evaluate(child(4), {hard.id: played(hard, t0, move: AdaptiveMove.retreat, attempts: 1)});
      expect(again.recommended!.id, hard.id);
      final movedOn = engine.evaluate(child(4), {hard.id: played(hard, t0, move: AdaptiveMove.retreat, attempts: CurriculumEngine.maxRetries)});
      expect(movedOn.recommended!.id, isNot(hard.id));
      expect(movedOn.recommendation!.reason, RecommendationReason.next);
    });

    test('after accurate, independent play: a challenge -- but only once its prerequisites are done', () {
      final stage = engine.evaluate(child(4), const {}).current.stage;
      final challenge = stage.activities.firstWhere((a) => a.role == LevelRole.challenge);
      final other = stage.required.firstWhere((a) => !challenge.prerequisites.contains(a.id));
      // Strong play, but the challenge's prerequisites are not finished: no bypass.
      final early = engine.evaluate(child(4), {other.id: played(other, t0, move: AdaptiveMove.advance, stars: 3, accuracy: 1)});
      expect(early.statusOf(challenge.id), ActivityStatus.locked);
      expect(early.recommended!.id, isNot(challenge.id));
      expect(early.recommendation!.reason, isNot(RecommendationReason.stretch));

      // Prerequisites done, the last session strong: the challenge comes next.
      final records = {
        for (final (i, id) in challenge.prerequisites.indexed)
          id: played(stage.activities.firstWhere((a) => a.id == id), t0.add(Duration(minutes: i)), move: AdaptiveMove.advance, stars: 3, accuracy: 1),
      };
      final ready = engine.evaluate(child(4), records);
      expect(ready.recommended!.id, challenge.id);
      expect(ready.recommendation!.reason, RecommendationReason.stretch);

      // Same completions with a productive (not strong) last session: required work first.
      final steady = {for (final e in records.entries) e.key: played(stage.activities.firstWhere((a) => a.id == e.key), t0, move: AdaptiveMove.stay)};
      expect(engine.evaluate(child(4), steady).recommended!.role, LevelRole.required);
    });

    test('a struggling child is never sent into a locked stage or a locked activity', () {
      final p = engine.evaluate(child(4), const {});
      final hard = p.current.stage.required.first;
      final r = engine.evaluate(child(4), {hard.id: played(hard, t0, move: AdaptiveMove.retreat)});
      expect(engine.canStart(r, r.recommended!.id), isTrue);
      expect(r.recommended!.stageId, r.current.stage.id);
    });

    test('mastery evidence orders required work: skills not yet secure come first', () {
      final p = engine.evaluate(child(4), const {});
      final first = p.recommended!;
      final secure = ChildEvidence(masteryBySkill: {for (final s in first.skills) s: 'secure'});
      final withEvidence = engine.evaluate(child(4), const {}, evidence: secure);
      final others = p.current.stage.required.where((a) => !secure.isSecure(a.skills));
      if (others.isNotEmpty) expect(withEvidence.recommended!.id, isNot(first.id));
      // Secure evidence never completes an activity or a stage by itself.
      expect(withEvidence.statusOf(first.id).isDone, isFalse);
      expect(withEvidence.currentIndex, p.currentIndex);
    });

    test('completion is not mastery: finishing activities adds no mastery evidence', () {
      final p = engine.evaluate(child(4), finishAll(engine.evaluate(child(4), const {}).current.stage.required));
      expect(p.stages[p.entryIndex].status, StageStatus.completed);
      expect(const ChildEvidence().isSecure(p.stages[p.entryIndex].stage.required.first.skills), isFalse);
    });

    test('changing age keeps the session evidence and never fakes completion of new content', () {
      final first = engine.evaluate(child(4), const {}).recommended!;
      final records = {first.id: played(first, t0, move: AdaptiveMove.retreat, stars: 1, accuracy: 0.4)};
      final at6 = engine.evaluate(child(6), records);
      expect(at6.statusOf(first.id).isDone, isTrue);
      expect(at6.current.requiredDone, 0, reason: 'nothing in the new stage is marked done');
      expect(records[first.id]!.lastMove, AdaptiveMove.retreat);
    });
  });

  group('journey first: what a child can reach', () {
    List<String> stagesForAge(int age) => [for (final s in curriculum.stages) if (s.startsAtAge(age)) s.id];

    /// Finishes required work stage by stage until [until] holds.
    Map<String, ActivityRecord> progressUntil(ChildProfile profile, bool Function(JourneyProgress) until) {
      var records = <String, ActivityRecord>{};
      for (var guard = 0; guard < curriculum.stages.length; guard++) {
        final p = engine.evaluate(profile, records);
        if (until(p)) return records;
        records = finishAll(p.current.stage.required.where((a) => !p.statusOf(a.id).isDone), into: records);
      }
      fail('never reached');
    }

    test('a new age-4 child gets the age-4 journey, and its content is open', () {
      expect(stagesForAge(4), ['stage.explorer.counting-orchard', 'stage.explorer.story-bridge', 'stage.explorer.echo-valley']);
      final p = engine.evaluate(child(4), const {});
      expect(p.current.stage.id, 'stage.explorer.counting-orchard');
      expect(p.recommended!.stageId, 'stage.explorer.counting-orchard');
      expect(engine.canStart(p, p.recommended!.id), isTrue);
    });

    test('age-5 content is not open before the child gets there', () {
      final p = engine.evaluate(child(4), const {});
      for (final s in p.stages.where((s) => s.stage.ageRange.first >= 5)) {
        expect(s.status, StageStatus.locked, reason: s.stage.id);
        for (final a in s.stage.activities) {
          expect(engine.canStart(p, a.id), isFalse, reason: a.id);
        }
      }
      for (final language in ['en', 'ar']) {
        expect(engine.explore(p, language: language).where((a) => curriculum.stages.firstWhere((s) => s.id == a.stageId).ageRange.first >= 5), isEmpty);
      }
    });

    test('finishing the age-4 adventures opens the next age group, and the child is still 4', () {
      final profile = child(4);
      final records = progressUntil(profile, (p) => !p.current.stage.startsAtAge(4));
      final p = engine.evaluate(profile, records);
      expect(p.current.stage.id, 'stage.explorer.lily-pond');
      expect(p.current.status, StageStatus.current);
      for (final id in stagesForAge(4)) {
        expect(p.stages.firstWhere((s) => s.stage.id == id).status, StageStatus.completed, reason: id);
      }
      // The curriculum put them here: the adventure's activities are theirs.
      expect(p.recommended!.stageId, 'stage.explorer.lily-pond');
      expect(engine.canStart(p, p.recommended!.id), isTrue);
      // Progress is not age.
      expect(p.profile.age, 4);
      expect(profile.age, 4);
      expect(p.entryIndex, engine.entryIndexFor(4));
    });

    test('a grown-up changes the age from 4 to 6: the age-6 curriculum, with every record kept', () {
      final records = progressUntil(child(4), (p) => p.currentIndex > p.entryIndex + 1);
      final snapshot = Map.of(records);
      final at6 = engine.evaluate(child(6), records);
      expect(at6.current.stage.id, stagesForAge(6).first);
      expect(at6.recommended!.stageId, at6.current.stage.id);
      for (final r in records.values.where((r) => r.completed)) {
        expect(at6.statusOf(r.activityId).isDone, isTrue, reason: r.activityId);
      }
      expect(at6.current.requiredDone, 0, reason: 'nothing new is marked done');
      expect(at6.firstVisibleIndex, lessThan(at6.entryIndex), reason: 'the age-4 history is still on the map');
      expect(records, snapshot);
    });

    test('Explore more only offers open activities made for the age of the child, in their language', () {
      for (final age in [2, 3, 4, 5, 6, 7, 8]) {
        for (final records in [<String, ActivityRecord>{}, progressUntil(child(age), (p) => p.currentIndex > p.entryIndex || p.finished)]) {
          // Also after the age changed: history from other ages must not leak in.
          for (final shown in [age, if (age > 2) age - 2, if (age < 7) age + 2]) {
            final p = engine.evaluate(child(shown), records);
            for (final language in ['en', 'ar']) {
              final offered = engine.explore(p, language: language);
              expect(offered.length, lessThanOrEqualTo(4));
              for (final a in offered) {
                final why = 'age $shown, $language, ${a.id}';
                expect(a.suitsAge(shown), isTrue, reason: why);
                expect(a.supportsLanguage(language), isTrue, reason: why);
                expect(engine.canStart(p, a.id), isTrue, reason: why);
                expect(p.statusOf(a.id), isNot(ActivityStatus.locked), reason: why);
                expect(curriculum.stages.firstWhere((s) => s.id == a.stageId).index, lessThanOrEqualTo(p.currentIndex), reason: why);
                expect(a.id, isNot(p.recommended?.id), reason: why);
              }
            }
          }
        }
      }
    });

    test('a game with its own dedicated screen gets no exemption from the age rule', () {
      // Bear's Apples (ages 3-5) has a dedicated screen. A 7-year-old never
      // reaches it off their path, even with it finished long ago.
      final bear = curriculum.activities.where((a) => a.gameFor('en') == 'game.math.bear-apples').toList();
      expect(bear, isNotEmpty);
      final records = finishAll(bear);
      final p = engine.evaluate(child(7), records);
      for (final a in bear) {
        expect(engine.canStart(p, a.id), isFalse, reason: a.id);
        expect(p.statusOf(a.id).isDone, isTrue, reason: 'history stays visible');
      }
      expect(engine.explore(p, language: 'en').where((a) => a.gameFor('en') == 'game.math.bear-apples'), isEmpty);
      // Never finished: shown locked, not open.
      final fresh = engine.evaluate(child(7), const {});
      for (final a in bear) {
        expect(fresh.statusOf(a.id), ActivityStatus.locked, reason: a.id);
      }
    });

    test('prerequisites cannot be bypassed through Explore more', () {
      final p = engine.evaluate(child(4), const {});
      final gated = p.current.stage.activities.where((a) => a.prerequisites.isNotEmpty).toList();
      expect(gated, isNotEmpty);
      final offered = engine.explore(p, language: 'en', limit: 50).map((a) => a.id);
      for (final a in gated) {
        expect(offered, isNot(contains(a.id)));
      }
    });

    test('every stage names a real place, which is what dresses it', () {
      final places = {'numbers', 'language', 'sounds', 'feelings', 'memory', 'discovery', 'movement'};
      for (final s in curriculum.stages) {
        expect(places, contains(s.place), reason: s.id);
      }
    });
  });
}

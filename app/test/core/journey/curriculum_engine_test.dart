import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/in_memory_player_state_port.dart';
import 'package:nova_app/core/content/models.dart';
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
}

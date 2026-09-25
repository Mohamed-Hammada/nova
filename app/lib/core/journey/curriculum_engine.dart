import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';

import 'journey_models.dart';

/// The whole curriculum as one continuous journey: every stage of every
/// age group's journey in the spec, in age order.
class Curriculum {
  Curriculum(this.stages) : _activities = {for (final s in stages) for (final a in s.activities) a.id: a};

  final List<JourneyStage> stages;
  final Map<String, Activity> _activities;

  Activity? activity(String id) => _activities[id];
  Iterable<Activity> get activities => _activities.values;
  bool get isEmpty => stages.isEmpty;

  /// Builds the curriculum from the content bundle. Journeys without
  /// stages (older bundles) become one stage each.
  factory Curriculum.fromContent(ContentRuntime content) {
    final journeys = [...content.journeys]..sort((a, b) => a.ageRange.first.compareTo(b.ageRange.first));
    final stages = <JourneyStage>[];
    for (final journey in journeys) {
      final levels = {for (final l in journey.levels) l.id: l};
      final specs = journey.stages.isNotEmpty
          ? journey.stages
          : [StageSpec(id: 'stage.${journey.id}', nameKey: journey.nameKey, place: 'numbers', ageRange: journey.ageRange, levelIds: [for (final l in journey.levels) l.id])];
      for (final spec in specs) {
        final index = stages.length;
        stages.add(JourneyStage(
          id: spec.id,
          nameKey: spec.nameKey,
          place: spec.place,
          ageRange: spec.ageRange,
          index: index,
          activities: [
            for (final id in spec.levelIds)
              if (levels[id] != null) _activity(content, levels[id]!, spec.id),
          ],
        ));
      }
    }
    return Curriculum(stages);
  }

  static Activity _activity(ContentRuntime content, JourneyLevel level, String stageId) {
    final gameIds = level.gameId != null ? [level.gameId!] : level.gamesByLanguage.values.toList();
    final games = [for (final id in gameIds) if (content.hasGame(id)) content.game(id)];
    final first = games.isEmpty ? null : games.first;
    final skills = first?.primarySkillIds ?? const <String>[];
    final languages = level.gameId != null ? {...?first?.languageDependencies} : level.gamesByLanguage.keys.toSet();
    return Activity(
      id: level.id,
      stageId: stageId,
      level: level,
      role: level.role,
      prerequisites: level.prerequisites,
      minAge: first?.ageRange.first ?? 2,
      maxAge: first?.ageRange.last ?? 8,
      domains: _domains(content, skills),
      skills: skills,
      languages: languages,
      // A session is six short rounds: about three minutes.
      minutes: level.minutes ?? 3,
    );
  }

  /// Maps a game's skills onto developmental domains. The spec's skill
  /// domains are the source; literacy is split by what the skill trains
  /// (hearing sounds, words and meaning, or print), because a journey
  /// should vary between those as much as between maths and feelings.
  static List<DevelopmentalDomain> _domains(ContentRuntime content, List<String> skills) {
    final out = <DevelopmentalDomain>[];
    for (final id in skills) {
      final specDomains = content.hasSkill(id) ? content.skill(id).domains : const <String>[];
      for (final d in specDomains) {
        final domain = switch (d) {
          'math' => DevelopmentalDomain.numeracy,
          'social_emotional' => DevelopmentalDomain.socialEmotional,
          'memory' => DevelopmentalDomain.memory,
          'executive_function' => DevelopmentalDomain.attention,
          'cognitive' => DevelopmentalDomain.problemSolving,
          'language_literacy' => _literacy(id),
          _ => DevelopmentalDomain.problemSolving,
        };
        if (!out.contains(domain)) out.add(domain);
      }
    }
    return out.isEmpty ? const [DevelopmentalDomain.problemSolving] : out;
  }

  static DevelopmentalDomain _literacy(String skillId) {
    final area = skillId.split('.').last;
    if (const {'syllables', 'rhyme', 'first-sounds'}.contains(area)) return DevelopmentalDomain.auditory;
    if (const {'listening', 'vocabulary'}.contains(area)) return DevelopmentalDomain.language;
    return DevelopmentalDomain.earlyLiteracy;
  }
}

/// Owns every rule about where a child is in the journey and what comes
/// next. The UI and the games only consume its output.
///
/// - The child's age picks the stage they START at; it is never changed
///   by progress.
/// - A stage is complete when all its required activities are complete.
///   The current stage is the first incomplete one from the starting point.
/// - Later stages open one at a time as earlier ones complete; records are
///   never removed, so a change of age re-positions the child without
///   losing anything they did.
/// - Age is only a starting point. The engine is deterministic and works
///   from records, so performance-based adaptation can be added here later.
class CurriculumEngine {
  const CurriculumEngine(this.curriculum);
  final Curriculum curriculum;

  /// The first stage a child of [age] starts at.
  int entryIndexFor(int age) {
    final stages = curriculum.stages;
    for (final s in stages) {
      if (s.startsAtAge(age)) return s.index;
    }
    // Younger than any stage: the very beginning. Older: the first stage of
    // the oldest age group.
    if (stages.isEmpty || age < stages.first.ageRange.first) return 0;
    final oldest = stages.map((s) => s.ageRange.first).reduce((a, b) => a > b ? a : b);
    return stages.firstWhere((s) => s.ageRange.first == oldest).index;
  }

  JourneyProgress evaluate(ChildProfile profile, Map<String, ActivityRecord> records, {ChildEvidence evidence = const ChildEvidence()}) {
    final stages = curriculum.stages;
    bool done(Activity a) => records[a.id]?.completed ?? false;
    bool stageDone(JourneyStage s) => s.required.every(done);

    final entry = entryIndexFor(profile.age);
    var current = -1;
    for (var i = entry; i < stages.length; i++) {
      if (!stageDone(stages[i])) {
        current = i;
        break;
      }
    }
    final finished = current < 0;
    if (finished) current = stages.isEmpty ? 0 : stages.length - 1;

    var firstVisible = entry;
    for (var i = 0; i < entry; i++) {
      if (stages[i].activities.any((a) => records.containsKey(a.id))) {
        firstVisible = i;
        break;
      }
    }

    final progress = <StageProgress>[];
    for (final s in stages) {
      final StageStatus status;
      if (s.index < entry) {
        status = stageDone(s) ? StageStatus.completed : StageStatus.earlier;
      } else if (s.index == current && !finished) {
        status = StageStatus.current;
      } else if (stageDone(s)) {
        status = StageStatus.completed;
      } else {
        status = StageStatus.locked;
      }
      final open = status != StageStatus.locked;
      progress.add(StageProgress(stage: s, status: status, activities: {
        for (final a in s.activities) a.id: _status(a, records, open: open),
      }));
    }

    final recommendation = stages.isEmpty ? null : _recommend(stages[current], progress[current], records, evidence, finished: finished);
    final recommended = recommendation?.activity;
    // A replay of something already done keeps its "done" mark.
    if (recommended != null && progress[current].activities[recommended.id] == ActivityStatus.available) {
      progress[current].activities[recommended.id] = ActivityStatus.recommended;
    }

    return JourneyProgress(
      profile: profile,
      stages: progress,
      entryIndex: entry,
      currentIndex: current,
      firstVisibleIndex: firstVisible,
      recommendation: recommendation,
      domains: _domainProgress(stages.sublist(firstVisible, stages.isEmpty ? 0 : current + 1), records),
      finished: finished,
    );
  }

  ActivityStatus _status(Activity a, Map<String, ActivityRecord> records, {required bool open}) {
    final r = records[a.id];
    if (r != null && r.completed) return r.completions >= 2 && r.bestStars >= 3 ? ActivityStatus.mastered : ActivityStatus.completed;
    if (!open) return ActivityStatus.locked;
    final waiting = a.prerequisites.any((p) => !(records[p]?.completed ?? false));
    return waiting ? ActivityStatus.locked : ActivityStatus.available;
  }

  static const _rolePriority = [LevelRole.required, LevelRole.practice, LevelRole.challenge, LevelRole.optional, LevelRole.review];

  /// How many times the engine suggests going back to the same activity
  /// after a hard session before moving on (the Adaptive Engine has eased
  /// the game each time; the journey should not loop on one game).
  static const maxRetries = 3;

  /// The next activity, from curriculum eligibility plus the child's
  /// evidence. Performance never opens anything the curriculum keeps
  /// locked: every candidate is an activity of the current stage the child
  /// may start.
  ///
  /// 1. After a hard session (the Adaptive Engine eased the game): an open
  ///    practice or review activity in the same area; otherwise the same
  ///    activity again, now easier and with more help.
  /// 2. After an accurate, independent session: an open challenge.
  /// 3. Otherwise: required first, then practice, challenge, optional and
  ///    review -- avoiding the area just played, favouring skills without
  ///    secure mastery evidence, then the area done least.
  /// 4. With everything done: replay the activity with the fewest stars.
  Recommendation? _recommend(JourneyStage stage, StageProgress progress, Map<String, ActivityRecord> records, ChildEvidence evidence, {required bool finished}) {
    bool startable(Activity a) => progress.activities[a.id]!.canStart;
    final open = stage.activities.where((a) => progress.activities[a.id] == ActivityStatus.available).toList();

    ActivityRecord? last;
    final doneByDomain = <DevelopmentalDomain, int>{};
    for (final r in records.values) {
      final a = curriculum.activity(r.activityId);
      if (a == null) continue;
      if (r.completed) doneByDomain[a.domain] = (doneByDomain[a.domain] ?? 0) + 1;
      if (last == null || r.lastPlayedAt.isAfter(last.lastPlayedAt)) last = r;
    }
    final lastActivity = last == null ? null : curriculum.activity(last.activityId);
    final lastDomain = lastActivity?.domain;

    if (!finished && last != null && lastActivity != null && last.struggled) {
      final practice = stage.activities
          .where((a) => a.id != lastActivity.id && (a.role == LevelRole.practice || a.role == LevelRole.review) && a.domain == lastActivity.domain && startable(a))
          .toList()
        ..sort((a, b) => (records[a.id]?.completions ?? 0).compareTo(records[b.id]?.completions ?? 0));
      if (practice.isNotEmpty) return Recommendation(practice.first, RecommendationReason.practice);
      if (lastActivity.stageId == stage.id && startable(lastActivity) && last.attempts < maxRetries) {
        return Recommendation(lastActivity, RecommendationReason.tryAgainEasier);
      }
    }

    if (!finished && last != null && last.thrived) {
      final challenge = open.where((a) => a.role == LevelRole.challenge).toList();
      if (challenge.isNotEmpty) return Recommendation(challenge.first, RecommendationReason.stretch);
    }

    if (open.isEmpty || finished) {
      final replay = [...stage.activities]..sort((a, b) {
          final byStars = (records[a.id]?.bestStars ?? 0).compareTo(records[b.id]?.bestStars ?? 0);
          return byStars != 0 ? byStars : stage.activities.indexOf(a).compareTo(stage.activities.indexOf(b));
        });
      return replay.isEmpty ? null : Recommendation(replay.first, RecommendationReason.review);
    }

    for (final role in _rolePriority) {
      final group = open.where((a) => a.role == role).toList();
      if (group.isEmpty) continue;
      group.sort((a, b) {
        final repeatA = a.domain == lastDomain ? 1 : 0, repeatB = b.domain == lastDomain ? 1 : 0;
        if (repeatA != repeatB) return repeatA.compareTo(repeatB);
        final secureA = evidence.isSecure(a.skills) ? 1 : 0, secureB = evidence.isSecure(b.skills) ? 1 : 0;
        if (secureA != secureB) return secureA.compareTo(secureB);
        final countA = doneByDomain[a.domain] ?? 0, countB = doneByDomain[b.domain] ?? 0;
        if (countA != countB) return countA.compareTo(countB);
        return stage.activities.indexOf(a).compareTo(stage.activities.indexOf(b));
      });
      return Recommendation(group.first, role == LevelRole.required ? RecommendationReason.next : RecommendationReason.explore);
    }
    return null;
  }

  List<DomainProgress> _domainProgress(List<JourneyStage> stages, Map<String, ActivityRecord> records) {
    final done = <DevelopmentalDomain, int>{}, total = <DevelopmentalDomain, int>{};
    for (final s in stages) {
      for (final a in s.activities) {
        total[a.domain] = (total[a.domain] ?? 0) + 1;
        if (records[a.id]?.completed ?? false) done[a.domain] = (done[a.domain] ?? 0) + 1;
      }
    }
    return [
      for (final d in DevelopmentalDomain.values)
        if (total.containsKey(d)) DomainProgress(domain: d, done: done[d] ?? 0, total: total[d]!),
    ];
  }

  /// Whether a child may start [activityId] now. Locked activities (a
  /// stage not yet reached, or unfinished prerequisites) cannot be started.
  bool canStart(JourneyProgress progress, String activityId) => progress.statusOf(activityId).canStart;
}

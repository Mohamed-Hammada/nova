import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/skills/skill_evidence.dart';
import 'package:nova_app/core/skills/skill_graph.dart';
import 'package:nova_app/core/skills/skill_profile.dart';

import 'journey_models.dart';

/// Why the engine picked an activity -- internal, for grown-ups' reports,
/// tests and debugging. The child only ever sees a friendly message.
enum SelectionReason {
  /// The next required activity of the adventure.
  nextRequired('next_required'),

  /// A skill (or a prerequisite under it) the evidence says needs practice.
  practiceMissingSkill('practice_missing_skill'),

  /// The same kind of mistake keeps coming back.
  addressRepeatedError('address_repeated_error'),

  /// Accurate, but still leaning on help: practise it with less.
  buildIndependence('build_independence'),

  /// A secure skill not practised for a while.
  reinforceSecureSkill('reinforce_secure_skill'),

  /// A secure skill, checked in a new mechanic.
  transferProbe('transfer_probe'),

  /// A challenge after accurate, independent play.
  stretch('stretch'),

  /// The same activity again, now easier (the Adaptive Engine eased it).
  tryAgainEasier('try_again_easier'),

  /// Something different, for a varied journey.
  variety('variety'),

  /// Everything is done: an earlier activity again.
  review('review');

  const SelectionReason(this.code);
  final String code;
}

/// One reason, for or against, and how much it weighed.
class ScoreFactor {
  const ScoreFactor(this.name, this.points, {this.reason});
  final String name;
  final double points;

  /// The selection reason this factor argues for, when it is one.
  final SelectionReason? reason;

  @override
  String toString() => '$name ${points >= 0 ? '+' : ''}${points.toStringAsFixed(0)}';
}

/// An activity the engine considered, with its score and every factor
/// behind it.
class RecommendationCandidate {
  const RecommendationCandidate({required this.activity, required this.factors, required this.reason});
  final Activity activity;
  final List<ScoreFactor> factors;
  final SelectionReason reason;

  double get score => factors.fold<double>(0, (a, f) => a + f.points);

  /// A one-line explanation, e.g. "address_repeated_error (score 112: fresh
  /// +30, required +50, ...)".
  String explain() => '${reason.code} (score ${score.toStringAsFixed(0)}: ${factors.join(', ')})';

  @override
  String toString() => '${activity.id}: ${explain()}';
}

/// Everything the engine weighs for one recommendation.
class RecommendationInput {
  const RecommendationInput({
    required this.stage,
    required this.progress,
    required this.records,
    required this.evidence,
    required this.age,
    required this.finished,
    required this.activity,
    this.language,
  });

  /// The adventure the child is on: candidates never come from anywhere
  /// else.
  final JourneyStage stage;
  final StageProgress progress;
  final Map<String, ActivityRecord> records;
  final ChildEvidence evidence;
  final int age;
  final bool finished;

  /// The language the child plays in; null: any.
  final String? language;

  /// Looks up any activity of the curriculum.
  final Activity? Function(String id) activity;
}

/// Scores candidate activities and picks the next one.
///
/// Hard rules first -- a candidate must be in the child's current adventure,
/// startable (not locked by the stage or its prerequisites, and allowed for
/// the child's age) and playable in their language. Performance never opens
/// anything.
///
/// Then every candidate gets points for: its role and whether it is new;
/// the need of the skills it trains (Skill Profiles); the skill graph
/// (reinforcing prerequisites of skills that are hard); how the last
/// session went (struggle -> practice or try again easier; thriving -> a
/// challenge); repeated errors; independence; transfer (a secure skill in a
/// new mechanic); and it loses points for repetition -- the same activity,
/// game, mechanic, domain or skill as just played, or a skill played in
/// every recent session -- unless the evidence is the reason to repeat.
///
/// Deterministic and explainable: each candidate carries its factors
/// (RecommendationCandidate.explain). Weights are provisional.
class RecommendationEngine {
  const RecommendationEngine({this.graph, this.maxRetries = 3});
  final SkillGraph? graph;

  /// Times the same activity is suggested again after hard sessions before
  /// the journey moves on.
  final int maxRetries;

  static const _roleWeight = {
    LevelRole.required: 50.0,
    LevelRole.practice: 20.0,
    LevelRole.challenge: 12.0,
    LevelRole.optional: 10.0,
    LevelRole.review: 8.0,
  };

  Recommendation? recommend(RecommendationInput input) {
    final ranked = rank(input);
    if (ranked.isEmpty) return null;
    final best = ranked.first;
    return Recommendation(best.activity, childReason(best, input.progress), why: best, candidates: ranked);
  }

  /// The child-facing reason for a pick.
  static RecommendationReason childReason(RecommendationCandidate c, StageProgress progress) {
    final done = progress.activities[c.activity.id]?.isDone ?? false;
    return switch (c.reason) {
      SelectionReason.nextRequired => RecommendationReason.next,
      SelectionReason.practiceMissingSkill || SelectionReason.addressRepeatedError || SelectionReason.buildIndependence => RecommendationReason.practice,
      SelectionReason.tryAgainEasier => RecommendationReason.tryAgainEasier,
      SelectionReason.stretch => RecommendationReason.stretch,
      SelectionReason.transferProbe => RecommendationReason.newWay,
      SelectionReason.review => RecommendationReason.review,
      SelectionReason.reinforceSecureSkill || SelectionReason.variety => done ? RecommendationReason.review : RecommendationReason.explore,
    };
  }

  /// Every eligible candidate, best first.
  List<RecommendationCandidate> rank(RecommendationInput input) {
    final stage = input.stage;
    final statuses = input.progress.activities;
    final records = input.records;
    final profiles = input.evidence.profiles;
    final history = input.evidence.history.isNotEmpty ? input.evidence.history : _historyFromRecords(records, input);

    bool eligible(Activity a) {
      final status = statuses[a.id];
      if (status == null || !status.canStart) return false;
      if (input.language != null && !a.supportsLanguage(input.language!)) return false;
      return true;
    }

    final pool = stage.activities.where(eligible).toList();
    if (pool.isEmpty) return const [];

    // The last session, and the few before it.
    final last = history.isEmpty ? null : history.first;
    final lastActivity = last?.activityId == null ? null : input.activity(last!.activityId!);
    final lastRecord = lastActivity == null ? null : records[lastActivity.id];
    final recentIds = {for (final s in history.skip(1).take(2)) ?s.activityId};
    final struggled = !input.finished && lastRecord != null && lastRecord.struggled;
    final thrived = !input.finished && lastRecord != null && lastRecord.thrived;

    final doneByDomain = <DevelopmentalDomain, int>{};
    for (final r in records.values) {
      final a = input.activity(r.activityId);
      if (a != null && r.completed) doneByDomain[a.domain] = (doneByDomain[a.domain] ?? 0) + 1;
    }
    final now = history.isEmpty ? null : history.first.at;

    // Skills under the ones the child finds hard: prerequisites worth
    // reinforcing (from the skill graph).
    final g = graph;
    final reinforce = <String>{};
    if (g != null) {
      for (final p in profiles.values) {
        if (p.hasEvidence && p.needsPractice) reinforce.addAll(g.reinforcementFor(p.skillId, profiles));
      }
    }

    final out = <RecommendationCandidate>[];
    for (final (index, a) in pool.indexed) {
      final f = <ScoreFactor>[];
      final done = statuses[a.id]!.isDone;
      final skills = a.skillsFor(input.language);
      final skillProfiles = [for (final s in skills) profiles[s] ?? SkillProfile(skillId: s)];

      f.add(done ? const ScoreFactor('already_done', -25) : const ScoreFactor('fresh', 30));
      f.add(ScoreFactor('role_${a.role.name}', _roleWeight[a.role]!));
      if (a.suitsAge(input.age)) f.add(const ScoreFactor('age_fit', 5));

      // Skill need, from the neediest skill it trains (evidence of need
      // counts more than no evidence yet).
      ScoreFactor? need;
      for (final p in skillProfiles) {
        final ScoreFactor factor = switch (p.state) {
          SkillState.notYet || SkillState.emerging when p.hasEvidence => const ScoreFactor('skill_needs_practice', 20, reason: SelectionReason.practiceMissingSkill),
          SkillState.notYet || SkillState.emerging => const ScoreFactor('skill_new', 15),
          SkillState.developing => p.trend == Trend.declining
              ? const ScoreFactor('skill_slipping', 18, reason: SelectionReason.practiceMissingSkill)
              : const ScoreFactor('skill_developing', 8),
          SkillState.secure => const ScoreFactor('skill_secure', -10),
          SkillState.transfer => const ScoreFactor('skill_transferred', -20),
        };
        if (need == null || factor.points > need.points) need = factor;
      }
      if (need != null) f.add(need);

      // The skill graph: never build on a prerequisite the child finds hard;
      // do reinforce prerequisites under a skill that is hard.
      if (g != null) {
        final shaky = skills.expand((s) => g.weakPrerequisites(s, profiles)).toSet()..removeAll(skills);
        if (shaky.isNotEmpty) f.add(const ScoreFactor('prerequisite_not_ready', -20));
      }
      final reinforcing = g != null && skills.any(reinforce.contains);
      if (reinforcing) f.add(const ScoreFactor('reinforce_prerequisite', 20, reason: SelectionReason.practiceMissingSkill));

      // How the last session went.
      var tryAgain = false, strugglePractice = false;
      if (struggled && lastActivity != null) {
        if (a.id != lastActivity.id && (a.role == LevelRole.practice || a.role == LevelRole.review) && a.domain == lastActivity.domain) {
          strugglePractice = true;
          final sharesSkill = skills.any(lastActivity.skillsFor(input.language).contains);
          f.add(ScoreFactor('practice_after_hard_session', sharesSkill ? 140 : 130, reason: SelectionReason.practiceMissingSkill));
        } else if (a.id == lastActivity.id && lastActivity.stageId == stage.id && lastRecord.attempts < maxRetries) {
          tryAgain = true;
          f.add(const ScoreFactor('try_again_easier', 85, reason: SelectionReason.tryAgainEasier));
        }
      }
      if (thrived && a.role == LevelRole.challenge && !done) f.add(const ScoreFactor('challenge_after_strong_play', 90, reason: SelectionReason.stretch));

      // Evidence-driven reasons, per skill.
      var learningReason = strugglePractice || tryAgain || reinforcing;
      for (final p in skillProfiles) {
        if (p.repeatedErrors.isNotEmpty) {
          learningReason = true;
          f.add(ScoreFactor('repeated_${p.repeatedErrors.first}', a.id == lastActivity?.id ? 55 : 70, reason: SelectionReason.addressRepeatedError));
        }
        if (p.needsIndependence) {
          learningReason = true;
          f.add(const ScoreFactor('needs_independence', 25, reason: SelectionReason.buildIndependence));
        }
        if (p.readyForTransfer && p.secureMechanics.isNotEmpty && a.mechanics.isNotEmpty && a.mechanics.every((m) => !p.secureMechanics.contains(m))) {
          learningReason = true;
          f.add(const ScoreFactor('transfer_check', 40, reason: SelectionReason.transferProbe));
        } else if (p.hasEvidence && !p.contexts.contains(_contextKey(a, input.language))) {
          f.add(const ScoreFactor('new_context', 6));
        }
        if (p.state >= SkillState.secure && now != null && p.lastPracticed != null && now.difference(p.lastPracticed!).inDays >= 7 && (done || a.role == LevelRole.review)) {
          f.add(const ScoreFactor('reinforce_secure', 15, reason: SelectionReason.reinforceSecureSkill));
        }
      }

      // Variety: do not grind. Repetition costs points; when the evidence is
      // the reason to stay with a skill it costs half, and a different game
      // for the same skill is preferred (game A -> game B, same skill).
      if (last != null && !tryAgain) {
        final k = learningReason ? 0.5 : 1.0;
        final sameGame = a.gameFor(input.language ?? 'en') == last.gameId;
        if (a.id == last.activityId) f.add(const ScoreFactor('just_played', -40));
        if (sameGame) f.add(ScoreFactor('same_game', -20 * k));
        if (a.mechanics.contains(last.mechanicId)) f.add(ScoreFactor('same_mechanic', -8 * k));
        if (!strugglePractice && lastActivity != null && a.domain == lastActivity.domain) f.add(ScoreFactor('same_domain', -15 * k));
        if (!learningReason && skills.any(last.skills.contains)) f.add(const ScoreFactor('same_skill', -10));
        if (learningReason && !sameGame && skills.any(last.skills.contains)) f.add(const ScoreFactor('same_skill_new_game', 10));
      }
      if (recentIds.contains(a.id)) f.add(const ScoreFactor('played_recently', -15));
      // A skill in every recent session needs a break -- after three in a
      // row, or four when the evidence asks for more of it.
      if (skillProfiles.any((p) => p.recentRun >= (learningReason ? 4 : 3))) f.add(const ScoreFactor('skill_fatigue', -30));
      final domainDone = doneByDomain[a.domain] ?? 0;
      if (domainDone > 0) f.add(ScoreFactor('domain_done_$domainDone', -1.5 * domainDone));
      if (done && !tryAgain) {
        final stars = records[a.id]?.bestStars ?? 0;
        if (stars > 0) f.add(ScoreFactor('stars_$stars', -4.0 * stars));
      }
      f.add(ScoreFactor('order', -0.01 * index));

      out.add(RecommendationCandidate(activity: a, factors: f, reason: _reason(f, a, done: done)));
    }
    out.sort((x, y) => y.score.compareTo(x.score));
    return out;
  }

  static SelectionReason _reason(List<ScoreFactor> factors, Activity a, {required bool done}) {
    ScoreFactor? best;
    for (final f in factors) {
      if (f.reason != null && f.points > 0 && (best == null || f.points > best.points)) best = f;
    }
    if (best != null) return best.reason!;
    if (done) return SelectionReason.review;
    return a.isRequired ? SelectionReason.nextRequired : SelectionReason.variety;
  }

  static String _contextKey(Activity a, String? language) {
    final game = a.gameFor(language ?? 'en');
    final skin = a.level.skin;
    return skin == null || skin.isEmpty ? game : '$game#$skin';
  }

  /// Without a session log (older data, tests), the activity records give
  /// the order in which activities were last played.
  static List<PlayedSession> _historyFromRecords(Map<String, ActivityRecord> records, RecommendationInput input) {
    final sorted = [...records.values]..sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    return [
      for (final r in sorted)
        if (input.activity(r.activityId) case final a?)
          PlayedSession(
            at: r.lastPlayedAt,
            activityId: a.id,
            gameId: a.gameFor(input.language ?? 'en'),
            mechanicId: a.mechanics.isEmpty ? '' : a.mechanics.first,
            skills: a.skillsFor(input.language),
          ),
    ];
  }
}

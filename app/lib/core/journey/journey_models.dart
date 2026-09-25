import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/content/models.dart';

/// The child using Nova. [age] is the child's real, chronological age: it
/// is only ever changed by a grown-up, never by progress. Where the child
/// is in the journey is a separate thing (see CurriculumEngine).
class ChildProfile {
  const ChildProfile({required this.id, required this.name, required this.age});
  final String id;
  final String name;
  final int age;

  ChildProfile withAge(int newAge) => ChildProfile(id: id, name: name, age: newAge);
}

/// The developmental areas a journey balances. A presentation-level
/// grouping of the spec's skill domains, used to vary recommendations and
/// to show grown-ups coverage -- never to grade a child.
enum DevelopmentalDomain {
  socialEmotional,
  language,
  earlyLiteracy,
  auditory,
  numeracy,
  memory,
  attention,
  problemSolving,
}

/// How an activity is judged finished. Every activity is a session of
/// rounds; it is complete once all rounds are played and at least
/// [minStars] stars are earned. (Stars are an engagement reward only; a
/// completed activity is not evidence of mastery -- mastery comes from the
/// assessment pipeline over many sessions.)
class CompletionCriteria {
  const CompletionCriteria({this.minStars = 1});
  final int minStars;

  bool isMet({required bool finishedAllRounds, required int stars}) => finishedAllRounds && stars >= minStars;
}

/// One activity in the curriculum: a journey level resolved against the
/// content bundle, with everything the engine and the UI need to know
/// about it. The game it plays receives only this configuration; no game
/// holds age rules of its own.
class Activity {
  const Activity({
    required this.id,
    required this.stageId,
    required this.level,
    required this.role,
    required this.prerequisites,
    required this.minAge,
    required this.maxAge,
    required this.domains,
    required this.skills,
    required this.languages,
    required this.minutes,
    this.completion = const CompletionCriteria(),
  });

  /// The journey level id; the same whatever language the child plays in.
  final String id;
  final String stageId;
  final JourneyLevel level;
  final LevelRole role;
  final List<String> prerequisites;
  final int minAge;
  final int maxAge;

  /// The first domain is the activity's main one.
  final List<DevelopmentalDomain> domains;
  final List<String> skills;

  /// Languages it can be played in (empty: any).
  final Set<String> languages;
  final double minutes;
  final CompletionCriteria completion;

  DevelopmentalDomain get domain => domains.first;
  bool get isRequired => role == LevelRole.required;

  /// The game played for a child using [language].
  String gameFor(String language) => level.gameFor(language);
}

/// One adventure of the continuous journey.
class JourneyStage {
  const JourneyStage({required this.id, required this.nameKey, required this.place, required this.ageRange, required this.index, required this.activities});
  final String id;
  final String nameKey;
  final String place;
  final List<int> ageRange;

  /// Position in the whole journey, from 0.
  final int index;
  final List<Activity> activities;

  Iterable<Activity> get required => activities.where((a) => a.isRequired);
  bool startsAtAge(int age) => ageRange.first <= age && age <= ageRange.last;
}

/// What the device remembers about one activity for one child. Records
/// are only ever added to or updated -- never deleted -- so history
/// survives age changes and journey progress.
class ActivityRecord {
  const ActivityRecord({
    required this.childId,
    required this.activityId,
    required this.firstStartedAt,
    required this.lastPlayedAt,
    this.firstCompletedAt,
    this.attempts = 0,
    this.completions = 0,
    this.bestStars = 0,
    this.lastAccuracy,
    this.lastHintsPerTrial,
    this.lastMove,
    this.lastScaffold,
  });

  final String childId;
  final String activityId;
  final DateTime firstStartedAt;
  final DateTime lastPlayedAt;
  final DateTime? firstCompletedAt;

  /// Times the activity was started.
  final int attempts;

  /// Times it was finished.
  final int completions;
  final int bestStars;
  final double? lastAccuracy;

  /// From the last session's assessment and adaptive decision: hints per
  /// round, and whether the Adaptive Engine moved the game up, kept it, or
  /// moved it down (with the scaffold it chose). This is session evidence,
  /// not mastery.
  final double? lastHintsPerTrial;
  final AdaptiveMove? lastMove;
  final String? lastScaffold;

  bool get completed => completions > 0;

  /// The last session showed struggle (the Adaptive Engine eased off).
  bool get struggled => lastMove == AdaptiveMove.retreat;

  /// The last session was accurate and independent enough to move up.
  bool get thrived => lastMove == AdaptiveMove.advance || lastScaffold == ScaffoldLevel.independent;

  ActivityRecord started(DateTime at) => ActivityRecord(
        childId: childId,
        activityId: activityId,
        firstStartedAt: firstStartedAt,
        lastPlayedAt: at,
        firstCompletedAt: firstCompletedAt,
        attempts: attempts + 1,
        completions: completions,
        bestStars: bestStars,
        lastAccuracy: lastAccuracy,
        lastHintsPerTrial: lastHintsPerTrial,
        lastMove: lastMove,
        lastScaffold: lastScaffold,
      );

  ActivityRecord finished(DateTime at, {required bool completed, required int stars, required double accuracy, SessionOutcome? outcome}) => ActivityRecord(
        childId: childId,
        activityId: activityId,
        firstStartedAt: firstStartedAt,
        lastPlayedAt: at,
        firstCompletedAt: firstCompletedAt ?? (completed ? at : null),
        attempts: attempts,
        completions: completions + (completed ? 1 : 0),
        bestStars: stars > bestStars ? stars : bestStars,
        lastAccuracy: accuracy,
        lastHintsPerTrial: outcome?.hintsPerTrial ?? lastHintsPerTrial,
        lastMove: outcome?.move ?? lastMove,
        lastScaffold: outcome?.scaffold ?? lastScaffold,
      );

  static ActivityRecord fresh(String childId, String activityId, DateTime at) =>
      ActivityRecord(childId: childId, activityId: activityId, firstStartedAt: at, lastPlayedAt: at);
}

/// What a finished game session reports to the journey: the child's
/// result, and the Adaptive Engine's decision computed from the session's
/// learning signals (GameRuntime.completeSession).
class SessionOutcome {
  const SessionOutcome({required this.stars, required this.accuracy, this.hintsPerTrial, this.move, this.scaffold, this.finishedAllRounds = true});
  final int stars;

  /// First-try accuracy, 0..1.
  final double accuracy;
  final double? hintsPerTrial;

  /// The Adaptive Engine's decision for the next session of this game.
  final AdaptiveMove? move;
  final String? scaffold;
  final bool finishedAllRounds;
}

/// Where an activity stands for this child.
enum ActivityStatus {
  /// Its stage is not open yet, or its prerequisites are unfinished.
  locked,
  available,

  /// The one to do next.
  recommended,
  completed,

  /// Finished at least twice with every star. This describes the activity
  /// ("played brilliantly"), not the child's skill mastery.
  mastered;

  bool get isDone => this == completed || this == mastered;
  bool get canStart => this != locked;
}

enum StageStatus {
  /// Before the child's starting point and never played: part of the world,
  /// open to explore, not required.
  earlier,
  completed,
  current,
  locked,
}

class StageProgress {
  const StageProgress({required this.stage, required this.status, required this.activities});
  final JourneyStage stage;
  final StageStatus status;
  final Map<String, ActivityStatus> activities;

  int get requiredDone => stage.required.where((a) => activities[a.id]!.isDone).length;
  int get requiredTotal => stage.required.length;
  int get done => activities.values.where((s) => s.isDone).length;
}

/// A domain's share of the journey so far, for grown-ups.
class DomainProgress {
  const DomainProgress({required this.domain, required this.done, required this.total});
  final DevelopmentalDomain domain;
  final int done;
  final int total;
  double get fraction => total == 0 ? 0 : done / total;
}

/// Everything the UI needs about a child's journey, computed by the
/// curriculum engine from the profile and the activity records.
class JourneyProgress {
  const JourneyProgress({
    required this.profile,
    required this.stages,
    required this.entryIndex,
    required this.currentIndex,
    required this.firstVisibleIndex,
    required this.recommended,
    required this.domains,
    required this.finished,
  });

  final ChildProfile profile;

  /// Every stage of the whole journey, in order.
  final List<StageProgress> stages;

  /// Where a child of this age starts.
  final int entryIndex;

  /// The adventure the child is on now.
  final int currentIndex;

  /// The first stage worth showing: the starting point, or earlier if the
  /// child has history there (history never disappears).
  final int firstVisibleIndex;
  final Activity? recommended;
  final List<DomainProgress> domains;

  /// Every stage from the starting point on is complete.
  final bool finished;

  StageProgress get current => stages[currentIndex];
  List<StageProgress> get visible => stages.sublist(firstVisibleIndex);

  ActivityStatus statusOf(String activityId) {
    for (final s in stages) {
      final status = s.activities[activityId];
      if (status != null) return status;
    }
    return ActivityStatus.locked;
  }
}

/// The five mastery states, in order. Stored as the strings the Mastery
/// Engine already uses (null = "Not yet").
enum SkillState {
  notYet(null),
  emerging('emerging'),
  developing('developing'),
  secure('secure'),
  transfer('transfer');

  const SkillState(this.key);
  final String? key;

  static SkillState parse(String? key) => values.firstWhere((s) => s.key == key, orElse: () => notYet);

  bool operator >=(SkillState other) => index >= other.index;
  bool operator <(SkillState other) => index < other.index;
}

/// Which way recent sessions are going.
enum Trend { improving, steady, declining, unknown }

/// How much help the child needs, from hints and grown-up help per round.
enum Independence { independent, occasionalHelp, needsHelp, unknown }

/// How alike the child's sessions are (a wobbly profile deserves less trust).
enum Consistency { strong, moderate, weak, unknown }

/// Everything Nova knows about one child and one skill, accumulated across
/// sessions (SkillProfileBuilder). Descriptive evidence -- never a score or
/// a rank -- that the recommendation engine and the grown-ups' report read.
class SkillProfile {
  const SkillProfile({
    required this.skillId,
    this.state = SkillState.notYet,
    this.confidence = 0,
    this.recentAccuracy,
    this.rollingAccuracy,
    this.independence = Independence.unknown,
    this.hintsPerTrial = 0,
    this.hintRequestsPerTrial = 0,
    this.adultAssistPerTrial = 0,
    this.consistency = Consistency.unknown,
    this.trend = Trend.unknown,
    this.attempts = 0,
    this.sessions = 0,
    this.errorCounts = const {},
    this.repeatedErrors = const [],
    this.selfCorrections = 0,
    this.contexts = const {},
    this.games = const {},
    this.mechanics = const {},
    this.secureMechanics = const {},
    this.transferEvidence = 0,
    this.lastPracticed,
    this.recentRun = 0,
    this.scaffold,
    this.rungId,
    this.rungIndex,
    this.rungCount,
  });

  /// A profile with nothing but a known state (evidence from an older
  /// record, or a test).
  factory SkillProfile.stateOnly(String skillId, String? state) => SkillProfile(skillId: skillId, state: SkillState.parse(state));

  final String skillId;
  final SkillState state;

  /// 0..1: how much the evidence behind [state] can be trusted (more rounds
  /// and steadier sessions, more trust). Provisional formula.
  final double confidence;

  /// The last session's first-try accuracy, and the accuracy over the recent
  /// window of sessions the state is judged on.
  final double? recentAccuracy;
  final double? rollingAccuracy;
  final Independence independence;
  final double hintsPerTrial;
  final double hintRequestsPerTrial;
  final double adultAssistPerTrial;
  final Consistency consistency;
  final Trend trend;

  /// First-try rounds answered, over all sessions.
  final int attempts;

  /// Sessions played (the repetition count).
  final int sessions;

  /// Mistake types over the recent window, and those that keep coming back.
  final Map<String, int> errorCounts;
  final List<String> repeatedErrors;
  final int selfCorrections;

  /// Where the skill was practised: game+skin contexts, games, mechanics.
  final Set<String> contexts;
  final Set<String> games;
  final Set<String> mechanics;

  /// Mechanics the skill was secure in; transfer needs another one.
  final Set<String> secureMechanics;

  /// Passed transfer checks: an in-app session in a new mechanic, or a
  /// grown-up's report of a probe task.
  final int transferEvidence;
  final DateTime? lastPracticed;

  /// How many of the child's most recent sessions in a row exercised this
  /// skill (fatigue / grinding guard).
  final int recentRun;

  /// The adaptive scaffold and rung last chosen for the skill's game.
  final String? scaffold;
  final String? rungId;
  final int? rungIndex;
  final int? rungCount;

  bool get hasEvidence => sessions > 0;

  /// Needs more practice: little or no evidence yet, early state, or going
  /// the wrong way.
  bool get needsPractice => state < SkillState.developing || trend == Trend.declining;

  /// Accurate, but still leaning on help.
  bool get needsIndependence =>
      (rollingAccuracy ?? 0) >= 0.75 && (independence == Independence.occasionalHelp || independence == Independence.needsHelp);

  /// Secure and ready to be checked somewhere new.
  bool get readyForTransfer => state == SkillState.secure;
}

/// One session's evidence about one skill, as GameRuntime observed it: the
/// raw material the Skill Profile is accumulated from. Evidence is only
/// ever added -- a session never rewrites an earlier one -- so the profile
/// can always be rebuilt from history.
class SkillEvidence {
  const SkillEvidence({
    required this.childId,
    required this.skillId,
    required this.sessionId,
    required this.at,
    required this.gameId,
    required this.mechanicId,
    this.activityId,
    this.context,
    this.rungId,
    this.scaffold,
    required this.trials,
    required this.correct,
    this.hints = 0,
    this.hintRequests = 0,
    this.adultAssists = 0,
    this.retries = 0,
    this.selfCorrections = 0,
    this.errors = const {},
  });

  final String childId;
  final String skillId;
  final String sessionId;
  final DateTime at;
  final String gameId;
  final String mechanicId;

  /// The journey activity it was played as, when there was one.
  final String? activityId;

  /// The setting the skill was practised in: the game plus its picture skin
  /// (apples, shells...). A new context is not a new mechanic: reskins never
  /// count as transfer.
  final String? context;
  final String? rungId;
  final String? scaffold;

  /// First-try responses, and how many of them were right.
  final int trials;
  final int correct;

  /// All help received (asked for, or given by the scaffold), of which
  /// [hintRequests] the child asked for.
  final int hints;
  final int hintRequests;
  final int adultAssists;
  final int retries;
  final int selfCorrections;

  /// How often each mechanic-specific error was reported (ErrorType).
  final Map<String, int> errors;

  double get accuracy => trials == 0 ? 0 : correct / trials;
  double get hintsPerTrial => trials == 0 ? 0 : hints / trials;
  double get adultAssistPerTrial => trials == 0 ? 0 : adultAssists / trials;

  /// Where the skill was practised: game and skin.
  String get contextKey => context == null || context!.isEmpty ? gameId : '$gameId#$context';
}

/// One played session, for variety and recency: which activity, game and
/// mechanic, and which skills it exercised. Newest first in a history.
class PlayedSession {
  const PlayedSession({required this.at, required this.gameId, required this.mechanicId, required this.skills, this.activityId});
  final DateTime at;
  final String? activityId;
  final String gameId;
  final String mechanicId;
  final List<String> skills;

  /// Sessions from the evidence log, one per session id, newest first.
  static List<PlayedSession> fromEvidence(Iterable<SkillEvidence> evidence) {
    final bySession = <String, List<SkillEvidence>>{};
    for (final e in evidence) {
      bySession.putIfAbsent(e.sessionId, () => []).add(e);
    }
    final out = [
      for (final group in bySession.values)
        PlayedSession(
          at: group.first.at,
          activityId: group.first.activityId,
          gameId: group.first.gameId,
          mechanicId: group.first.mechanicId,
          skills: [for (final e in group) e.skillId],
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return out;
  }
}

import 'dart:math' as math;

import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/content/criterion_parameters.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/mastery/mastery_engine.dart';

import 'error_types.dart';
import 'skill_evidence.dart';
import 'skill_profile.dart';

/// Builds a child's Skill Profile from the whole evidence history of one
/// skill. Deterministic and explainable -- every rule is written out below
/// -- and swappable: nothing outside reads how the profile was computed.
///
/// The mastery state is judged on a rolling window of recent sessions, not
/// on the last session alone, using the skill's own assessment rule and
/// thresholds (through the Mastery Engine, so the curriculum's criteria stay
/// the single source):
///
/// 1. Sessions are replayed in order. After each, the window (the last
///    [window] sessions) is pooled into one performance and one
///    independence estimate, and the Mastery Engine names the state that
///    evidence supports.
/// 2. Moving up happens as soon as the pooled evidence supports it.
/// 3. Moving down is slower, so one bad session never erases what the child
///    has shown: the state only drops when the last two sessions in a row
///    both fall below the current state's own accuracy threshold, and then
///    by one step at a time.
/// 4. Transfer needs Secure plus a pass somewhere new: a session in a
///    mechanic the skill was not yet secure in, at the rule's transfer pass
///    mark and without leaning on hints -- or a grown-up's report of a
///    passed probe task. A new picture skin in the same mechanic never
///    counts. High accuracy alone is never Transfer.
class SkillProfileBuilder {
  const SkillProfileBuilder({this.window = 5, MasteryEngine mastery = const MasteryEngine()}) : _mastery = mastery;

  /// How many recent sessions the state, rolling accuracy, independence,
  /// consistency and error patterns are judged on.
  final int window;
  final MasteryEngine _mastery;

  SkillProfile build({
    required String skillId,
    required List<SkillEvidence> evidence,
    required AssessmentRule rule,
    required Map<String, Parameter> parameters,
    DimensionEstimate? probe,
    List<PlayedSession> history = const [],
    String? scaffold,
    String? rungId,
    List<String> rungIds = const [],
  }) {
    final sessions = [...evidence.where((e) => e.skillId == skillId && e.trials > 0)]..sort((a, b) => a.at.compareTo(b.at));
    final recentRun = _recentRun(skillId, history);
    final rungIndex = rungId == null ? null : rungIds.indexOf(rungId);
    if (sessions.isEmpty) {
      // A grown-up may still have reported a probe; without in-app evidence
      // it cannot make a state (Transfer needs Secure first).
      return SkillProfile(
        skillId: skillId,
        transferEvidence: (probe?.metrics['passed'] ?? 0) >= 1 ? 1 : 0,
        recentRun: recentRun,
        scaffold: scaffold,
        rungId: rungId,
        rungIndex: rungIndex == null || rungIndex < 0 ? null : rungIndex,
        rungCount: rungIds.isEmpty ? null : rungIds.length,
      );
    }

    final secureCriterion = rule.stateCriteria['secure'];
    final transferCriterion = rule.stateCriteria['transfer'];
    final passMark = (transferCriterion == null ? null : criterionParameter(transferCriterion, parameters, 'transfer-pass')) ?? 0.7;
    final maxHints = (secureCriterion == null ? null : criterionParameter(secureCriterion, parameters, 'hints-per-trial')) ?? 0.2;
    final maxAssist = (secureCriterion == null ? null : criterionParameter(secureCriterion, parameters, 'adult-assist-per-trial')) ?? 0.2;
    final probePassed = (probe?.metrics['passed'] ?? 0) >= 1;

    var state = SkillState.notYet;
    final secureMechanics = <String>{};
    var inAppTransfers = 0;

    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final win = sessions.sublist(math.max(0, i - window + 1), i + 1);

      // A pass in a mechanic the skill was not yet secure in.
      final newMechanic = secureMechanics.isNotEmpty && !secureMechanics.contains(s.mechanicId);
      if (newMechanic && s.accuracy >= passMark && s.hintsPerTrial <= maxHints && s.adultAssistPerTrial <= maxAssist) inAppTransfers++;
      final transferOk = probePassed || inAppTransfers > 0;

      final candidate = SkillState.parse(_mastery
          .recompute(
            childId: s.childId,
            skillId: skillId,
            performance: _performance(skillId, win),
            independence: _independence(skillId, win),
            transfer: transferOk ? DimensionEstimate(skillId: skillId, dimension: 'transfer', metrics: const {'passed': 1}, evidenceCount: 1, lastUpdated: s.at) : null,
            rule: rule,
            parameters: parameters,
            now: s.at,
          )
          .state);

      if (candidate >= state) {
        state = candidate;
      } else if (i >= 1) {
        final threshold = _accuracyThreshold(rule, parameters, state);
        final twoBelow = threshold != null && s.accuracy < threshold && sessions[i - 1].accuracy < threshold;
        if (twoBelow) state = SkillState.values[math.max(candidate.index, state.index - 1)];
      }
      if (state >= SkillState.secure && secureMechanics.isEmpty) {
        // The mechanics the skill first became secure in (the window's):
        // a transfer check has to be somewhere else.
        secureMechanics.addAll(win.map((w) => w.mechanicId));
      }
    }

    final win = sessions.sublist(math.max(0, sessions.length - window));
    final trials = win.fold<int>(0, (a, s) => a + s.trials);
    final correct = win.fold<int>(0, (a, s) => a + s.correct);
    final hints = win.fold<int>(0, (a, s) => a + s.hints);
    final requests = win.fold<int>(0, (a, s) => a + s.hintRequests);
    final assists = win.fold<int>(0, (a, s) => a + s.adultAssists);
    final hintsPerTrial = trials == 0 ? 0.0 : hints / trials;
    final assistPerTrial = trials == 0 ? 0.0 : assists / trials;

    final errorCounts = <String, int>{};
    final errorSessions = <String, int>{};
    for (final s in win) {
      for (final e in s.errors.entries) {
        if (!ErrorType.isMistake(e.key) || e.value <= 0) continue;
        errorCounts[e.key] = (errorCounts[e.key] ?? 0) + e.value;
        errorSessions[e.key] = (errorSessions[e.key] ?? 0) + 1;
      }
    }
    // A pattern, not a slip: at least three times, in two sessions when
    // there are two to compare -- and still happening in the last session
    // (once the child stops making it, it stops pulling the journey).
    final lastErrors = sessions.last.errors;
    final repeated = [
      for (final e in errorCounts.entries)
        if (e.value >= 3 && (errorSessions[e.key]! >= 2 || win.length == 1) && (lastErrors[e.key] ?? 0) > 0) e.key,
    ]..sort((a, b) => errorCounts[b]!.compareTo(errorCounts[a]!));

    final consistency = _consistency(win);
    final allTrials = sessions.fold<int>(0, (a, s) => a + s.trials);
    final consistencyWeight = switch (consistency) {
      Consistency.strong => 1.0,
      Consistency.moderate => 0.85,
      Consistency.weak => 0.7,
      Consistency.unknown => 0.8,
    };

    return SkillProfile(
      skillId: skillId,
      state: state,
      confidence: (allTrials / (allTrials + 10) * consistencyWeight).clamp(0.0, 1.0),
      recentAccuracy: sessions.last.accuracy,
      rollingAccuracy: trials == 0 ? null : correct / trials,
      independence: _independenceLevel(hintsPerTrial + assistPerTrial, maxHints.toDouble() + maxAssist.toDouble()),
      hintsPerTrial: hintsPerTrial,
      hintRequestsPerTrial: trials == 0 ? 0 : requests / trials,
      adultAssistPerTrial: assistPerTrial,
      consistency: consistency,
      trend: _trend(sessions),
      attempts: allTrials,
      sessions: sessions.length,
      errorCounts: errorCounts,
      repeatedErrors: repeated,
      selfCorrections: win.fold<int>(0, (a, s) => a + s.selfCorrections),
      contexts: {for (final s in sessions) s.contextKey},
      games: {for (final s in sessions) s.gameId},
      mechanics: {for (final s in sessions) s.mechanicId},
      secureMechanics: secureMechanics,
      transferEvidence: inAppTransfers + (probePassed ? 1 : 0),
      lastPracticed: sessions.last.at,
      recentRun: recentRun,
      scaffold: scaffold,
      rungId: rungId,
      rungIndex: rungIndex == null || rungIndex < 0 ? null : rungIndex,
      rungCount: rungIds.isEmpty ? null : rungIds.length,
    );
  }

  static DimensionEstimate _performance(String skillId, List<SkillEvidence> win) {
    final trials = win.fold<int>(0, (a, s) => a + s.trials);
    final correct = win.fold<int>(0, (a, s) => a + s.correct);
    return DimensionEstimate(
      skillId: skillId,
      dimension: 'performance',
      metrics: {'accuracy': trials == 0 ? 0 : correct / trials, 'trials': trials},
      evidenceCount: trials,
      lastUpdated: win.last.at,
    );
  }

  static DimensionEstimate _independence(String skillId, List<SkillEvidence> win) {
    final trials = win.fold<int>(0, (a, s) => a + s.trials);
    final safe = trials == 0 ? 1 : trials;
    return DimensionEstimate(
      skillId: skillId,
      dimension: 'independence',
      metrics: {
        'hintsPerTrial': win.fold<int>(0, (a, s) => a + s.hints) / safe,
        'adultAssistPerTrial': win.fold<int>(0, (a, s) => a + s.adultAssists) / safe,
      },
      evidenceCount: trials,
      lastUpdated: win.last.at,
    );
  }

  static num? _accuracyThreshold(AssessmentRule rule, Map<String, Parameter> parameters, SkillState state) {
    // Transfer is kept on Secure's accuracy.
    final key = state == SkillState.transfer ? 'secure' : state.key;
    final criterion = key == null ? null : rule.stateCriteria[key];
    return criterion == null ? null : criterionParameter(criterion, parameters, 'accuracy');
  }

  /// The last two sessions against the (up to three) before them.
  static Trend _trend(List<SkillEvidence> sessions) {
    if (sessions.length < 2) return Trend.unknown;
    double mean(Iterable<SkillEvidence> s) => s.fold<double>(0, (a, e) => a + e.accuracy) / s.length;
    final n = sessions.length;
    final recent = n == 2 ? [sessions[1]] : sessions.sublist(n - 2);
    final before = n == 2 ? [sessions[0]] : sessions.sublist(math.max(0, n - 5), n - 2);
    final diff = mean(recent) - mean(before);
    if (diff >= 0.1) return Trend.improving;
    if (diff <= -0.1) return Trend.declining;
    return Trend.steady;
  }

  static Consistency _consistency(List<SkillEvidence> win) {
    if (win.length < 2) return Consistency.unknown;
    final mean = win.fold<double>(0, (a, s) => a + s.accuracy) / win.length;
    final variance = win.fold<double>(0, (a, s) => a + (s.accuracy - mean) * (s.accuracy - mean)) / win.length;
    final sd = math.sqrt(variance);
    if (sd <= 0.1) return Consistency.strong;
    if (sd <= 0.2) return Consistency.moderate;
    return Consistency.weak;
  }

  /// Help per round against what the skill's Secure criterion allows.
  static Independence _independenceLevel(double helpPerTrial, double allowed) {
    if (helpPerTrial <= allowed) return Independence.independent;
    if (helpPerTrial <= allowed * 3) return Independence.occasionalHelp;
    return Independence.needsHelp;
  }

  /// How many of the most recent sessions in a row exercised [skillId].
  static int _recentRun(String skillId, List<PlayedSession> history) {
    var run = 0;
    for (final s in history) {
      if (!s.skills.contains(skillId)) break;
      run++;
    }
    return run;
  }
}

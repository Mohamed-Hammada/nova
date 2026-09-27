import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/adaptive/adaptive_model.dart';
import 'package:nova_app/core/adaptive/adaptive_progression_engine.dart';
import 'package:nova_app/core/assessment/assessment_engine.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/criterion_parameters.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/mastery/mastery_engine.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/core/ports/clock_port.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/core/signals/signal.dart';
import 'package:nova_app/core/signals/signal_bus.dart';
import 'package:nova_app/core/signals/signal_collector.dart';
import 'package:nova_app/core/skills/error_types.dart';
import 'package:nova_app/core/skills/skill_evidence.dart';
import 'package:nova_app/core/skills/skill_profile.dart';
import 'package:nova_app/core/skills/skill_profile_builder.dart';

import 'session_plan.dart';
import 'signal_mapping.dart';

/// The single orchestration point: content -> mechanic raw events ->
/// signals -> assessment -> mastery -> adaptive -> persistence (design doc
/// 2026-09-22, section 5). Nothing else in the domain core calls
/// PersistencePort directly (design doc section 4's component table).
class GameRuntime {
  GameRuntime({
    required ContentRuntime content,
    required SignalBus bus,
    required SignalCollector collector,
    required AssessmentEngine assessment,
    required MasteryEngine mastery,
    required AdaptiveProgressionEngine adaptive,
    required PersistencePort persistence,
    required ClockPort clock,
    SkillProfileBuilder profiles = const SkillProfileBuilder(),
  })  : _content = content,
        _profiles = profiles,
        _bus = bus,
        _collector = collector,
        _assessment = assessment,
        _mastery = mastery,
        _adaptive = adaptive,
        _persistence = persistence,
        _clock = clock;

  final ContentRuntime _content;
  // Held so other long-lived subscribers (e.g. a future engagement logger,
  // Plan 2) can listen independently; GameRuntime itself does not read
  // from it -- it captures collector.collect's typed return values below.
  // ignore: unused_field
  final SignalBus _bus;
  final SignalCollector _collector;
  final AssessmentEngine _assessment;
  final MasteryEngine _mastery;
  final AdaptiveProgressionEngine _adaptive;
  final PersistencePort _persistence;
  final ClockPort _clock;
  final SkillProfileBuilder _profiles;

  /// What the next session of [gameId] should be: the rung the Adaptive
  /// Engine last committed for this child (the first rung before any
  /// session), and enough trials for the skill's assessment rule to evaluate
  /// every state -- its `min-trials` parameter, read from content.
  Future<SessionPlan> planSession({required String childId, required String gameId, required String skillId}) async {
    final game = _content.game(gameId);
    final rungId = await _currentRungId(childId: childId, gameId: gameId);
    final trialCount = minTrialsFor(_content.assessmentRuleFor(skillId), _content.allParameters()) ?? 1;
    var scaffold = await _persistence.currentScaffold(childId: childId, gameId: gameId) ?? ScaffoldLevel.hintOnRequest;
    // The same mistake keeps coming back: the first round shows the way
    // again (guided), whatever the rung. The Adaptive Engine's rung stands.
    if (scaffold == ScaffoldLevel.hintOnRequest || scaffold == ScaffoldLevel.independent) {
      final profile = await skillProfile(childId: childId, skillId: skillId);
      if (profile.repeatedErrors.isNotEmpty && profile.recentAccuracy != null && profile.recentAccuracy! < 0.85) scaffold = ScaffoldLevel.guided;
    }
    return SessionPlan(childId: childId, game: game, skillId: skillId, rung: game.rungsById[rungId]!, trialCount: trialCount, scaffold: scaffold);
  }

  /// Read-only view of a skill's mastery for presentation (e.g. the grown-ups'
  /// progress screen), so no widget ever reaches PersistencePort itself.
  Future<MasteryRecord?> currentMastery({required String childId, required String skillId}) =>
      _persistence.currentMastery(childId: childId, skillId: skillId);

  /// The child's Skill Profile for [skillId]: every session's evidence,
  /// accumulated (SkillProfileBuilder), plus the rung and scaffold of the
  /// skill's main game and any grown-up-reported transfer probe.
  Future<SkillProfile> skillProfile({required String childId, required String skillId, List<PlayedSession>? history, List<SkillEvidence>? evidence}) async {
    evidence ??= await _persistence.skillEvidence(childId: childId, skillId: skillId);
    final probe = await _persistence.currentDimension(childId: childId, skillId: skillId, dimension: 'transfer');
    final games = _content.gamesForSkill(skillId);
    // The rung shown is the one of the game played last for the skill.
    final gameId = evidence.isNotEmpty ? evidence.last.gameId : (games.isEmpty ? null : games.first.id);
    final game = gameId != null && _content.hasGame(gameId) ? _content.game(gameId) : null;
    final rung = game == null ? null : await _persistence.currentRung(childId: childId, gameId: game.id);
    final scaffold = game == null ? null : await _persistence.currentScaffold(childId: childId, gameId: game.id);
    return _profiles.build(
      skillId: skillId,
      evidence: evidence,
      rule: _content.assessmentRuleFor(skillId),
      parameters: _content.allParameters(),
      probe: probe,
      history: history ?? const [],
      scaffold: scaffold,
      rungId: rung,
      rungIds: game?.rungIds ?? const [],
    );
  }

  /// Profiles for many skills at once, and the recent sessions (newest
  /// first) -- what the curriculum engine needs to recommend.
  Future<({Map<String, SkillProfile> profiles, List<PlayedSession> history})> childSkills({required String childId, required Iterable<String> skillIds}) async {
    // One read of the whole log, grouped by skill.
    final all = await _persistence.skillEvidence(childId: childId);
    final history = PlayedSession.fromEvidence(all);
    final bySkill = <String, List<SkillEvidence>>{};
    for (final e in all) {
      bySkill.putIfAbsent(e.skillId, () => []).add(e);
    }
    final profiles = <String, SkillProfile>{};
    for (final id in skillIds) {
      if (!_content.hasSkill(id)) continue;
      final profile = await skillProfile(childId: childId, skillId: id, history: history, evidence: bySkill[id] ?? const []);
      if (profile.hasEvidence || profile.transferEvidence > 0) {
        profiles[id] = profile;
      } else {
        // An older install may have a mastery record without evidence rows.
        final mastery = await _persistence.currentMastery(childId: childId, skillId: id);
        if (mastery != null) profiles[id] = SkillProfile.stateOnly(id, mastery.state);
      }
    }
    return (profiles: profiles, history: history);
  }

  /// A grown-up reports how a transfer probe task went (e.g. counting
  /// objects at home). Recorded on the `transfer` dimension -- the only way
  /// besides an in-app transfer session -- and the skill's mastery is
  /// recomputed from its whole profile.
  Future<SkillProfile> recordTransferProbe({required String childId, required String skillId, required bool passed}) async {
    final prior = await _persistence.currentDimension(childId: childId, skillId: skillId, dimension: 'transfer');
    // A pass stays a pass: a later "not yet" is logged but never erases it.
    final estimate = _assessment.recordProbeResult(skillId: skillId, passed: passed || (prior?.metrics['passed'] ?? 0) >= 1, now: _clock.now(), priorEvidenceCount: prior?.evidenceCount ?? 0);
    await _persistence.saveDimension(childId: childId, estimate: estimate);
    return skillProfile(childId: childId, skillId: skillId);
  }

  /// The persisted rung, or the first rung when there is none yet -- or when
  /// the persisted id is no longer in the game's ladder (content changed
  /// since it was saved), rather than carrying a dangling id forward.
  Future<String> _currentRungId({required String childId, required String gameId}) async {
    final game = _content.game(gameId);
    final saved = await _persistence.currentRung(childId: childId, gameId: gameId);
    return saved != null && game.rungsById.containsKey(saved) ? saved : game.rungIds.first;
  }

  /// The strictest help limits any of the rule's state criteria set (the
  /// ones Secure uses), read from content like every other threshold.
  static IndependenceLimits _independenceLimits(AssessmentRule rule, Map<String, Parameter> parameters) {
    num? hints, assist;
    for (final criterion in rule.stateCriteria.values) {
      final h = criterionParameter(criterion, parameters, 'hints-per-trial');
      final a = criterionParameter(criterion, parameters, 'adult-assist-per-trial');
      if (h != null && (hints == null || h < hints)) hints = h;
      if (a != null && (assist == null || a < assist)) assist = a;
    }
    return IndependenceLimits(maxHintsPerTrial: hints, maxAdultAssistPerTrial: assist);
  }

  Future<AdaptiveDecision> completeSession({
    required String childId,
    required String gameId,
    required String skillId,
    required List<RawMechanicEvent> rawEvents,
    required SignalMapper mapper,
    String? activityId,
    String? context,
  }) async {
    final sessionId = '$childId:$gameId:${_clock.now().microsecondsSinceEpoch}';
    final learningSignals = <LearningSignal>[];
    for (final event in rawEvents) {
      for (final draft in mapper(event)) {
        // A bundle without a signal the mapper knows (an older vocabulary)
        // simply does not collect it; the raw event still carries it.
        if (!_content.hasSignalDef(draft.signalDefId)) continue;
        final signal = _collector.collect(
          sessionId: sessionId, skillId: skillId,
          signalDefId: draft.signalDefId, value: draft.value, at: _clock.now(),
        );
        if (signal is LearningSignal) learningSignals.add(signal);
      }
    }

    final accuracySignals = learningSignals.where((s) => s.signalDefId == 'accuracy').toList();
    final hintsSignals = learningSignals.where((s) => s.signalDefId == 'hints_used').toList();
    final assistSignals = learningSignals.where((s) => s.signalDefId == 'adult_assist').toList();

    final performance = _assessment.computePerformance(skillId: skillId, accuracySignals: accuracySignals, now: _clock.now());
    final independence = _assessment.computeIndependence(
      skillId: skillId, hintsSignals: hintsSignals, adultAssistSignals: assistSignals,
      trials: accuracySignals.length, now: _clock.now(),
    );

    final rule = _content.assessmentRuleFor(skillId);
    final parameters = _content.allParameters();
    final priorTransfer = await _persistence.currentDimension(childId: childId, skillId: skillId, dimension: 'transfer');

    final game = _content.game(gameId);
    final currentRung = await _currentRungId(childId: childId, gameId: gameId);
    final plannedScaffold = await _persistence.currentScaffold(childId: childId, gameId: gameId);

    // This session's evidence, as the game reported it: first tries, help,
    // retries, and each explicit error type.
    final submissions = rawEvents.whereType<TrialSubmitted>().toList();
    final errors = <String, int>{};
    for (final s in submissions) {
      for (final e in s.errors) {
        errors[e] = (errors[e] ?? 0) + 1;
      }
    }
    final evidence = SkillEvidence(
      childId: childId,
      skillId: skillId,
      sessionId: sessionId,
      at: _clock.now(),
      gameId: gameId,
      mechanicId: game.mechanicId,
      activityId: activityId,
      context: context,
      rungId: currentRung,
      scaffold: plannedScaffold,
      trials: accuracySignals.length,
      correct: accuracySignals.where((s) => s.value >= 1).length,
      hints: hintsSignals.fold<num>(0, (a, s) => a + s.value).round(),
      hintRequests: submissions.fold<int>(0, (a, s) => a + s.hintRequestsThisTrial),
      adultAssists: assistSignals.fold<num>(0, (a, s) => a + s.value).round(),
      retries: submissions.where((s) => s.attempt > 1).length,
      selfCorrections: errors[ErrorType.selfCorrection] ?? 0,
      errors: errors,
    );

    // Mastery from the accumulated profile -- every session so far, this
    // one included -- never from this session alone. With a single session
    // it is exactly the Mastery Engine's verdict on that session.
    final history = [...await _persistence.skillEvidence(childId: childId, skillId: skillId), if (evidence.trials > 0) evidence];
    final profile = _profiles.build(skillId: skillId, evidence: history, rule: rule, parameters: parameters, probe: priorTransfer);
    final sessionOnly = _mastery.recompute(
      childId: childId, skillId: skillId,
      performance: performance, independence: independence, transfer: priorTransfer,
      rule: rule, parameters: parameters, now: _clock.now(),
    );
    final masteryRecord = MasteryRecord(
      childId: childId,
      skillId: skillId,
      state: profile.hasEvidence ? profile.state.key : sessionOnly.state,
      confidence: profile.hasEvidence ? profile.confidence : sessionOnly.confidence,
      updatedAt: _clock.now(),
    );

    final decision = _adaptive.recommend(
      childId: childId, game: game, rungIds: game.rungIds, currentRungId: currentRung,
      recentPerformance: performance, parameters: parameters,
      recentIndependence: independence, independenceLimits: _independenceLimits(rule, parameters),
    );

    await _persistence.saveSession(
      childId: childId, skillId: skillId, mastery: masteryRecord,
      performance: performance, independence: independence, transfer: priorTransfer,
      decision: decision,
      evidence: [if (evidence.trials > 0) evidence],
    );

    return decision;
  }
}

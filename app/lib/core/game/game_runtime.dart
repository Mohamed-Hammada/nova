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
  })  : _content = content,
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

  /// What the next session of [gameId] should be: the rung the Adaptive
  /// Engine last committed for this child (the first rung before any
  /// session), and enough trials for the skill's assessment rule to evaluate
  /// every state -- its `min-trials` parameter, read from content.
  Future<SessionPlan> planSession({required String childId, required String gameId, required String skillId}) async {
    final game = _content.game(gameId);
    final rungId = await _currentRungId(childId: childId, gameId: gameId);
    final trialCount = minTrialsFor(_content.assessmentRuleFor(skillId), _content.allParameters()) ?? 1;
    final scaffold = await _persistence.currentScaffold(childId: childId, gameId: gameId) ?? ScaffoldLevel.hintOnRequest;
    return SessionPlan(childId: childId, game: game, skillId: skillId, rung: game.rungsById[rungId]!, trialCount: trialCount, scaffold: scaffold);
  }

  /// Read-only view of a skill's mastery for presentation (e.g. the grown-ups'
  /// progress screen), so no widget ever reaches PersistencePort itself.
  Future<MasteryRecord?> currentMastery({required String childId, required String skillId}) =>
      _persistence.currentMastery(childId: childId, skillId: skillId);

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
  }) async {
    final sessionId = '$childId:$gameId:${_clock.now().microsecondsSinceEpoch}';
    final learningSignals = <LearningSignal>[];
    for (final event in rawEvents) {
      for (final draft in mapper(event)) {
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

    final masteryRecord = _mastery.recompute(
      childId: childId, skillId: skillId,
      performance: performance, independence: independence, transfer: priorTransfer,
      rule: rule, parameters: parameters, now: _clock.now(),
    );

    final game = _content.game(gameId);
    final currentRung = await _currentRungId(childId: childId, gameId: gameId);
    final decision = _adaptive.recommend(
      childId: childId, game: game, rungIds: game.rungIds, currentRungId: currentRung,
      recentPerformance: performance, parameters: parameters,
      recentIndependence: independence, independenceLimits: _independenceLimits(rule, parameters),
    );

    await _persistence.saveSession(
      childId: childId, skillId: skillId, mastery: masteryRecord,
      performance: performance, independence: independence, transfer: priorTransfer,
      decision: decision,
    );

    return decision;
  }
}

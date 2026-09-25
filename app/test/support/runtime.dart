import 'package:nova_app/core/adaptive/adaptive_model.dart';
import 'package:nova_app/core/adaptive/adaptive_progression_engine.dart';
import 'package:nova_app/core/assessment/assessment_engine.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/game/game_runtime.dart';
import 'package:nova_app/core/mastery/mastery_engine.dart';
import 'package:nova_app/core/ports/clock_port.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/core/signals/signal_bus.dart';
import 'package:nova_app/core/signals/signal_collector.dart';

/// A GameRuntime wired exactly as the composition root wires it, on the
/// given content and ports.
GameRuntime buildRuntime(ContentRuntime content, PersistencePort persistence, ClockPort clock, {SignalBus? bus}) {
  final signalBus = bus ?? InMemorySignalBus();
  return GameRuntime(
    content: content,
    bus: signalBus,
    collector: SignalCollector(content, signalBus),
    assessment: const AssessmentEngine(),
    mastery: const MasteryEngine(),
    adaptive: const AdaptiveProgressionEngine(RuleBasedAdaptiveModel()),
    persistence: persistence,
    clock: clock,
  );
}

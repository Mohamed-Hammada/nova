import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/adapters/audio_player/just_audio_port.dart';
import 'package:nova_app/adapters/clock_device/system_clock.dart';
import 'package:nova_app/adapters/persistence_drift/connection.dart';
import 'package:nova_app/adapters/persistence_drift/database.dart';
import 'package:nova_app/adapters/persistence_drift/drift_persistence_port.dart';
import 'package:nova_app/core/adaptive/adaptive_model.dart';
import 'package:nova_app/core/adaptive/adaptive_progression_engine.dart';
import 'package:nova_app/core/assessment/assessment_engine.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/game/game_runtime.dart';
import 'package:nova_app/core/mastery/mastery_engine.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/core/ports/clock_port.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/core/signals/signal_bus.dart';
import 'package:nova_app/core/signals/signal_collector.dart';

// Real content: loaded once at app start via loadContentRuntimeFromAssets()
// and overridden into this provider before runApp (see main.dart).
final contentRuntimeProvider = Provider<ContentRuntime>((ref) => throw UnimplementedError('override before use'));

final clockPortProvider = Provider<ClockPort>((ref) => const SystemClock());
final audioPortProvider = Provider<AudioPort>((ref) => JustAudioPort());

final persistencePortProvider = Provider<PersistencePort>((ref) {
  final db = NovaDatabase(openConnection());
  return DriftPersistencePort(db);
});

final signalBusProvider = Provider<SignalBus>((ref) => InMemorySignalBus());

final gameRuntimeProvider = Provider<GameRuntime>((ref) {
  final content = ref.watch(contentRuntimeProvider);
  final bus = ref.watch(signalBusProvider);
  return GameRuntime(
    content: content,
    bus: bus,
    collector: SignalCollector(content, bus),
    assessment: const AssessmentEngine(),
    mastery: const MasteryEngine(),
    adaptive: const AdaptiveProgressionEngine(RuleBasedAdaptiveModel()),
    persistence: ref.watch(persistencePortProvider),
    clock: ref.watch(clockPortProvider),
  );
});

// A single fixed local child for this slice; multiple children are Plan 2.
const currentChildId = 'local-child';

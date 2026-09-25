import 'package:flutter/widgets.dart' show Locale;
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
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/game/game_runtime.dart';
import 'package:nova_app/core/mastery/mastery_engine.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/core/ports/clock_port.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/core/signals/signal_bus.dart';
import 'package:nova_app/core/signals/signal_collector.dart';
import 'package:nova_app/ui/game/game_catalog.dart';

// Real content: loaded once at app start via loadContentRuntimeFromAssets()
// and overridden into this provider before runApp (see main.dart).
final contentRuntimeProvider = Provider<ContentRuntime>((ref) => throw UnimplementedError('override before use'));

final clockPortProvider = Provider<ClockPort>((ref) => const SystemClock());
// The asset paths actually bundled with this build (from the asset
// manifest, read at boot); null means "unknown", in which case every play
// is attempted and a missing file degrades to silence.
final bundledAssetsProvider = Provider<Set<String>?>((ref) => null);
final audioPortProvider = Provider<AudioPort>((ref) => JustAudioPort(bundledAssets: ref.watch(bundledAssetsProvider)));

// One database for the app's lifetime. openConnection() is chosen at compile
// time per platform (adapters/persistence_drift/connection.dart): native
// SQLite on devices, SQLite-on-WebAssembly in the browser. Nothing above this
// line knows which.
final persistencePortProvider = Provider<PersistencePort>((ref) {
  final db = NovaDatabase(openConnection());
  ref.onDispose(db.close);
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

/// The language the user picked, or null to follow the device.
final localeProvider = StateProvider<Locale?>((ref) => null);

/// The bundle's games that this app can run, in bundle order.
final playableGamesProvider = Provider<List<Game>>((ref) {
  final content = ref.watch(contentRuntimeProvider);
  return content.games.where((g) => playableGames.containsKey(g.id)).toList();
});

/// A skill's current mastery for the local child, read through GameRuntime
/// (never from PersistencePort directly). Invalidated after each session.
final masteryProvider = FutureProvider.autoDispose.family<MasteryRecord?, String>((ref, skillId) {
  return ref.watch(gameRuntimeProvider).currentMastery(childId: currentChildId, skillId: skillId);
});

// A single fixed local child for this slice; multiple children are Plan 2.
const currentChildId = 'local-child';

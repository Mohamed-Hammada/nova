import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/adapters/audio_player/just_audio_port.dart';
import 'package:nova_app/adapters/clock_device/system_clock.dart';
import 'package:nova_app/adapters/persistence_drift/connection.dart';
import 'package:nova_app/adapters/persistence_drift/database.dart';
import 'package:nova_app/adapters/persistence_drift/drift_persistence_port.dart';
import 'package:nova_app/adapters/persistence_drift/drift_player_state_port.dart';
import 'package:nova_app/adapters/speech/tts_speech_port.dart';
import 'package:nova_app/core/play/trial_factory.dart';
import 'package:nova_app/core/ports/player_state_port.dart';
import 'package:nova_app/core/ports/speech_port.dart';
import 'package:nova_app/core/ports/face_sensor_port.dart';
import 'package:nova_app/core/ports/voice_input_port.dart';
import 'package:nova_app/adapters/device/device_ports.dart';
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
import 'package:nova_app/ui/characters/character_rig.dart';
import 'package:nova_app/ui/game/game_catalog.dart';
import 'package:nova_app/ui/game/stage3d/stage_capability.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/theme/age_band.dart';
import 'package:nova_app/ui/theme/graphics.dart';

// Real content: loaded once at app start via loadContentRuntimeFromAssets()
// and overridden into this provider before runApp (see main.dart).
final contentRuntimeProvider = Provider<ContentRuntime>((ref) => throw UnimplementedError('override before use'));

final clockPortProvider = Provider<ClockPort>((ref) => const SystemClock());
// The asset paths actually bundled with this build (from the asset
// manifest, read at boot); null means "unknown", in which case every play
// is attempted and a missing file degrades to silence.
final bundledAssetsProvider = Provider<Set<String>?>((ref) => null);
final audioPortProvider = Provider<AudioPort>((ref) => JustAudioPort(bundledAssets: ref.watch(bundledAssetsProvider)));

/// Sound effects (taps, chimes, celebrations), unless a grown-up turned them
/// off. Separate players from narration, so an effect never cuts off a
/// spoken prompt. Only sounds the build really bundles are played; without
/// an asset manifest (tests, previews) effects stay silent.
final soundEffectsEnabledProvider = StateProvider<bool>((ref) => true);
final soundEffectsPortProvider = Provider<AudioPort>((ref) {
  final bundled = ref.watch(bundledAssetsProvider);
  if (!ref.watch(soundEffectsEnabledProvider) || bundled == null) return const SilentAudioPort();
  return JustAudioPort(bundledAssets: bundled, voices: 3);
});

// One database for the app's lifetime, shared by both storage ports.
// openConnection() is chosen at compile time per platform
// (adapters/persistence_drift/connection.dart): native SQLite on devices,
// SQLite-on-WebAssembly in the browser. Nothing above this line knows which.
final databaseProvider = Provider<NovaDatabase>((ref) {
  final db = NovaDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
});

final persistencePortProvider = Provider<PersistencePort>((ref) => DriftPersistencePort(ref.watch(databaseProvider)));

/// Level stars and settings (presentation state, not learning evidence).
final playerStatePortProvider = Provider<PlayerStatePort>((ref) => DriftPlayerStatePort(ref.watch(databaseProvider)));

/// Spoken prompts, unless a grown-up turned them off.
final speechEnabledProvider = StateProvider<bool>((ref) => true);
final ttsProvider = Provider<SpeechPort>((ref) => TtsSpeechPort());
final speechPortProvider = Provider<SpeechPort>((ref) => ref.watch(speechEnabledProvider) ? ref.watch(ttsProvider) : const SilentSpeechPort());

// Voice answers and face play: on-device only, off until a grown-up allows.
final voiceInputProvider = Provider<VoiceInputPort>((ref) => createVoiceInput());
final faceSensorProvider = Provider<FaceSensorPort>((ref) => createFaceSensor());

final trialFactoryProvider = Provider<TrialFactory>((ref) => const TrialFactory());

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

/// Every game the app can run: those with a dedicated screen (the catalog)
/// and those the shared level engine plays, in bundle order.
final allPlayableGamesProvider = Provider<List<Game>>((ref) {
  final content = ref.watch(contentRuntimeProvider);
  final factory = ref.watch(trialFactoryProvider);
  return content.games.where((g) => playableGames.containsKey(g.id) || factory.canPlayGame(g)).toList();
});

/// A skill's current mastery for the local child, read through GameRuntime
/// (never from PersistencePort directly). Invalidated after each session.
final masteryProvider = FutureProvider.autoDispose.family<MasteryRecord?, String>((ref, skillId) {
  return ref.watch(gameRuntimeProvider).currentMastery(childId: currentChildId, skillId: skillId);
});

// A single fixed local child for this slice; multiple children are Plan 2.
const currentChildId = 'local-child';

// Presentation settings, saved per device (ui/settings/settings_sync.dart).
final ageBandProvider = StateProvider<AgeBand>((ref) => AgeBand.explorer);

/// The content language in use: the picked locale, else the device's.
final languageProvider = Provider<String>((ref) => (ref.watch(localeProvider) ?? NovaLocales.resolve(PlatformDispatcher.instance.locales)).languageCode);

// The child's profile. Name and exact age are optional; companion and
// world follow the age group unless the child picks their own.
final childNameProvider = StateProvider<String>((ref) => '');
final childAgeProvider = StateProvider<int?>((ref) => null);
final companionChoiceProvider = StateProvider<CharacterKind?>((ref) => null);
final worldChoiceProvider = StateProvider<WorldKind?>((ref) => null);
final companionProvider = Provider<CharacterKind>((ref) => ref.watch(companionChoiceProvider) ?? ref.watch(ageBandProvider).character);
final worldProvider = Provider<WorldKind>((ref) => ref.watch(worldChoiceProvider) ?? ref.watch(ageBandProvider).world);
final paletteProvider = Provider<WorldPalette>((ref) => WorldPalette.of(ref.watch(worldProvider)));

// Grown-up settings.
/// The grown-up's graphics choice, shared by the 3D stage and the 2D worlds.
final graphicsSettingProvider = StateProvider<GraphicsQualitySetting>((ref) => GraphicsQualitySetting.auto);

/// How richly the 2D worlds and characters are drawn, from that choice.
final graphicsProvider = Provider<GraphicsQuality>((ref) => switch (ref.watch(graphicsSettingProvider)) {
      GraphicsQualitySetting.low => GraphicsQuality.low,
      GraphicsQualitySetting.medium || GraphicsQualitySetting.twoDimensional => GraphicsQuality.balanced,
      GraphicsQualitySetting.high || GraphicsQualitySetting.auto => GraphicsQuality.high,
    });
final voiceAnswersProvider = StateProvider<bool>((ref) => false);
final cameraPlayProvider = StateProvider<bool>((ref) => false);

// Looping decorative animation (idle characters, drifting clouds). Tests
// switch it off so the widget tree can settle; see ui/theme/motion.dart.
final ambientMotionProvider = Provider<bool>((ref) => true);

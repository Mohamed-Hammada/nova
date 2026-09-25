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
import 'package:nova_app/core/game/game_runtime.dart';
import 'package:nova_app/core/mastery/mastery_engine.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/core/ports/clock_port.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/core/signals/signal_bus.dart';
import 'package:nova_app/core/signals/signal_collector.dart';
import 'package:nova_app/ui/characters/character_rig.dart';
import 'package:nova_app/ui/theme/age_band.dart';
import 'package:nova_app/ui/theme/graphics.dart';

// Real content: loaded once at app start via loadContentRuntimeFromAssets()
// and overridden into this provider before runApp (see main.dart).
final contentRuntimeProvider = Provider<ContentRuntime>((ref) => throw UnimplementedError('override before use'));

final clockPortProvider = Provider<ClockPort>((ref) => const SystemClock());
final audioPortProvider = Provider<AudioPort>((ref) => JustAudioPort());

// One database for the whole app, shared by both storage ports.
final databaseProvider = Provider<NovaDatabase>((ref) => NovaDatabase(openConnection()));

final persistencePortProvider = Provider<PersistencePort>((ref) => DriftPersistencePort(ref.watch(databaseProvider)));

/// Level stars and settings (not learning evidence).
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

// A single fixed local child for this slice; multiple children are Plan 2.
const currentChildId = 'local-child';

// Presentation settings. Held in memory for now; persisting them per child
// arrives with multiple child profiles (Plan 2).
final ageBandProvider = StateProvider<AgeBand>((ref) => AgeBand.explorer);
final languageProvider = StateProvider<String>((ref) => 'en');

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
final graphicsProvider = StateProvider<GraphicsQuality>((ref) => GraphicsQuality.high);
final voiceAnswersProvider = StateProvider<bool>((ref) => false);
final cameraPlayProvider = StateProvider<bool>((ref) => false);

// Looping decorative animation (idle characters, drifting clouds). Tests
// switch it off so the widget tree can settle; see ui/theme/motion.dart.
final ambientMotionProvider = Provider<bool>((ref) => true);

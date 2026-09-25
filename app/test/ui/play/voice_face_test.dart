import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/in_memory_player_state_port.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/play/stories.dart';
import 'package:nova_app/core/play/trial_factory.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/core/ports/face_sensor_port.dart';
import 'package:nova_app/core/ports/voice_input_port.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/characters/character_view.dart';
import 'package:nova_app/ui/play/level_screen.dart';
import 'package:nova_app/ui/play/trial_views.dart';
import 'package:nova_app/ui/settings/face_play.dart';
import 'package:nova_app/ui/theme/motion.dart';

import '../../support/fake_speech_port.dart';
import '../../support/in_memory_persistence_port.dart';

class _FakeVoice implements VoiceInputPort {
  String? next;
  @override
  Future<bool> prepare({required String language}) async => true;
  @override
  Future<String?> listen({required String language, Duration max = const Duration(seconds: 5)}) async => next;
  @override
  Future<void> cancel() async {}
}

class _FakeFace implements FaceSensorPort {
  final controller = StreamController<FaceReading>.broadcast();
  bool started = false;
  @override
  Future<bool> start() async => started = true;
  @override
  Stream<FaceReading> get readings => controller.stream;
  @override
  Future<void> stop() async => started = false;
}

final _content = ContentRuntime(ContentBundle.fromJson(jsonDecode(File('assets/content/content_bundle.json').readAsStringSync()) as Map<String, dynamic>));

void main() {
  testWidgets('a spoken answer counts exactly like a tap', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final voice = _FakeVoice();
    const gameId = 'game.sel.feelings-friends';
    final game = _content.game(gameId);
    final first = const TrialFactory().build(game: game, rung: game.rungsById['r1']!, language: 'en', seed: 4).first as ChoiceTrial;
    voice.next = emotionWord((first.options[first.answer] as FaceVisual).emotion, 'en');

    await tester.pumpWidget(ProviderScope(
      overrides: [
        contentRuntimeProvider.overrideWithValue(_content),
        persistencePortProvider.overrideWithValue(InMemoryPersistencePort()),
        playerStatePortProvider.overrideWithValue(InMemoryPlayerStatePort()),
        ttsProvider.overrideWithValue(FakeSpeechPort()),
        voiceInputProvider.overrideWithValue(voice),
        voiceAnswersProvider.overrideWith((ref) => true),
      ],
      child: MaterialApp(
        home: AmbientMotion(
          enabled: false,
          child: LevelScreen(journey: Journey(id: 'j', nameKey: '', ageRange: const [2, 8], levels: [JourneyLevel(id: 'v-1', gameId: gameId)]), levelIndex: 0, seed: 4),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Say it!'), findsOneWidget);
    await tester.tap(find.text('Say it!'));
    await tester.pump(const Duration(milliseconds: 300));

    final cards = tester.widgetList<OptionCard>(find.byType(OptionCard)).toList();
    expect(cards[first.answer].state, OptionState.right);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('face play: the character smiles back, and the camera only runs while it is on', (tester) async {
    final face = _FakeFace();
    final guide = CharacterController();
    final container = ProviderContainer(overrides: [faceSensorProvider.overrideWithValue(face), cameraPlayProvider.overrideWith((ref) => true)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: Directionality(textDirection: TextDirection.ltr, child: FacePlay(controller: guide))));
    await tester.pump();
    expect(face.started, isTrue);
    expect(find.byIcon(Icons.videocam_rounded), findsOneWidget); // visible camera badge

    face.controller.add(const FaceReading(present: true, x: 0.5, smile: 0.1));
    await tester.pump();
    face.controller.add(const FaceReading(present: true, x: 0.5, smile: 0.95));
    await tester.pump();
    expect(guide.reaction, Reaction.happy);
    expect(guide.look, isNotNull);

    container.read(cameraPlayProvider.notifier).state = false;
    await tester.pump();
    await tester.pump();
    expect(face.started, isFalse);
    expect(find.byIcon(Icons.videocam_rounded), findsNothing);
  });
}

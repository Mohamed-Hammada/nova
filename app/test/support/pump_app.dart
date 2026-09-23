import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/app.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/core/ports/clock_port.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/providers.dart';

import 'fake_audio_port.dart';
import 'fake_clock.dart';
import 'fixture_content.dart';
import 'in_memory_persistence_port.dart';

/// The fakes a pumped app runs on, for assertions.
class AppHarness {
  AppHarness({required this.persistence, required this.clock, required this.audio, required this.container});
  final PersistencePort persistence;
  final FakeClock clock;
  final FakeAudioPort audio;
  final ProviderContainer container;
}

/// Pumps the real NovaApp (real theme, localization, screens, GameRuntime and
/// engines) on fake ports: in-memory persistence, a fixed clock, recorded
/// audio. [size] sets the logical window size; [locale] pins the language.
Future<AppHarness> pumpNovaApp(
  WidgetTester tester, {
  ContentRuntime? content,
  PersistencePort? persistence,
  Locale? locale,
  Size size = const Size(1280, 900),
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  if (disableAnimations) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  final store = persistence ?? InMemoryPersistencePort();
  final clock = FakeClock(DateTime(2026, 1, 1));
  final audio = FakeAudioPort();
  final container = ProviderContainer(overrides: [
    contentRuntimeProvider.overrideWithValue(content ?? fixtureContent()),
    persistencePortProvider.overrideWithValue(store),
    clockPortProvider.overrideWithValue(clock as ClockPort),
    audioPortProvider.overrideWithValue(audio as AudioPort),
  ]);
  addTearDown(container.dispose);
  if (locale != null) container.read(localeProvider.notifier).state = locale;

  // Start from a clean tree, so a second pump in one test gets a fresh
  // Navigator rather than the previous app's route stack.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const NovaApp()));
  await tester.pumpAndSettle();
  return AppHarness(persistence: store, clock: clock, audio: audio, container: container);
}

/// Opens the first game from Home and waits for the first trial.
Future<void> openBearApples(WidgetTester tester, {String name = "Bear's Apples"}) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

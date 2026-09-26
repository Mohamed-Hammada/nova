import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/audio/sound_effects.dart';
import 'package:nova_app/ui/play/trial_views.dart';

import '../support/fixture_content.dart';
import '../support/pump_app.dart';

class _Recorder implements AudioPort {
  final played = <String>[];
  @override
  Future<void> play(String assetPath) async => played.add(assetPath);
}

void main() {
  test('every sound effect is a bundled local file, listed in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/sfx/'));
    for (final s in Sfx.values) {
      final f = File(s.asset);
      expect(f.existsSync(), isTrue, reason: s.asset);
      expect(f.lengthSync(), lessThan(100 * 1024), reason: 'sound effects stay small');
      expect(s.asset, isNot(contains('http')));
    }
  });

  test('sound effects are silent when a grown-up turns them off, or without a manifest', () {
    final c = ProviderContainer(overrides: [bundledAssetsProvider.overrideWithValue({'assets/sfx/tap.wav'})]);
    addTearDown(c.dispose);
    expect(c.read(soundEffectsPortProvider), isNot(isA<SilentAudioPort>()));
    c.read(soundEffectsEnabledProvider.notifier).state = false;
    expect(c.read(soundEffectsPortProvider), isA<SilentAudioPort>());
    final bare = ProviderContainer();
    addTearDown(bare.dispose);
    expect(bare.read(soundEffectsPortProvider), isA<SilentAudioPort>());
  });

  testWidgets('play has sound: answers sweep in, a chime for a right answer, a gentle "hmm?" for a miss', (tester) async {
    final sfx = _Recorder();
    await pumpNovaApp(tester, content: loadRealBundle(), size: const Size(1280, 900), soundEffects: sfx);
    await openStage(tester, 'stage.explorer.counting-orchard');
    await tester.tap(find.byKey(const ValueKey('activity.explorer-003')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(sfx.played, contains(Sfx.whoosh.asset));
    final holders = tester.widgetList<ChoiceHolder>(find.byType(ChoiceHolder)).toList();
    final wrong = holders.indexWhere((h) => h.key is ValueKey);
    await tester.tap(find.byType(ChoiceHolder).at(wrong));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sfx.played.last, Sfx.retry.asset);
    await tester.pump(const Duration(milliseconds: 600));
    final answer = holders.indexWhere((h) => h.key is GlobalKey);
    await tester.tap(find.byType(ChoiceHolder).at(answer));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sfx.played.last, Sfx.success.asset);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/in_memory_player_state_port.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/characters/character_rig.dart';
import 'package:nova_app/ui/scene/world_backdrop.dart';
import 'package:nova_app/ui/settings/settings_sync.dart';
import 'package:nova_app/ui/theme/age_band.dart';
import 'package:nova_app/ui/theme/graphics.dart';
import 'package:nova_app/ui/theme/motion.dart';

void main() {
  test('an exact age picks its age group', () {
    expect(bandForAge(2), AgeBand.tiny);
    expect(bandForAge(3), AgeBand.tiny);
    expect(bandForAge(5), AgeBand.explorer);
    expect(bandForAge(8), AgeBand.champion);
  });

  test('companion and world follow the age group until the child picks their own', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(ageBandProvider.notifier).state = AgeBand.tiny;
    expect(c.read(companionProvider), CharacterKind.bunny);
    expect(c.read(worldProvider), WorldKind.candyMeadow);
    c.read(companionChoiceProvider.notifier).state = CharacterKind.robot;
    c.read(worldChoiceProvider.notifier).state = WorldKind.cosmicLab;
    expect(c.read(companionProvider), CharacterKind.robot);
    expect(c.read(paletteProvider).isNight, isTrue);
  });

  testWidgets('settings saved while the app runs are loaded back on the next start', (tester) async {
    final store = InMemoryPlayerStatePort();
    final first = ProviderContainer(overrides: [playerStatePortProvider.overrideWithValue(store)]);
    await tester.pumpWidget(UncontrolledProviderScope(container: first, child: const SettingsSync(child: SizedBox())));
    first.read(childNameProvider.notifier).state = 'Sara';
    first.read(childAgeProvider.notifier).state = 7;
    first.read(languageProvider.notifier).state = 'ar';
    first.read(companionChoiceProvider.notifier).state = CharacterKind.fox;
    first.read(graphicsProvider.notifier).state = GraphicsQuality.low;
    first.read(speechEnabledProvider.notifier).state = false;
    await tester.pump();

    final second = ProviderContainer(overrides: [playerStatePortProvider.overrideWithValue(store)]);
    await loadSettings(second, store);
    expect(second.read(childNameProvider), 'Sara');
    expect(second.read(childAgeProvider), 7);
    expect(second.read(ageBandProvider), AgeBand.champion);
    expect(second.read(languageProvider), 'ar');
    expect(second.read(companionProvider), CharacterKind.fox);
    expect(second.read(graphicsProvider), GraphicsQuality.low);
    expect(second.read(speechEnabledProvider), isFalse);
    first.dispose();
    second.dispose();
  });

  for (final q in GraphicsQuality.values) {
    testWidgets('every world paints at $q graphics quality', (tester) async {
      for (final w in WorldKind.values) {
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: AmbientMotion(enabled: true, child: Graphics(quality: q, child: WorldBackdrop(world: w))),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

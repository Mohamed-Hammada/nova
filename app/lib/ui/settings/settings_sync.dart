import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/ports/player_state_port.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_rig.dart';
import '../theme/age_band.dart';
import '../game/stage3d/stage_capability.dart';

/// The age group for an exact age.
AgeBand bandForAge(int age) => AgeBand.values.firstWhere((b) => age >= b.minAge && age <= b.maxAge, orElse: () => age < 2 ? AgeBand.tiny : AgeBand.champion);

T? _byName<T extends Enum>(List<T> values, String? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

/// Reads saved settings into the providers. Called once at startup, before
/// the first frame, so the app never flashes the defaults.
Future<void> loadSettings(ProviderContainer c, PlayerStatePort store) async {
  Future<String?> get(String key) => store.setting(key);
  final age = int.tryParse(await get('age') ?? '');
  if (age != null) {
    c.read(childAgeProvider.notifier).state = age;
    c.read(ageBandProvider.notifier).state = bandForAge(age);
  } else {
    final band = _byName(AgeBand.values, await get('band'));
    if (band != null) c.read(ageBandProvider.notifier).state = band;
  }
  final lang = await get('language');
  if (lang == 'ar' || lang == 'en') c.read(localeProvider.notifier).state = Locale(lang!);
  c.read(childNameProvider.notifier).state = await get('name') ?? '';
  c.read(companionChoiceProvider.notifier).state = _byName(CharacterKind.values, await get('companion'));
  c.read(worldChoiceProvider.notifier).state = _byName(WorldKind.values, await get('world'));
  final graphics = await get('graphics');
  if (graphics != null) c.read(graphicsSettingProvider.notifier).state = GraphicsQualitySetting.fromString(graphics);
  c.read(speechEnabledProvider.notifier).state = (await get('speech')) != 'off';
  c.read(soundEffectsEnabledProvider.notifier).state = (await get('soundEffects')) != 'off';
  c.read(voiceAnswersProvider.notifier).state = (await get('voiceAnswers')) == 'on';
  c.read(cameraPlayProvider.notifier).state = (await get('camera')) == 'on';
}

/// Saves each setting whenever it changes.
class SettingsSync extends ConsumerWidget {
  const SettingsSync({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void save(String key, String value) {
      try {
        ref.read(playerStatePortProvider).saveSetting(key, value).catchError((_) {});
      } catch (_) {
        // Storage unavailable: the setting still applies for this session.
      }
    }

    ref.listen(ageBandProvider, (_, b) => save('band', b.name));
    ref.listen(childAgeProvider, (_, a) => save('age', a?.toString() ?? ''));
    ref.listen(localeProvider, (_, l) => save('language', l?.languageCode ?? ''));
    ref.listen(childNameProvider, (_, n) => save('name', n));
    ref.listen(companionChoiceProvider, (_, c) => save('companion', c?.name ?? ''));
    ref.listen(worldChoiceProvider, (_, w) => save('world', w?.name ?? ''));
    ref.listen(graphicsSettingProvider, (_, g) => save('graphics', g.toJson()));
    ref.listen(speechEnabledProvider, (_, on) => save('speech', on ? 'on' : 'off'));
    ref.listen(soundEffectsEnabledProvider, (_, on) => save('soundEffects', on ? 'on' : 'off'));
    ref.listen(voiceAnswersProvider, (_, on) => save('voiceAnswers', on ? 'on' : 'off'));
    ref.listen(cameraPlayProvider, (_, on) => save('camera', on ? 'on' : 'off'));
    return child;
  }
}

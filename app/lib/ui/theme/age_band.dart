import 'package:flutter/material.dart';

import '../characters/character_rig.dart';

/// The three age groups the app is presented for. Each one gets its own
/// guide character, colour world and interface scale -- bigger touch targets
/// and fewer words for the youngest, more text and detail for the oldest.
///
/// This is presentation only: which games a child sees is still decided by
/// each game's `age_range` in the curriculum spec (see [overlaps]), and the
/// difficulty inside a game is still the adaptive engine's call.
enum AgeBand {
  tiny(minAge: 2, maxAge: 3, character: CharacterKind.bunny, world: WorldKind.candyMeadow, uiScale: 1.25),
  explorer(minAge: 4, maxAge: 5, character: CharacterKind.fox, world: WorldKind.sunnyForest, uiScale: 1.1),
  champion(minAge: 6, maxAge: 8, character: CharacterKind.robot, world: WorldKind.cosmicLab, uiScale: 1.0);

  const AgeBand({required this.minAge, required this.maxAge, required this.character, required this.world, required this.uiScale});

  final int minAge;
  final int maxAge;
  final CharacterKind character;
  final WorldKind world;

  /// Multiplier for touch targets and type. Toddlers get the biggest.
  final double uiScale;

  /// Whether a game made for ages [range] belongs in this band.
  bool overlaps(List<int> range) => range.length == 2 && range[0] <= maxAge && range[1] >= minAge;

  String get ageLabel => '$minAge–$maxAge';

  WorldPalette get palette => WorldPalette.of(world);
}

enum WorldKind { candyMeadow, sunnyForest, cosmicLab }

/// Every colour a world needs, from the sky down to the buttons, so a
/// screen can be re-skinned per age group by swapping one object.
class WorldPalette {
  const WorldPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.glow,
    required this.hillFar,
    required this.hillMid,
    required this.hillNear,
    required this.accent,
    required this.accentDeep,
    required this.surface,
    required this.onSurface,
    required this.onSky,
    required this.isNight,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color glow;
  final Color hillFar;
  final Color hillMid;
  final Color hillNear;
  final Color accent;
  final Color accentDeep;
  final Color surface;
  final Color onSurface;
  final Color onSky;
  final bool isNight;

  static WorldPalette of(WorldKind world) => switch (world) {
    WorldKind.candyMeadow => const WorldPalette(
      skyTop: Color(0xFFFFB5D2),
      skyBottom: Color(0xFFFFE9C7),
      glow: Color(0xFFFFF4D6),
      hillFar: Color(0xFFB9E4D0),
      hillMid: Color(0xFF8FD8B4),
      hillNear: Color(0xFF6CC79A),
      accent: Color(0xFFFF6FA5),
      accentDeep: Color(0xFFD9437D),
      surface: Color(0xFFFFFBF5),
      onSurface: Color(0xFF4A2E4F),
      onSky: Color(0xFF5B2C58),
      isNight: false,
    ),
    WorldKind.sunnyForest => const WorldPalette(
      skyTop: Color(0xFF4FB3FF),
      skyBottom: Color(0xFFFFD58A),
      glow: Color(0xFFFFF1B8),
      hillFar: Color(0xFF8CC7A1),
      hillMid: Color(0xFF55A86F),
      hillNear: Color(0xFF2F8A55),
      accent: Color(0xFFFF8A1F),
      accentDeep: Color(0xFFD35F00),
      surface: Color(0xFFFFFCF4),
      onSurface: Color(0xFF2E3A2F),
      onSky: Color(0xFF123B5C),
      isNight: false,
    ),
    WorldKind.cosmicLab => const WorldPalette(
      skyTop: Color(0xFF0B0B2E),
      skyBottom: Color(0xFF4B2A8C),
      glow: Color(0xFF7AF5FF),
      hillFar: Color(0xFF34236E),
      hillMid: Color(0xFF261A55),
      hillNear: Color(0xFF191140),
      accent: Color(0xFF28D7E8),
      accentDeep: Color(0xFF0F9DB0),
      surface: Color(0xFF1E1A45),
      onSurface: Color(0xFFF1EEFF),
      onSky: Color(0xFFF1EEFF),
      isNight: true,
    ),
  };
}

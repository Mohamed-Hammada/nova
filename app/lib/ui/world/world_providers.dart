import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';

import '../game/game_catalog.dart';
import 'activity_world.dart';

/// Every activity offered to this child: made for their age group and
/// language. Games with a dedicated screen (the catalog) are always offered.
final offeredGamesProvider = Provider<List<Game>>((ref) {
  final band = ref.watch(ageBandProvider);
  final language = ref.watch(languageProvider);
  return [
    for (final g in ref.watch(allPlayableGamesProvider))
      if (playableGames.containsKey(g.id) || (band.overlaps(g.ageRange) && (g.languageDependencies.isEmpty || g.languageDependencies.contains(language)))) g,
  ];
});

/// The offered activities grouped by place, in the order places are shown.
final placesProvider = Provider<Map<ActivityCategory, List<Game>>>((ref) {
  final games = ref.watch(offeredGamesProvider);
  return {
    for (final c in ActivityCategory.values)
      if (games.any((g) => ActivityCategory.of(g) == c)) c: [for (final g in games) if (ActivityCategory.of(g) == c) g],
  };
});

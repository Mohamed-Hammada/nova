import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';

/// The games a bundle WITHOUT a curriculum can offer this child (older or
/// test bundles; with a curriculum, the journey decides everything). Every
/// game must be made for the child's age -- their exact age once known,
/// else their age group -- and play in their language. Having a dedicated
/// screen never exempts a game from that.
final offeredGamesProvider = Provider<List<Game>>((ref) {
  final age = ref.watch(childAgeProvider);
  final band = ref.watch(ageBandProvider);
  final language = ref.watch(languageProvider);
  bool suits(Game g) => age != null ? g.ageRange.first <= age && age <= g.ageRange.last : band.overlaps(g.ageRange);
  return [
    for (final g in ref.watch(allPlayableGamesProvider))
      if (suits(g) && (g.languageDependencies.isEmpty || g.languageDependencies.contains(language))) g,
  ];
});

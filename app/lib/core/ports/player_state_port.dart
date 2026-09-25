/// Presentation state that is not learning evidence: stars per journey level
/// and device settings. Kept apart from PersistencePort, which only
/// GameRuntime may use for mastery (design doc section 4).
abstract class PlayerStatePort {
  /// Best stars (1-3) per level id; levels never finished are absent.
  Future<Map<String, int>> levelStars({required String childId});

  /// Records a finished level, keeping the best stars earned so far.
  Future<void> saveLevel({required String childId, required String levelId, required int stars});

  Future<String?> setting(String key);
  Future<void> saveSetting(String key, String value);
}

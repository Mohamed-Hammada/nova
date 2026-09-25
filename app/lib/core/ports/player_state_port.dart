import 'package:nova_app/core/journey/journey_models.dart';

/// Presentation state that is not learning evidence: stars per journey level,
/// the journey's activity records, and device settings. Kept apart from PersistencePort, which only
/// GameRuntime may use for mastery (design doc section 4).
abstract class PlayerStatePort {
  /// Best stars (1-3) per level id; levels never finished are absent.
  Future<Map<String, int>> levelStars({required String childId});

  /// Records a finished level, keeping the best stars earned so far.
  Future<void> saveLevel({required String childId, required String levelId, required int stars});

  /// Every activity record for [childId]. Records are never deleted.
  Future<List<ActivityRecord>> activityRecords({required String childId});

  /// Adds or replaces one activity record.
  Future<void> saveActivityRecord(ActivityRecord record);

  Future<String?> setting(String key);
  Future<void> saveSetting(String key, String value);
}

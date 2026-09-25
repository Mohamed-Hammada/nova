import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/ports/player_state_port.dart';

/// Keeps player state in memory: used by tests, and as a fallback if the
/// database cannot open.
class InMemoryPlayerStatePort implements PlayerStatePort {
  final _stars = <String, Map<String, int>>{};
  final _settings = <String, String>{};
  final _records = <String, Map<String, ActivityRecord>>{};

  @override
  Future<List<ActivityRecord>> activityRecords({required String childId}) async => [...?_records[childId]?.values];

  @override
  Future<void> saveActivityRecord(ActivityRecord record) async => _records.putIfAbsent(record.childId, () => {})[record.activityId] = record;

  @override
  Future<Map<String, int>> levelStars({required String childId}) async => Map.of(_stars[childId] ?? const {});

  @override
  Future<void> saveLevel({required String childId, required String levelId, required int stars}) async {
    final map = _stars.putIfAbsent(childId, () => {});
    if ((map[levelId] ?? 0) < stars) map[levelId] = stars;
  }

  @override
  Future<String?> setting(String key) async => _settings[key];

  @override
  Future<void> saveSetting(String key, String value) async => _settings[key] = value;
}

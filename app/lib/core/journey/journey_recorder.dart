import 'package:nova_app/core/ports/player_state_port.dart';

import 'curriculum_engine.dart';
import 'journey_models.dart';

/// Writes activity starts and finishes to the child's records. Whether a
/// finish counts as a completion is the activity's completion criteria,
/// decided here -- not by the game.
class JourneyRecorder {
  JourneyRecorder(this._port, this._curriculum, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final PlayerStatePort _port;
  final Curriculum _curriculum;
  final DateTime Function() _now;

  Future<ActivityRecord?> _existing(String childId, String activityId) async {
    for (final r in await _port.activityRecords(childId: childId)) {
      if (r.activityId == activityId) return r;
    }
    return null;
  }

  Future<void> start({required String childId, required String activityId}) async {
    final at = _now();
    final record = await _existing(childId, activityId) ?? ActivityRecord.fresh(childId, activityId, at);
    await _port.saveActivityRecord(record.started(at));
  }

  /// Records a finished session: whether it completes the activity (the
  /// activity's criteria), and the session evidence -- accuracy, hints, and
  /// the Adaptive Engine's decision -- that the curriculum engine uses for
  /// what comes next. Returns whether the activity now counts as completed.
  Future<bool> finish({required String childId, required String activityId, required SessionOutcome outcome}) async {
    final at = _now();
    final criteria = _curriculum.activity(activityId)?.completion ?? const CompletionCriteria();
    final completed = criteria.isMet(finishedAllRounds: outcome.finishedAllRounds, stars: outcome.stars);
    final record = await _existing(childId, activityId) ?? ActivityRecord.fresh(childId, activityId, at).started(at);
    await _port.saveActivityRecord(record.finished(at, completed: completed, stars: outcome.stars, accuracy: outcome.accuracy, outcome: outcome));
    if (completed) await _port.saveLevel(childId: childId, levelId: activityId, stars: outcome.stars);
    return completed;
  }
}

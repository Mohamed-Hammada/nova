import 'dart:async';
import 'dart:ui' show Offset;

import 'package:nova_app/core/ports/face_sensor_port.dart';

enum BuddyCue { smileBack, peekaboo }

/// Turns face readings into a character's behaviour: look where the child
/// is, smile back when they smile, and play peekaboo when their face
/// disappears and comes back. Pure logic, so it is testable without a camera.
class FaceBuddy {
  FaceBuddy({required this.onLook, required this.onCue, DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Where to look (-1..1 each way), or null to go back to idle.
  final void Function(Offset? target) onLook;
  final void Function(BuddyCue cue) onCue;
  final DateTime Function() _now;

  bool _smiling = false;
  DateTime? _lostAt;
  DateTime _lastCue = DateTime.fromMillisecondsSinceEpoch(0);
  StreamSubscription<FaceReading>? _sub;

  void attach(Stream<FaceReading> readings) {
    _sub?.cancel();
    _sub = readings.listen(update);
  }

  void update(FaceReading r) {
    final now = _now();
    if (!r.present) {
      _lostAt ??= now;
      if (now.difference(_lostAt!).inMilliseconds > 600) onLook(null);
      _smiling = false;
      return;
    }
    final lost = _lostAt;
    _lostAt = null;
    onLook(Offset(r.x.clamp(-1.0, 1.0) * 0.8, r.y.clamp(-1.0, 1.0) * 0.5));
    if (lost != null && now.difference(lost).inMilliseconds > 1200) {
      _cue(BuddyCue.peekaboo, now);
      return;
    }
    final smilingNow = r.smile > (_smiling ? 0.4 : 0.75); // hysteresis
    if (smilingNow && !_smiling) _cue(BuddyCue.smileBack, now);
    _smiling = smilingNow;
  }

  void _cue(BuddyCue cue, DateTime now) {
    // Don't overreact: at most one cue every two seconds.
    if (now.difference(_lastCue).inMilliseconds < 2000) return;
    _lastCue = now;
    onCue(cue);
  }

  void dispose() => _sub?.cancel();
}

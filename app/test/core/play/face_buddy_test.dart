import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/play/face_buddy.dart';
import 'package:nova_app/core/ports/face_sensor_port.dart';

void main() {
  late DateTime now;
  late List<Offset?> looks;
  late List<BuddyCue> cues;
  late FaceBuddy buddy;

  setUp(() {
    now = DateTime(2026);
    looks = [];
    cues = [];
    buddy = FaceBuddy(onLook: looks.add, onCue: cues.add, now: () => now);
  });

  void at(int ms, FaceReading r) {
    now = DateTime(2026).add(Duration(milliseconds: ms));
    buddy.update(r);
  }

  test('the character looks toward the child', () {
    at(0, const FaceReading(present: true, x: 0.5, y: -0.4));
    expect(looks.last!.dx, closeTo(0.4, 1e-9));
    expect(looks.last!.dy, closeTo(-0.2, 1e-9));
  });

  test('a new smile gets one smile back, not one per frame', () {
    at(0, const FaceReading(present: true, smile: 0.1));
    at(200, const FaceReading(present: true, smile: 0.9));
    at(400, const FaceReading(present: true, smile: 0.9));
    at(600, const FaceReading(present: true, smile: 0.6)); // still smiling (hysteresis)
    expect(cues, [BuddyCue.smileBack]);
  });

  test('hiding the face and coming back plays peekaboo; a flicker does not', () {
    at(0, const FaceReading(present: true));
    at(200, FaceReading.absent);
    at(400, const FaceReading(present: true)); // brief flicker
    expect(cues, isEmpty);
    at(3000, FaceReading.absent);
    at(4600, const FaceReading(present: true));
    expect(cues, [BuddyCue.peekaboo]);
  });

  test('when the face is gone for a moment the character stops staring', () {
    at(0, const FaceReading(present: true, x: 1));
    at(100, FaceReading.absent);
    at(900, FaceReading.absent);
    expect(looks.last, isNull);
  });
}

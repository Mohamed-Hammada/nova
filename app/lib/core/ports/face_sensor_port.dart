/// One look at the child's face, from the front camera, processed on the
/// device. Only these few numbers leave the detector: no image is kept.
class FaceReading {
  const FaceReading({required this.present, this.x = 0, this.y = 0, this.smile = 0, this.eyesOpen = 1});

  final bool present;

  /// Face centre, -1..1 each way, mirrored so moving right means right on screen.
  final double x;
  final double y;

  /// 0..1 likelihoods from the detector.
  final double smile;
  final double eyesOpen;

  static const absent = FaceReading(present: false);
}

abstract class FaceSensorPort {
  /// Starts the camera and detector, asking for camera permission if needed.
  Future<bool> start();
  Stream<FaceReading> get readings;
  Future<void> stop();
}

class NoFaceSensor implements FaceSensorPort {
  const NoFaceSensor();
  @override
  Future<bool> start() async => false;
  @override
  Stream<FaceReading> get readings => const Stream.empty();
  @override
  Future<void> stop() async {}
}

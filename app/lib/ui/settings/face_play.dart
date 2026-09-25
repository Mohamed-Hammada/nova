import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/play/face_buddy.dart';
import 'package:nova_app/core/ports/face_sensor_port.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_view.dart';
import 'capabilities.dart';

/// Face readings while face play is on. The camera runs only while a screen
/// that uses it is showing, and stops as soon as it is not.
final faceReadingsProvider = StreamProvider.autoDispose<FaceReading>((ref) async* {
  if (!ref.watch(cameraPlayProvider) || !facePlaySupported) return;
  final sensor = ref.watch(faceSensorProvider);
  ref.onDispose(sensor.stop);
  if (!await sensor.start()) return;
  yield* sensor.readings;
});

/// Lets [controller]'s character see the child: it looks at them, smiles
/// back, and plays peekaboo. Shows a small camera badge whenever the camera
/// is in use, so it is never on without anyone knowing.
class FacePlay extends ConsumerStatefulWidget {
  const FacePlay({super.key, required this.controller});
  final CharacterController controller;

  @override
  ConsumerState<FacePlay> createState() => _FacePlayState();
}

class _FacePlayState extends ConsumerState<FacePlay> {
  late final _buddy = FaceBuddy(
    onLook: (t) => widget.controller.lookAt(t == null ? null : Offset(t.x, t.y)),
    onCue: (cue) => widget.controller.react(cue == BuddyCue.smileBack ? Reaction.happy : Reaction.wave),
  );

  @override
  Widget build(BuildContext context) {
    final on = ref.watch(cameraPlayProvider) && facePlaySupported;
    if (!on) return const SizedBox.shrink();
    ref.listen(faceReadingsProvider, (_, next) {
      final r = next.value;
      if (r != null) _buddy.update(r);
    });
    final active = ref.watch(faceReadingsProvider).hasValue;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: active ? 1 : 0.4,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
          child: const Icon(Icons.videocam_rounded, color: Color(0xFF7CFF9E), size: 18),
        ),
      ),
    );
  }
}

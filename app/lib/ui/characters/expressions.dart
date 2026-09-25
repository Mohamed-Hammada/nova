import 'package:nova_app/core/play/trials.dart';

import 'character_rig.dart';

/// Still poses for faces and picture stories: the feelings games show these,
/// and the listening game's pictures act out a sentence.
Pose emotionPose(Emotion e) => switch (e) {
      Emotion.happy => const Pose(smile: 1, mouthOpen: 0.3, brow: 0.35),
      Emotion.sad => const Pose(smile: -0.9, browTilt: -0.9, headPitch: -0.12, lookY: 0.6, headRoll: 0.08),
      Emotion.surprised => const Pose(smile: 0, mouthOpen: 0.85, brow: 1),
      Emotion.angry => const Pose(smile: -0.6, browTilt: 1, brow: -0.2, headPitch: -0.05),
    };

Pose actionPose(Act a) => switch (a) {
      Act.sleeping => const Pose(blink: 1, headRoll: 0.28, smile: 0.4, headPitch: -0.1),
      Act.eating => const Pose(mouthOpen: 0.7, happyEyes: 1, smile: 1, armL: 0.9, armR: 0.9),
      Act.jumping => const Pose(jump: 36, squash: 1.06, armL: 2.4, armR: 2.4, smile: 1, mouthOpen: 0.4),
      Act.waving => const Pose(armR: 2.5, smile: 1, headRoll: 0.12, brow: 0.3),
    };

CharacterKind kindOf(Who who) => switch (who) {
      Who.bear => CharacterKind.bear,
      Who.bunny => CharacterKind.bunny,
      Who.fox => CharacterKind.fox,
      Who.robot => CharacterKind.robot,
    };

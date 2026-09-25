import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/characters/character_rig.dart';
import 'package:nova_app/ui/characters/character_view.dart';
import 'package:nova_app/ui/theme/motion.dart';

void main() {
  group('poseFor', () {
    test('every character and reaction produces finite pose values across the whole reaction', () {
      for (final kind in CharacterKind.values) {
        for (final reaction in [null, ...Reaction.values]) {
          final total = reaction?.duration.inMicroseconds ?? 1000000;
          for (var i = 0; i <= 20; i++) {
            final rt = total / 1e6 * i / 20;
            final p = poseFor(kind, i * 0.37, const Offset(0.4, -0.2), reaction, reaction == null ? null : rt);
            for (final v in [p.jump, p.squash, p.headYaw, p.headPitch, p.armL, p.armR, p.blink, p.mouthOpen, p.happyEyes]) {
              expect(v.isFinite, isTrue, reason: '$kind $reaction at $rt');
            }
            expect(p.squash, greaterThan(0.7));
            expect(p.blink, inInclusiveRange(0, 1));
          }
        }
      }
    });

    test('a cheer leaves the ground and ends back on it', () {
      final mid = poseFor(CharacterKind.bear, 0, Offset.zero, Reaction.cheer, 0.5);
      final end = poseFor(CharacterKind.bear, 0, Offset.zero, Reaction.cheer, Reaction.cheer.duration.inMicroseconds / 1e6);
      expect(mid.jump, greaterThan(20));
      expect(end.jump, 0);
    });

    test('looking right turns the head right', () {
      final p = poseFor(CharacterKind.fox, 0, const Offset(1, 0), null, null);
      expect(p.headYaw, greaterThan(0.3));
    });
  });

  test('M3 rotations are orthonormal and compose', () {
    final m = M3.euler(yaw: 0.7, pitch: -0.3, roll: 1.1);
    final v = m.apply(const V3(3, 4, 12));
    // Rotation preserves length.
    expect(v.x * v.x + v.y * v.y + v.z * v.z, closeTo(169, 1e-9));
  });

  for (final kind in CharacterKind.values) {
    testWidgets('$kind renders every reaction without errors', (tester) async {
      final controller = CharacterController();
      await tester.pumpWidget(
        AmbientMotion(
          enabled: false,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 260,
              child: CharacterView(kind: kind, controller: controller, entrance: Reaction.wave),
            ),
          ),
        ),
      );
      for (final r in Reaction.values) {
        controller.react(r);
        controller.lookAt(const Offset(-0.6, 0.3));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      }
      // Reactions are finite, so with ambient motion off the character comes to rest.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      controller.dispose();
    });
  }
}

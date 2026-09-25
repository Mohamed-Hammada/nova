import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/scene/world_backdrop.dart';
import 'package:nova_app/ui/theme/age_band.dart';
import 'package:nova_app/ui/theme/motion.dart';
import 'package:nova_app/ui/widgets/confetti.dart';
import 'package:nova_app/ui/widgets/props.dart';

void main() {
  for (final world in WorldKind.values) {
    testWidgets('$world paints over time without errors', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AmbientMotion(enabled: true, child: WorldBackdrop(world: world)),
        ),
      );
      // Sample enough frames to cross the shooting-star and cloud-wrap cycles.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('props and a confetti burst paint without errors, and the burst ends', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Column(children: [Apple3D(), Apple3D(lifted: true), Plate3D(glow: 1), StarShape(), StarShape(filled: false)]),
            Positioned.fill(child: ConfettiBurst(play: 1)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

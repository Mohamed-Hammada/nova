import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/bootstrap.dart';
import 'package:nova_app/ui/journey/onboarding_screen.dart';

import 'support/fixture_content.dart';
import 'support/pump_app.dart';

void main() {
  testWidgets('NovaApp renders the home screen with the playable game from content', (tester) async {
    await pumpNovaApp(tester);
    // The next activity is offered straight away.
    expect(find.text("Bear's Apples"), findsOneWidget);
    expect(find.byKey(const ValueKey('home.continue')), findsOneWidget);
    // In the bundle, but its mechanic has no implementation: not offered.
    expect(find.text('Number Match'), findsNothing);
  });

  testWidgets('boot shows a loading state, then the app once content is loaded', (tester) async {
    await tester.pumpWidget(NovaBootstrap(
      overrides: deviceFreeOverrides(),
      load: () => Future.delayed(const Duration(milliseconds: 50), () => BootResult(content: fixtureContent())),
    ));
    expect(find.text('Getting ready…'), findsOneWidget);
    await tester.pumpAndSettle();
    // A first launch (no saved age) opens onboarding.
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('a content bundle that fails to load shows a recoverable error, and retry recovers', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(NovaBootstrap(overrides: deviceFreeOverrides(), load: () async {
      attempts++;
      if (attempts == 1) throw StateError('bundle missing');
      return BootResult(content: fixtureContent());
    }));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('The games could not be loaded on this device.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(attempts, 2);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/bootstrap.dart';

import 'support/fixture_content.dart';
import 'support/pump_app.dart';

void main() {
  testWidgets('NovaApp renders the home screen with the playable game from content', (tester) async {
    await pumpNovaApp(tester);
    expect(find.text("Bear's Apples"), findsOneWidget);
    expect(find.text('Count up to 5'), findsOneWidget);
    // In the bundle, but its mechanic has no implementation: not offered.
    expect(find.text('Number Match'), findsNothing);
  });

  testWidgets('boot shows a loading state, then the app once content is loaded', (tester) async {
    await tester.pumpWidget(NovaBootstrap(
      load: () => Future.delayed(const Duration(milliseconds: 50), () => BootResult(content: fixtureContent())),
    ));
    expect(find.text('Getting ready…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text("Bear's Apples"), findsOneWidget);
  });

  testWidgets('a content bundle that fails to load shows a recoverable error, and retry recovers', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(NovaBootstrap(load: () async {
      attempts++;
      if (attempts == 1) throw StateError('bundle missing');
      return BootResult(content: fixtureContent());
    }));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('The games could not be loaded on this device.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pumpAndSettle();
    expect(find.text("Bear's Apples"), findsOneWidget);
    expect(attempts, 2);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the requested count from the English prompt ("Give the bear 3 apples").
int requestedCount(WidgetTester tester) {
  final prompt = tester.widget<Text>(find.textContaining('Give the bear')).data!;
  return int.parse(RegExp(r'(\d+)').firstMatch(prompt)!.group(1)!);
}

Finder pileItem(int id) => find.byKey(ValueKey('drag-to-count.item.$id'));
Finder plateItem(int id) => find.byKey(ValueKey('drag-to-count.plate-item.$id'));

/// Gives [count] apples (item ids 0..count-1 are always apples) by tapping,
/// not dragging.
Future<void> tapApples(WidgetTester tester, int count) async {
  for (var id = 0; id < count; id++) {
    await tester.ensureVisible(pileItem(id));
    await tester.pumpAndSettle();
    await tester.tap(pileItem(id));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// A Material button (of any ButtonStyleButton subclass, including the
/// private `.icon` variants) showing [label].
Finder buttonWithText(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

bool isEnabled(WidgetTester tester, String label) => tester.widget<ButtonStyleButton>(buttonWithText(label).first).enabled;

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(buttonWithText(label).first);
  await tester.pumpAndSettle();
  await tester.tap(buttonWithText(label).first);
  await tester.pumpAndSettle();
}

/// Plays the current trial correctly by tapping, and continues past the
/// feedback.
Future<void> playCorrectTrial(WidgetTester tester) async {
  await tapApples(tester, requestedCount(tester));
  await tapButton(tester, 'Done');
  expect(find.text("That's just right! The bear is happy."), findsOneWidget);
  await tapButton(tester, 'Next');
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('a correct TrialSubmitted maps to accuracy=1.0 and the hint count', () {
    final drafts = bearApplesSignalMapper(TrialSubmitted(correct: true, hintsUsedThisTrial: 1, at: now));
    expect(drafts, contains(isA<SignalDraft>().having((d) => d.signalDefId, 'signalDefId', 'accuracy').having((d) => d.value, 'value', 1.0)));
    expect(drafts, contains(isA<SignalDraft>().having((d) => d.signalDefId, 'signalDefId', 'hints_used').having((d) => d.value, 'value', 1)));
  });

  test('an incorrect TrialSubmitted maps to accuracy=0.0', () {
    final drafts = bearApplesSignalMapper(TrialSubmitted(correct: false, hintsUsedThisTrial: 0, at: now));
    expect(drafts, contains(isA<SignalDraft>().having((d) => d.signalDefId, 'signalDefId', 'accuracy').having((d) => d.value, 'value', 0.0)));
  });

  test('an ItemPlaced event produces no signal drafts on its own', () {
    final drafts = bearApplesSignalMapper(ItemPlaced(runningTotal: 1, requestedTotal: 3, usedHint: false, at: now));
    expect(drafts, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';

Map<String, num> _asMap(List<SignalDraft> drafts) => {for (final d in drafts) d.signalDefId: d.value};

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

  test('an ItemRemoved event produces no signal drafts on its own', () {
    expect(bearApplesSignalMapper(ItemRemoved(runningTotal: 0, at: now)), isEmpty);
  });

  test('a retry is NOT accuracy evidence: a correct second attempt cannot turn a miss into a hit', () {
    final drafts = bearApplesSignalMapper(TrialSubmitted(correct: true, hintsUsedThisTrial: 0, attempt: 2, at: now));
    expect(_asMap(drafts).containsKey('accuracy'), isFalse);
    expect(_asMap(drafts)['retries'], 1);
  });

  test('hints used during a retry still count toward hints_used (support lowers independence)', () {
    final drafts = bearApplesSignalMapper(TrialSubmitted(correct: true, hintsUsedThisTrial: 2, attempt: 2, at: now));
    expect(_asMap(drafts)['hints_used'], 2);
  });
}

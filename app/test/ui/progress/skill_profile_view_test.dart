import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/skills/error_types.dart';
import 'package:nova_app/core/skills/skill_evidence.dart';

import '../../support/fixture_content.dart';
import '../../support/in_memory_persistence_port.dart';
import '../../support/pump_app.dart';

/// The grown-ups' view of a skill: descriptive evidence from every session,
/// never a score.
void main() {
  const skill = 'math.count.one-to-one-5';
  const compare = 'math.compare.more-fewer';

  Future<InMemoryPersistencePort> withHistory() async {
    final store = InMemoryPersistencePort();
    final t0 = DateTime(2026, 1, 1, 9);
    Future<void> session(String id, String skillId, int correct, int day, {Map<String, int> errors = const {}, String game = 'game.math.bear-apples', String mechanic = 'drag-to-count', String? skin}) => store.saveSession(
          childId: 'local-child', skillId: skillId,
          mastery: MasteryRecord(childId: 'local-child', skillId: skillId, state: null, confidence: 0, updatedAt: t0),
          performance: null, independence: null, transfer: null,
          decision: AdaptiveDecision(childId: 'local-child', gameId: game, nextRungId: 'r1', scaffold: 'hint_on_request', reason: 'x'),
          evidence: [
            SkillEvidence(childId: 'local-child', skillId: skillId, sessionId: id, at: t0.add(Duration(days: day)), gameId: game, mechanicId: mechanic, context: skin, trials: 6, correct: correct, errors: errors),
          ],
        );
    await session('a', skill, 4, 0, skin: 'apples');
    await session('b', skill, 6, 1, skin: 'shells');
    await session('c', skill, 6, 2, skin: 'fish');
    await session('d', compare, 3, 3, game: 'game.math.more-or-less', mechanic: 'compare-quantities', errors: {ErrorType.choseSmaller: 2});
    await session('e', compare, 3, 4, game: 'game.math.more-or-less', mechanic: 'compare-quantities', errors: {ErrorType.choseSmaller: 2});
    return store;
  }

  Future<void> openProgress(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.family_restroom_rounded));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  testWidgets('each skill shows its state, trend, independence, history, transfer, and a mistake that keeps coming back', (tester) async {
    await pumpNovaApp(tester, content: loadRealBundle(), persistence: await withHistory());
    await openProgress(tester);
    final history = find.byKey(const ValueKey('profile.$skill.history'));
    await scrollTo(tester, history);
    expect(find.text('3 sessions · 18 rounds · 3 settings'), findsOneWidget);
    expect(find.text('Improving'), findsWidgets);
    expect(find.text('Plays independently'), findsWidgets);
    expect(find.text('Transfer: ready to try somewhere new'), findsOneWidget);
    expect(find.textContaining('Try it at home'), findsWidgets);

    final compareHistory = find.byKey(const ValueKey('profile.$compare.history'));
    await scrollTo(tester, compareHistory);
    expect(find.text('Keeps happening: choosing the smaller group'), findsOneWidget);
    // No score, no rank anywhere.
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('a grown-up reports the home task went well: the skill shows Transfer', (tester) async {
    final store = await withHistory();
    await pumpNovaApp(tester, content: loadRealBundle(), persistence: store);
    await openProgress(tester);
    final passed = find.byKey(const ValueKey('probe.$skill.passed'));
    await scrollTo(tester, passed);
    await tester.tap(passed);
    await tester.pumpAndSettle();
    expect(find.text('Thanks! Noted.'), findsOneWidget);
    expect((await store.currentDimension(childId: 'local-child', skillId: skill, dimension: 'transfer'))!.metrics['passed'], 1);
    await scrollTo(tester, find.byKey(const ValueKey('profile.$skill.history')));
    expect(find.text('Transfer: shown somewhere new'), findsOneWidget);
  });

  testWidgets('Progress shows communication skills on the ENDCORE map: basic skills under the ones for getting on with others', (tester) async {
    final store = InMemoryPersistencePort();
    final t0 = DateTime(2026, 1, 1, 9);
    await store.saveSession(
      childId: 'local-child', skillId: 'sel.emotion.faces',
      mastery: MasteryRecord(childId: 'local-child', skillId: 'sel.emotion.faces', state: 'secure', confidence: 0.5, updatedAt: t0),
      performance: null, independence: null, transfer: null,
      decision: const AdaptiveDecision(childId: 'local-child', gameId: 'game.sel.feelings-friends', nextRungId: 'r1', scaffold: 'hint_on_request', reason: 'x'),
      evidence: [SkillEvidence(childId: 'local-child', skillId: 'sel.emotion.faces', sessionId: 's', at: t0, gameId: 'game.sel.feelings-friends', mechanicId: 'emotion-match', trials: 6, correct: 6)],
    );
    await pumpNovaApp(tester, content: loadRealBundle(), persistence: store);
    await openProgress(tester);
    expect(find.text('Communication and social skills'), findsOneWidget);
    for (final cell in ['expressivity', 'decoding', 'selfControl', 'assertion', 'otherAcceptance', 'relationships']) {
      expect(find.byKey(ValueKey('endcore.$cell')), findsOneWidget, reason: cell);
    }
    // Reading feelings has evidence; the others have not been played.
    expect(find.descendant(of: find.byKey(const ValueKey('endcore.decoding')), matching: find.text('Secure')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('endcore.assertion')), matching: find.text('Not played yet')), findsOneWidget);
    // "With others" is drawn above "Basic".
    expect(tester.getTopLeft(find.byKey(const ValueKey('endcore.assertion'))).dy, lessThan(tester.getTopLeft(find.byKey(const ValueKey('endcore.expressivity'))).dy));
  });
}

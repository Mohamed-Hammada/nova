import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/adaptive/adaptive_model.dart';
import 'package:nova_app/core/adaptive/adaptive_progression_engine.dart';
import 'package:nova_app/core/assessment/assessment_engine.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/game/game_runtime.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mastery/mastery_engine.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/core/signals/signal_bus.dart';
import 'package:nova_app/core/signals/signal_collector.dart';

import '../../support/fake_clock.dart';
import '../../support/in_memory_persistence_port.dart';

/// This is the test the other GameRuntime tests deliberately are NOT:
/// instead of a hand-built JSON literal shaped like the real content (which
/// only proves ContentRuntime can parse a shape resembling the real data),
/// this loads the ACTUAL compiled app/assets/content/content_bundle.json
/// from disk -- the same file the real app's asset_content_loader.dart
/// loads at runtime -- and runs GameRuntime against it. It proves the full
/// chain: real data/ -> real compiler -> real bundle -> ContentBundle.fromJson
/// -> ContentRuntime -> GameRuntime, with no fixture standing in for any
/// link. If tools/content_compiler's output shape, or a model's fromJson,
/// or a real assessment rule/parameter in data/ ever drifts from what
/// GameRuntime expects, this test -- not just the hand-built-fixture ones
/// -- is what catches it.
///
/// Requires the bundle to exist on disk: run
/// `scripts/regenerate_content_bundle.sh` (or `scripts/test_app.sh`, which
/// does so automatically) before running this test directly.
void main() {
  test('the real compiled bundle drives GameRuntime to Secure for game.math.bear-apples', () async {
    final bundleFile = File('assets/content/content_bundle.json');
    expect(
      bundleFile.existsSync(),
      isTrue,
      reason: 'Run scripts/regenerate_content_bundle.sh before this test '
          '(the bundle is a gitignored build artifact, not committed).',
    );

    final json = jsonDecode(bundleFile.readAsStringSync()) as Map<String, dynamic>;
    final content = ContentRuntime(ContentBundle.fromJson(json));

    // Confirm the real ids this test depends on actually made it into the
    // bundle, so a failure here points at the compiler/data, not this test.
    expect(content.game('game.math.bear-apples').mechanicId, 'drag-to-count');
    expect(content.skill('math.count.one-to-one-5').id, 'math.count.one-to-one-5');
    expect(content.assessmentRuleFor('math.count.one-to-one-5').id, 'rule.math.count.one-to-one-5');

    final bus = InMemorySignalBus();
    final persistence = InMemoryPersistencePort();
    final clock = FakeClock(DateTime(2026, 1, 1));
    final runtime = GameRuntime(
      content: content,
      bus: bus,
      collector: SignalCollector(content, bus),
      assessment: const AssessmentEngine(),
      mastery: const MasteryEngine(),
      adaptive: const AdaptiveProgressionEngine(RuleBasedAdaptiveModel()),
      persistence: persistence,
      clock: clock,
    );

    // Six correct, unhinted, unassisted trials -- the same real
    // param.default.* thresholds as game_runtime_test.dart's hand-built
    // fixture (min-trials=6, secure-accuracy=0.85, secure caps=0.2), but
    // read here from the actual compiled data/parameters/defaults.yaml.
    final events = List.generate(6, (_) => TrialSubmitted(correct: true, hintsUsedThisTrial: 0, at: clock.now()));

    final decision = await runtime.completeSession(
      childId: 'real-bundle-child',
      gameId: 'game.math.bear-apples',
      skillId: 'math.count.one-to-one-5',
      rawEvents: events,
      mapper: bearApplesSignalMapper,
    );

    expect(decision.gameId, 'game.math.bear-apples');
    // game.math.bear-apples's real ladder is r1, r2, r3; starting at r1
    // with accuracy 1.0 >= the real advance-accuracy parameter advances one rung.
    expect(decision.nextRungId, 'r2');

    final mastery = await persistence.currentMastery(childId: 'real-bundle-child', skillId: 'math.count.one-to-one-5');
    expect(mastery!.state, 'secure');
  });
}

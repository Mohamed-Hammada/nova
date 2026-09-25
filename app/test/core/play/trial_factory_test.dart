import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/play/lexicon.dart';
import 'package:nova_app/core/play/session.dart';
import 'package:nova_app/core/play/trial_factory.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';

/// Runs against the real compiled bundle (regenerate it with
/// scripts/regenerate_content_bundle.sh), like game_runtime_real_bundle_test.
ContentRuntime _real() {
  final json = jsonDecode(File('assets/content/content_bundle.json').readAsStringSync()) as Map<String, dynamic>;
  return ContentRuntime(ContentBundle.fromJson(json));
}

void main() {
  final content = _real();
  const factory = TrialFactory();

  test('every game used by a journey level can be played', () {
    for (final journey in content.journeys) {
      for (final level in journey.levels) {
        for (final language in ['en', 'ar']) {
          final id = level.gameFor(language);
          expect(factory.canPlay(id), isTrue, reason: '${level.id} ($language) -> $id');
        }
      }
    }
  });

  test('each journey has at least 50 levels and covers ages 2 to 8', () {
    for (final j in content.journeys) {
      expect(j.levels.length, greaterThanOrEqualTo(50), reason: j.id);
    }
    for (var age = 2; age <= 8; age++) {
      expect(content.journeyForAge(age), isNotNull, reason: 'age $age');
    }
  });

  test('every rung of every playable game builds well-formed trials in both languages, for many seeds', () {
    for (final id in factory.playableGameIds) {
      final game = content.game(id);
      for (final rungId in game.rungIds) {
        for (final language in ['en', 'ar']) {
          if (game.languageDependencies.isNotEmpty && !game.languageDependencies.contains(language)) continue;
          for (var seed = 0; seed < 25; seed++) {
            final trials = factory.build(game: game, rung: game.rungsById[rungId]!, language: language, seed: seed, skin: 'fish');
            expect(trials, isNotEmpty, reason: '$id $rungId $language');
            for (final t in trials) {
              _checkWellFormed(t, '$id $rungId $language seed $seed');
            }
          }
        }
      }
    }
  });

  test('the same seed gives the same level', () {
    final game = content.game('game.math.more-or-less');
    final rung = game.rungsById[game.rungIds.last]!;
    String describe(List<Trial> ts) => ts.map((t) => (t as ChoiceTrial).answer).join(',');
    expect(describe(factory.build(game: game, rung: rung, language: 'en', seed: 7)), describe(factory.build(game: game, rung: rung, language: 'en', seed: 7)));
  });

  test('harder rungs really are harder: bear-apples requests grow, simon sequences lengthen', () {
    final bear = content.game('game.math.bear-apples');
    int maxTarget(String rung) => [
          for (var s = 0; s < 30; s++)
            ...factory.build(game: bear, rung: bear.rungsById[rung]!, language: 'en', seed: s).cast<DragCountTrial>().map((t) => t.target),
        ].reduce((a, b) => a > b ? a : b);
    expect(maxTarget('r1'), lessThanOrEqualTo(3));
    expect(maxTarget('r2'), 5);

    final simon = content.game('game.memory.simon-lights');
    final first = factory.build(game: simon, rung: simon.rungsById['r1']!, language: 'en', seed: 1).first as SequenceTrial;
    final last = factory.build(game: simon, rung: simon.rungsById[simon.rungIds.last]!, language: 'en', seed: 1).first as SequenceTrial;
    expect(last.sequence.length, greaterThan(first.sequence.length));
  });

  test('sort-switch changes the rule halfway at its first rung', () {
    final game = content.game('game.ef.sort-switch');
    final trials = factory.build(game: game, rung: game.rungsById['r1']!, language: 'en', seed: 3).cast<SortTrial>();
    expect(trials.first.rule, SortRule.colour);
    expect(trials.last.rule, SortRule.shape);
    expect(trials.where((t) => t.switched), hasLength(1));
  });

  test('Arabic letter-forms offers joined (initial) forms as answers', () {
    final game = content.game('game.lit.ar.letter-forms');
    final t = factory.build(game: game, rung: game.rungsById['r1']!, language: 'ar', seed: 2).first as ChoiceTrial;
    final answer = t.options[t.answer] as TextVisual;
    expect(answer.text.endsWith('ـ'), isTrue);
  });

  test('PlaySession logs one TrialSubmitted per response and scores stars from accuracy', () async {
    final session = PlaySession(mechanicId: 'x', trials: const [ClapTrial(word: Word(Pic.sun, 'sun', ['sun']))], now: () => DateTime(2026));
    final events = <RawMechanicEvent>[];
    session.rawEvents.listen(events.add);
    session.useHint();
    session.record(true);
    session.record(false);
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<TrialSubmitted>().map((e) => e.correct), [true, false]);
    expect(events.whereType<TrialSubmitted>().first.hintsUsedThisTrial, 1);
    expect(session.stars, 1);
    expect(session.next(), isFalse);
    expect(session.isFinished, isTrue);
  });
}

void _checkWellFormed(Trial t, String where) {
  switch (t) {
    case ChoiceTrial():
      expect(t.options.length, greaterThanOrEqualTo(2), reason: where);
      expect(t.answer, inInclusiveRange(0, t.options.length - 1), reason: where);
    case DragCountTrial():
      expect(t.target, inInclusiveRange(1, t.pile), reason: where);
    case TapCountTrial():
      expect(t.choices, contains(t.count), reason: where);
      expect(t.choices.toSet().length, t.choices.length, reason: where);
    case JoinSeparateTrial():
      expect(t.result, greaterThanOrEqualTo(0), reason: where);
      expect(t.choices, contains(t.result), reason: where);
      expect(t.choices.toSet().length, t.choices.length, reason: where);
    case NumberLineTrial():
      expect(t.target, inInclusiveRange(0, t.max), reason: where);
    case SortTrial():
      expect(t.isCorrect(t.answer), isTrue, reason: where);
    case PairsTrial():
      expect(t.cards.length, t.pairs * 2, reason: where);
    case SequenceTrial():
      expect(t.sequence, everyElement(inInclusiveRange(0, t.pads - 1)), reason: where);
    case StreamItemTrial():
      expect(t.showFor.inMilliseconds, greaterThan(0), reason: where);
    case ClapTrial():
      expect(t.word.parts, isNotEmpty, reason: where);
    case PrintTrial():
      expect(t.order, isNotEmpty, reason: where);
    case BuildWordTrial():
      expect(t.tiles.toSet(), containsAll(t.word.letters.toSet()), reason: where);
  }
}

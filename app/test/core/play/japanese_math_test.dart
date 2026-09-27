import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/play/tape_stories.dart';
import 'package:nova_app/core/play/trial_factory.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/core/skills/error_types.dart';

import '../../support/fixture_content.dart';

/// Cherry Sums (さくらんぼ計算) and Tape Stories (テープ図), the Japanese
/// methods, in Arabic and English.
void main() {
  final content = loadRealBundle();
  const factory = TrialFactory();
  List<ChoiceTrial> build(String gameId, String rung, String lang, {int seed = 1}) =>
      factory.build(game: content.game(gameId), rung: content.game(gameId).rungsById[rung]!, language: lang, seed: seed).cast<ChoiceTrial>();
  int value(ChoiceTrial t, int i) => (t.options[i] as NumeralVisual).value;

  for (final lang in ['en', 'ar']) {
    group('Cherry Sums ($lang)', () {
      test('step 1: the part that makes ten; step 2: what is left; step 3: the sum, always past ten', () {
        for (final seed in [1, 2, 3]) {
          for (final (rung, step) in [('r1', 0), ('r2', 1), ('r3', 2)]) {
            for (final t in build('game.math.cherry-sums', rung, lang, seed: seed)) {
              final v = t.question! as CherryVisual;
              expect(v.a + v.b, greaterThan(10), reason: 'every sum passes ten');
              final toTen = 10 - v.a, rest = v.b - toTen;
              final want = [toTen, rest, v.a + v.b][step];
              expect(value(t, t.answer), want);
              if (step == 1) expect(v.first, toTen, reason: 'the ten is made before asking what is left');
              if (step == 2) expect(v.askTotal, isTrue);
              for (var i = 0; i < t.options.length; i++) {
                if (i != t.answer) expect(t.errorsFor(i), [value(t, i) > want ? ErrorType.overCount : ErrorType.underCount]);
              }
            }
          }
        }
      });
    });

    group('Tape Stories ($lang)', () {
      test('the whole is missing, then a part; numbers stay within ten; the story is read aloud', () {
        for (final seed in [1, 2, 3]) {
          for (final (rung, takeAway) in [('r1', false), ('r2', true)]) {
            for (final t in build('game.math.tape-stories', rung, lang, seed: seed)) {
              final tape = t.question! as TapeVisual;
              expect(tape.sizeA + tape.sizeB, lessThanOrEqualTo(10));
              expect(takeAway ? tape.partA : tape.whole, isNull, reason: 'the missing number');
              expect(value(t, t.answer), takeAway ? tape.sizeA : tape.sizeA + tape.sizeB);
              expect(t.speak, t.promptArgs['story']);
              if (lang == 'ar') expect(RegExp(r'[0-9]').hasMatch(t.speak!), isFalse, reason: 'Eastern digits in Arabic');
            }
          }
        }
      });
    });
  }

  test('Arabic counts agree with their noun, and verbs with the noun and the hero', () {
    const apple = TapeNoun('apple', 'apples', 'تفاحة واحدة', 'تفاحتان', 'تفاحات');
    const balloon = TapeNoun('balloon', 'balloons', 'بالون واحد', 'بالونان', 'بالونات', arFeminine: false);
    expect(apple.count(1, 'ar'), 'تفاحة واحدة');
    expect(apple.count(2, 'ar'), 'تفاحتان');
    expect(apple.count(7, 'ar'), '٧ تفاحات');
    final luna = tapeHeroes.firstWhere((h) => h.female);
    final pip = tapeHeroes.firstWhere((h) => !h.female);
    expect(joinStory('ar', pip, balloon, 3, 2), 'لدى بيب ٣ بالونات، ثم جاءه بالونان. كم أصبح لديه الآن؟');
    expect(joinStory('ar', luna, apple, 5, 3), 'لدى لونا ٥ تفاحات، ثم جاءتها ٣ تفاحات. كم أصبح لديها الآن؟');
    expect(separateStory('ar', pip, balloon, 6, 1), 'كان لدى بيب ٦ بالونات، ثم ذهب منها بالون واحد. كم بقي؟');
    expect(separateStory('ar', pip, apple, 8, 3), 'كان لدى بيب ٨ تفاحات، ثم ذهبت منها ٣ تفاحات. كم بقي؟');
    expect(joinStory('en', pip, apple, 1, 2), 'Pip has 1 apple. Then 2 more apples came. How many now?');
  });
}

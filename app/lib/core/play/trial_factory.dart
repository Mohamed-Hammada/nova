import 'dart:math';

import 'package:nova_app/core/content/models.dart';

import 'lexicon.dart';
import 'stories.dart';
import 'trials.dart';

/// Turns a game's current rung into concrete trials.
///
/// The rung values index each game's own anchors in data/games (for
/// example bear-apples' item_complexity 0 = "requests of 1 to 3"); the
/// builders below are the app's reading of those anchor labels. Everything
/// is seeded, so the same seed always gives the same level.
typedef _TrialBuilder = List<Trial> Function(_Ctx c);

/// Trials per session: at least param.default.min-trials (6), since mastery
/// is computed per session and fewer trials could never reach Emerging.
const trialsPerSession = 6;

class TrialFactory {
  const TrialFactory();

  static final Map<String, _TrialBuilder> _builders = {
    'game.math.bunny-carrots': (c) => _dragCount(c, maxLow: 2, maxHigh: 3, item: c.skinPic ?? Pic.carrot, distractor: Pic.radish),
    'game.math.bear-apples': (c) => _dragCount(c, maxLow: 3, maxHigh: 5, item: c.skinPic ?? Pic.apple, distractor: Pic.pear),
    'game.math.number-match': _numberMatch,
    'game.math.more-or-less': _moreOrLess,
    'game.math.number-catch': _numberCatch,
    'game.math.pattern-train': _patternTrain,
    'game.math.pattern-builder': _patternBuilder,
    'game.math.star-count': _starCount,
    'game.math.add-take-away': (c) => _joinSeparate(c, bigTotals: false),
    'game.math.space-shop': (c) => _joinSeparate(c, bigTotals: true),
    'game.math.number-line-hop': _numberLine,
    'game.cog.color-sort': _colorSort,
    'game.ef.sort-switch': _sortSwitch,
    'game.memory.peekaboo-pairs': _pairs,
    'game.memory.simon-lights': _simon,
    'game.ef.feed-the-fish': _feedFish,
    'game.sel.feelings-friends': _feelings,
    'game.sel.how-would-they-feel': _situations,
    for (final l in ['en', 'ar']) ...{
      'game.lit.$l.listen-and-find': _listen,
      'game.lit.$l.word-hunt': _wordHunt,
      'game.lit.$l.clap-syllables': _clap,
      'game.lit.$l.rhyme-time': _rhyme,
      'game.lit.$l.book-explorer': _book,
      'game.lit.$l.first-sound': _firstSound,
      'game.lit.$l.word-builder': _builder,
      'game.lit.$l.sound-blender': _blender,
      'game.lit.$l.word-pictures': _readWords,
      'game.lit.$l.letter-catch': _letterCatch,
    },
    'game.lit.en.letter-pairs': _letterPairs,
    'game.lit.ar.letter-forms': _letterForms,
  };

  /// The mechanic each builder implements. A game is only playable when the
  /// content gives it this same mechanic, so a builder never reads a rung
  /// ladder written for a different kind of game.
  static final Map<String, String> _mechanics = {
    'game.sel.feelings-friends': 'emotion-match',
    'game.sel.how-would-they-feel': 'story-choice',
    'game.lit.ar.letter-forms': 'letter-match',
    'game.lit.en.letter-pairs': 'letter-match',
    'game.math.bear-apples': 'drag-to-count',
    'game.math.number-match': 'match-symbol-to-quantity',
    'game.math.bunny-carrots': 'drag-to-count',
    'game.math.more-or-less': 'compare-quantities',
    'game.math.number-catch': 'catch-target',
    'game.math.pattern-train': 'pattern-continue',
    'game.math.pattern-builder': 'pattern-continue',
    'game.math.star-count': 'tap-to-count',
    'game.math.add-take-away': 'join-separate',
    'game.math.space-shop': 'join-separate',
    'game.math.number-line-hop': 'number-line-place',
    'game.cog.color-sort': 'sort-by-rule',
    'game.ef.sort-switch': 'switch-sort-rule',
    'game.memory.peekaboo-pairs': 'match-pairs',
    'game.memory.simon-lights': 'sequence-recall',
    'game.ef.feed-the-fish': 'go-no-go',
    for (final l in ['en', 'ar']) ...{
      'game.lit.$l.listen-and-find': 'story-choice',
      'game.lit.$l.word-hunt': 'hear-and-point',
      'game.lit.$l.clap-syllables': 'segment-sounds',
      'game.lit.$l.rhyme-time': 'rhyme-select',
      'game.lit.$l.book-explorer': 'print-follow',
      'game.lit.$l.letter-catch': 'catch-target',
      'game.lit.$l.first-sound': 'sound-match',
      'game.lit.$l.word-builder': 'build-word',
      'game.lit.$l.sound-blender': 'blend-sounds',
      'game.lit.$l.word-pictures': 'read-and-match',
    },
  };

  bool canPlay(String gameId) => _builders.containsKey(gameId);

  /// Whether [game] has a builder for its id and its mechanic.
  bool canPlayGame(Game game) => canPlay(game.id) && _mechanics[game.id] == game.mechanicId;

  Iterable<String> get playableGameIds => _builders.keys;

  List<Trial> build({required Game game, required Rung rung, required String language, required int seed, String? skin}) {
    final builder = _builders[game.id];
    if (builder == null) throw ArgumentError('no trial builder for ${game.id}');
    return builder(_Ctx(rung, Random(seed), language, skin));
  }
}

class _Ctx {
  _Ctx(this.rung, this.rng, this.lang, this.skin);
  final Rung rung;
  final Random rng;
  final String lang;
  final String? skin;

  int v(String dimension) => rung.values[dimension] ?? 0;
  int get ic => v('item_complexity');
  int get dist => v('distractors');
  int get abs => v('abstraction');
  int get rule => v('rule_complexity');
  int get wm => v('working_memory_load');
  int get load => v('cognitive_load');
  bool get ar => lang == 'ar';

  int between(int lo, int hi) => lo + rng.nextInt(hi - lo + 1);
  T pick<T>(List<T> xs) => xs[rng.nextInt(xs.length)];
  List<T> shuffled<T>(Iterable<T> xs) => (List<T>.of(xs)..shuffle(rng));

  Pic? get skinPic => switch (skin) {
    'apples' => Pic.apple,
    'carrots' => Pic.carrot,
    'fish' => Pic.fish,
    'stars' => Pic.star,
    'balls' => Pic.ball,
    'flowers' => Pic.flower,
    'shells' => Pic.shell,
    'hearts' => Pic.heart,
    _ => null,
  };

  /// [answer] placed at a random position among [others]; returns (options, index).
  (List<X>, int) withAnswer<X>(X answer, List<X> others) {
    final all = shuffled([answer, ...others]);
    return (all, all.indexOf(answer));
  }

  /// Nearby wrong numbers for a numeric answer.
  List<int> near(int answer, int count, {int min = 0, int max = 30}) {
    final out = <int>{};
    var spread = 1;
    while (out.length < count) {
      for (final d in [spread, -spread]) {
        final n = answer + d;
        if (n >= min && n <= max && n != answer && out.length < count) out.add(n);
      }
      spread++;
    }
    return shuffled(out);
  }

  List<Word> get words => lexicon(lang);
}

// ----------------------------------------------------------------- math ----

List<Trial> _dragCount(_Ctx c, {required int maxLow, required int maxHigh, required Pic item, required Pic distractor}) {
  final max = c.ic == 0 ? maxLow : maxHigh;
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final target = c.between(1, max);
        return DragCountTrial(
          target: target,
          item: item,
          pile: min(target + 2, max + 1),
          distractor: c.dist > 0 ? distractor : null,
          distractorCount: c.dist > 0 ? 2 : 0,
        );
      }(),
  ];
}

List<Trial> _numberMatch(_Ctx c) {
  final groups = c.dist == 0 ? 2 : 3;
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final n = c.between(1, 5);
        final others = c.near(n, groups - 1, min: 1, max: 6);
        final (values, answer) = c.withAnswer(n, others);
        final pic = c.skinPic ?? c.pick<Pic>([Pic.apple, Pic.star, Pic.fish, Pic.ball]);
        return ChoiceTrial(
          promptKey: 'match_number',
          promptArgs: {'n': '$n'},
          question: NumeralVisual(n),
          options: [for (final v in values) c.abs == 0 ? GroupVisual(Pic.gem, v) : GroupVisual(pic, v, scattered: true, seed: c.rng.nextInt(999))],
          answer: answer,
        );
      }(),
  ];
}

List<Trial> _moreOrLess(_Ctx c) {
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        late int a, b;
        switch (c.ic) {
          case 0:
            a = c.between(1, 2);
            b = c.between(a + 2, 4);
          case 1:
            a = c.between(1, 5);
            b = min(6, a + c.between(1, 2));
          default:
            a = c.between(1, 9);
            b = a + 1;
        }
        final askMore = c.rule == 0 || c.rng.nextBool();
        final left = c.rng.nextBool();
        final pic = c.skinPic ?? c.pick<Pic>([Pic.apple, Pic.fish, Pic.star, Pic.flower]);
        final values = left ? [b, a] : [a, b];
        final bigger = values[0] > values[1] ? 0 : 1;
        return ChoiceTrial(
          promptKey: askMore ? 'pick_more' : 'pick_fewer',
          options: [for (final v in values) GroupVisual(pic, v, scattered: c.ic > 0, seed: c.rng.nextInt(999))],
          answer: askMore ? bigger : 1 - bigger,
          optionsAreBig: true,
        );
      }(),
  ];
}

List<Trial> _numberCatch(_Ctx c) {
  final maxN = c.ic == 0 ? 5 : 10;
  final target = c.between(1, maxN);
  const lookAlike = {6: 9, 9: 6, 1: 7, 7: 1, 3: 8, 8: 3, 2: 5, 5: 2};
  final others = [
    for (var n = 1; n <= maxN; n++)
      if (n != target) n,
  ];
  return [
    for (var i = 0; i < 12; i++)
      () {
        final isTarget = i < 2 ? i == 0 : c.rng.nextDouble() < 0.4;
        final value = isTarget ? target : (c.dist > 0 && lookAlike.containsKey(target) && c.rng.nextBool() ? lookAlike[target]! : c.pick(others));
        return StreamItemTrial(
          visual: NumeralVisual(value),
          isTarget: value == target,
          showFor: const Duration(milliseconds: 2200),
          targetLabel: NumeralVisual(target),
          theme: StreamTheme.balloons,
        );
      }(),
  ];
}

List<Trial> _patternTrain(_Ctx c) {
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final hues = c.shuffled(Hue.values).take(3).toList();
        final shapes = c.shuffled(Shape.values).take(3).toList();
        Token t(int k) => c.abs == 0 ? Token(Shape.circle, hues[k]) : Token(shapes[k], hues[k]);
        final unit = switch (c.ic) {
          0 => [t(0), t(1)],
          1 => [t(0), t(1), t(2)],
          _ => c.rng.nextBool() ? [t(0), t(0), t(1)] : [t(0), t(1), t(1)],
        };
        final length = unit.length * 2 + c.between(0, unit.length - 1);
        final shown = [for (var k = 0; k < length; k++) unit[k % unit.length]];
        final next = unit[length % unit.length];
        final wrong = <Token>{...unit, t(2)}..remove(next);
        final (options, answer) = c.withAnswer<Token>(next, c.shuffled(wrong).take(2).toList());
        return ChoiceTrial(promptKey: 'what_next', question: PatternVisual(shown), options: [for (final o in options) TokenVisual(o)], answer: answer);
      }(),
  ];
}

List<Trial> _patternBuilder(_Ctx c) {
  final choices = c.dist == 0 ? 3 : 4;
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        late List<int> steps;
        late int next;
        switch (c.ic) {
          case 0:
            final unit = c.shuffled([1, 2, 3, 4]);
            steps = [...unit, ...unit.take(2)];
            next = unit[2];
          case 1:
            final s = c.between(1, 3);
            steps = [s, s + 1, s + 2, s + 3];
            next = s + 4;
          default:
            final s = c.between(1, 2);
            steps = [s, s + 2, s + 4];
            next = s + 6;
        }
        final (heights, answer) = c.withAnswer(next, c.near(next, choices - 1, min: 1, max: 10));
        return ChoiceTrial(
          promptKey: 'what_next_tower',
          question: TowersVisual(steps),
          options: [
            for (final h in heights) TowersVisual([h], withGap: false),
          ],
          answer: answer,
        );
      }(),
  ];
}

List<Trial> _starCount(_Ctx c) {
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final n = c.ic < 2 ? c.between(6, 10) : c.between(11, 20);
        final choices = c.shuffled([n, ...c.near(n, 2, min: 1, max: 25)]);
        return TapCountTrial(count: n, pic: c.skinPic ?? Pic.star, scattered: c.ic > 0, choices: choices, seed: c.rng.nextInt(9999));
      }(),
  ];
}

List<Trial> _joinSeparate(_Ctx c, {required bool bigTotals}) {
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        late int start, change;
        if (!bigTotals) {
          if (c.ic == 0) {
            start = c.between(1, 4);
            change = c.between(1, 5 - start);
          } else if (c.rng.nextBool()) {
            start = c.between(2, 9);
            change = c.between(1, 10 - start);
          } else {
            start = c.between(3, 10);
            change = -c.between(1, start - 1);
          }
        } else if (c.ic == 0) {
          // Up to 15, never crossing ten: 11 + 3, 14 - 2.
          start = c.between(11, 13);
          change = c.rng.nextBool() ? c.between(1, 15 - start) : -c.between(1, start - 10);
        } else {
          // Up to 20, crossing ten: 8 + 5, 13 - 6.
          if (c.rng.nextBool()) {
            start = c.between(6, 9);
            change = c.between(11 - start, min(20 - start, 9));
          } else {
            start = c.between(11, 18);
            change = -c.between(start - 9, min(start - 1, 9));
          }
        }
        final result = start + change;
        return JoinSeparateTrial(
          start: start,
          change: change,
          pic: bigTotals ? Pic.gem : Pic.bird,
          hidden: c.abs > 0,
          choices: c.shuffled([result, ...c.near(result, 2, min: 0, max: 20)]),
        );
      }(),
  ];
}

List<Trial> _numberLine(_Ctx c) {
  final max = c.ic == 0 ? 10 : 20;
  final labelEvery = switch (c.abs) {
    0 => 1,
    1 => 5,
    _ => 0,
  };
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        var target = c.between(1, max - 1);
        if (labelEvery == 5 && target % 5 == 0) target += 1;
        return NumberLineTrial(max: max, target: target, labelEvery: labelEvery, tolerance: labelEvery == 0 ? 1 : 0);
      }(),
  ];
}

// ------------------------------------------------------------- thinking ----

List<Trial> _colorSort(_Ctx c) {
  final rule = c.rule == 0 ? SortRule.colour : SortRule.shape;
  final hues = c.shuffled(Hue.values).take(2).toList();
  final shapes = c.shuffled(Shape.values).take(2).toList();
  final bins = rule == SortRule.colour
      ? [Token(Shape.circle, hues[0]), Token(Shape.circle, hues[1])]
      : [Token(shapes[0], Hue.purple), Token(shapes[1], Hue.purple)];
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final k = c.rng.nextInt(2);
        final card = rule == SortRule.colour
            ? Token(c.dist == 0 ? Shape.circle : c.pick(shapes), hues[k])
            : Token(shapes[k], c.dist == 0 ? Hue.purple : c.pick(hues));
        return SortTrial(card: card, rule: rule, bins: bins, switched: false);
      }(),
  ];
}

List<Trial> _sortSwitch(_Ctx c) {
  // Classic rule-switch card sorting: the bins' pictures conflict with the
  // cards, so a card matches one bin by colour and the other by shape.
  const bins = [Token(Shape.star, Hue.red), Token(Shape.circle, Hue.blue)];
  const cards = [Token(Shape.star, Hue.blue), Token(Shape.circle, Hue.red)];
  const count = 8;
  final trials = <Trial>[];
  var previous = SortRule.colour;
  for (var i = 0; i < count; i++) {
    final bordered = c.rule == 2 && c.rng.nextBool();
    final rule = switch (c.rule) {
      0 => i < count ~/ 2 ? SortRule.colour : SortRule.shape,
      1 => (i ~/ 2).isEven ? SortRule.colour : SortRule.shape,
      _ => bordered ? SortRule.shape : SortRule.colour,
    };
    trials.add(SortTrial(card: c.pick(cards), rule: rule, bins: bins, switched: i > 0 && rule != previous, bordered: bordered));
    previous = rule;
  }
  return trials;
}

List<Trial> _pairs(_Ctx c) {
  final pairs = const [2, 3, 4, 6][c.wm.clamp(0, 3)];
  const pool = [Pic.apple, Pic.star, Pic.fish, Pic.ball, Pic.flower, Pic.heart, Pic.bird, Pic.sun, Pic.moon, Pic.car, Pic.cake, Pic.duck];
  return [
    for (var i = 0; i < 3; i++)
      () {
        final pics = c.shuffled(pool).take(pairs).toList();
        return PairsTrial(cards: c.shuffled([...pics, ...pics]), pairs: pairs);
      }(),
  ];
}

List<Trial> _simon(_Ctx c) {
  final length = 2 + c.wm;
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final seq = <int>[];
        while (seq.length < length) {
          final pad = c.rng.nextInt(4);
          if (seq.isEmpty || seq.last != pad) seq.add(pad);
        }
        return SequenceTrial(pads: 4, sequence: seq);
      }(),
  ];
}

List<Trial> _feedFish(_Ctx c) {
  final ms = const [2000, 1500, 1100][c.load.clamp(0, 2)];
  final noGoRate = c.dist == 0 ? 0.25 : 0.5;
  return [
    for (var i = 0; i < 12; i++)
      () {
        final go = i < 2 || c.rng.nextDouble() >= noGoRate;
        return StreamItemTrial(
          visual: PicVisual(go ? Pic.fish : Pic.shark),
          isTarget: go,
          showFor: Duration(milliseconds: ms),
        );
      }(),
  ];
}

// ------------------------------------------------------------- feelings ----

List<Trial> _feelings(_Ctx c) {
  final emotions = Emotion.values.take(2 + c.ic).toList();
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final who = c.shuffled(Who.values);
        final e = c.pick(emotions);
        final wrong = c.shuffled(emotions.where((x) => x != e)).take(min(2, emotions.length - 1)).toList();
        final (options, answer) = c.withAnswer(e, wrong);
        return ChoiceTrial(
          promptKey: 'same_feeling',
          question: FaceVisual(who[0], e),
          options: [for (var k = 0; k < options.length; k++) FaceVisual(who[1 + k], options[k])],
          answer: answer,
          speak: emotionWord(e, c.lang),
        );
      }(),
  ];
}

List<Trial> _situations(_Ctx c) {
  final stories = c.shuffled(situations).take(trialsPerSession).toList();
  final choices = c.dist == 0 ? 2 : 3;
  return [
    for (final s in stories)
      () {
        final wrong = c.shuffled(Emotion.values.where((e) => e != s.emotion)).take(choices - 1).toList();
        final (options, answer) = c.withAnswer(s.emotion, wrong);
        final text = c.ar ? s.ar : s.en;
        return ChoiceTrial(
          promptKey: 'how_feel',
          promptArgs: {'story': text},
          question: SceneVisual(s.who, Act.waving, prop: s.prop),
          options: [for (final e in options) FaceVisual(s.who, e)],
          answer: answer,
          speak: text,
        );
      }(),
  ];
}

// ------------------------------------------------------------- literacy ----

List<Trial> _listen(_Ctx c) {
  final choices = c.dist == 0 ? 2 : 3;
  const props = [Pic.ball, Pic.apple, Pic.star, Pic.balloon, Pic.book];
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final who = c.pick(Who.values);
        final action = c.pick(Act.values);
        final prop = c.ic > 0 ? c.pick(props) : null;
        final answerScene = SceneVisual(who, action, prop: prop);
        // Distractors differ in exactly one detail when there are three pictures.
        final others = <SceneVisual>[];
        while (others.length < choices - 1) {
          final change = c.rng.nextInt(prop == null ? 2 : 3);
          final s = switch (change) {
            0 => SceneVisual(c.pick(Who.values.where((w) => w != who).toList()), action, prop: prop),
            1 => SceneVisual(who, c.pick(Act.values.where((a) => a != action).toList()), prop: prop),
            _ => SceneVisual(who, action, prop: c.pick(props.where((p) => p != prop).toList())),
          };
          if (!others.any((o) => o.who == s.who && o.action == s.action && o.prop == s.prop)) others.add(s);
        }
        final (options, answer) = c.withAnswer<SceneVisual>(answerScene, others);
        final sentence = sceneSentence(answerScene, c.lang);
        return ChoiceTrial(promptKey: 'listen_find', options: options, answer: answer, speak: sentence, promptArgs: {'sentence': sentence});
      }(),
  ];
}

List<Trial> _wordHunt(_Ctx c) {
  final pool = [
    for (final p in (c.ic == 0 ? commonPics : lessCommonPics))
      if (wordFor(c.lang, p) != null) p,
  ];
  final allPics = [
    for (final p in [...commonPics, ...lessCommonPics])
      if (wordFor(c.lang, p) != null) p,
  ];
  final choices = c.dist == 0 ? 2 : 4;
  return [
    for (final target in c.shuffled(pool).take(trialsPerSession))
      () {
        final (options, answer) = c.withAnswer(target, c.shuffled(allPics.where((p) => p != target)).take(choices - 1).toList());
        final word = wordFor(c.lang, target)!.text;
        return ChoiceTrial(promptKey: 'find_word', promptArgs: {'word': word}, options: [for (final p in options) PicVisual(p)], answer: answer, speak: word);
      }(),
  ];
}

List<Trial> _clap(_Ctx c) {
  final maxParts = [2, 3, 4][c.ic.clamp(0, 2)];
  final minParts = c.ic == 0 ? 1 : 2;
  final pool = c.words.where((w) => w.parts.length >= minParts && w.parts.length <= maxParts).toList();
  return [for (final w in c.shuffled(pool).take(trialsPerSession)) ClapTrial(word: w)];
}

List<Trial> _rhyme(_Ctx c) {
  final groups = <String, List<Word>>{};
  for (final w in c.words) {
    if (w.rhyme != null) groups.putIfAbsent(w.rhyme!, () => []).add(w);
  }
  final rhyming = groups.values.where((g) => g.length >= 2).toList();
  final nonRhyming = c.words.where((w) => w.rhyme == null).toList();
  final choices = c.dist == 0 ? 2 : 3;
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final group = c.shuffled(c.pick(rhyming));
        final cue = group[0];
        final match = group[1];
        final wrong = <Word>[];
        if (choices == 3) {
          // One distractor starts with the same letter as the cue, if possible.
          final same = nonRhyming.where((w) => w.firstLetter == cue.firstLetter).toList();
          wrong.add(same.isNotEmpty ? c.pick(same) : c.pick(nonRhyming));
        }
        while (wrong.length < choices - 1) {
          final w = c.pick(nonRhyming);
          if (!wrong.contains(w)) wrong.add(w);
        }
        final (options, answer) = c.withAnswer(match, wrong);
        return ChoiceTrial(
          promptKey: 'rhyme',
          promptArgs: {'word': cue.text},
          question: PicVisual(cue.pic),
          options: [for (final w in options) PicVisual(w.pic)],
          answer: answer,
          speak: cue.text,
        );
      }(),
  ];
}

List<Trial> _book(_Ctx c) {
  final lines = printLines(c.lang);
  return [
    for (var i = 0; i < trialsPerSession; i++)
      () {
        final chosen = c.shuffled(lines).take(c.ic == 2 ? 2 : 1).toList();
        return PrintTrial(lines: chosen, rtl: c.ar, startOnly: c.ic == 0);
      }(),
  ];
}

List<Trial> _firstSound(_Ctx c) {
  final choices = c.dist == 0 ? 2 : 3;
  final letters = {for (final w in c.words) w.firstLetter}.toList();
  return [
    for (final w in c.shuffled(c.words).take(trialsPerSession))
      () {
        final (options, answer) = c.withAnswer(w.firstLetter, c.shuffled(letters.where((l) => l != w.firstLetter)).take(choices - 1).toList());
        return ChoiceTrial(
          promptKey: 'first_letter',
          promptArgs: {'word': w.text},
          question: PicVisual(w.pic),
          options: [for (final l in options) TextVisual(l, isLetter: true)],
          answer: answer,
          speak: w.text,
        );
      }(),
  ];
}

List<Trial> _builder(_Ctx c) {
  final length = c.ic == 0 ? 3 : 4;
  final pool = c.words.where((w) => w.letters.length == length).toList();
  final alphabet = c.ar ? 'ابتثجحخدرزسشصطعفقكلمنهوي' : 'abcdefghijklmnopqrstuvwxyz';
  return [
    for (final w in c.shuffled(pool).take(trialsPerSession))
      () {
        final tiles = [...w.letters];
        if (c.dist > 0) {
          final extra = alphabet.runes.map(String.fromCharCode).where((l) => !tiles.contains(l)).toList();
          tiles.add(c.pick(extra));
        }
        return BuildWordTrial(word: w, tiles: c.shuffled(tiles), rtl: c.ar);
      }(),
  ];
}

List<Trial> _blender(_Ctx c) {
  final pool = c.ic == 0 ? c.words.where((w) => w.parts.length >= 2).toList() : c.words.where((w) => w.letters.length <= 4).toList();
  return [
    for (final w in c.shuffled(pool).take(trialsPerSession))
      () {
        final parts = c.ic == 0 ? w.parts : w.letters;
        final (options, answer) = c.withAnswer(w, c.shuffled(c.words.where((x) => x != w)).take(2).toList());
        return ChoiceTrial(
          promptKey: 'blend',
          promptArgs: {'parts': parts.join(' - ')},
          options: [for (final o in options) PicVisual(o.pic)],
          answer: answer,
          speak: parts.join('... '),
        );
      }(),
  ];
}

List<Trial> _readWords(_Ctx c) {
  final short = c.ar ? 3 : 4;
  final pool = c.words.where((w) => c.ic == 0 ? w.letters.length <= short : w.letters.length > short).toList();
  return [
    for (final w in c.shuffled(pool).take(trialsPerSession))
      () {
        final similar = c.words.where((x) => x != w && (x.firstLetter == w.firstLetter || x.letters.length == w.letters.length)).toList();
        final source = c.dist > 0 && similar.length >= 2 ? similar : c.words.where((x) => x != w).toList();
        final (options, answer) = c.withAnswer(w, c.shuffled(source).take(2).toList());
        return ChoiceTrial(promptKey: 'read_find', question: TextVisual(w.text), options: [for (final o in options) PicVisual(o.pic)], answer: answer);
      }(),
  ];
}

List<Trial> _letterPairs(_Ctx c) {
  final letters = c.ic == 0 ? enLookAlikeCase : [for (var r = 65; r <= 90; r++) String.fromCharCode(r)];
  final choices = c.dist == 0 ? 2 : 3;
  return [
    for (final upper in c.shuffled(letters).take(trialsPerSession))
      () {
        final lower = upper.toLowerCase();
        final confusable = enConfusables[lower];
        final pool = [for (var r = 97; r <= 122; r++) String.fromCharCode(r)]..remove(lower);
        final wrong = <String>[];
        if (choices == 3 && confusable != null) wrong.add(c.pick(confusable));
        while (wrong.length < choices - 1) {
          final l = c.pick(pool);
          if (!wrong.contains(l)) wrong.add(l);
        }
        final (options, answer) = c.withAnswer(lower, wrong);
        return ChoiceTrial(
          promptKey: 'letter_small',
          promptArgs: {'letter': upper},
          question: TextVisual(upper, isLetter: true),
          options: [for (final o in options) TextVisual(o, isLetter: true)],
          answer: answer,
          speak: upper,
        );
      }(),
  ];
}

List<Trial> _letterForms(_Ctx c) {
  final letters = c.ic == 0 ? arStableForms : arChangingForms;
  final all = [...arStableForms, ...arChangingForms];
  final choices = c.dist == 0 ? 2 : 3;
  return [
    for (final letter in c.shuffled(letters).take(trialsPerSession))
      () {
        final family = arDotFamily(letter)?.where((l) => l != letter && all.contains(l)).toList() ?? const <String>[];
        final wrong = <String>[];
        if (choices == 3 && family.isNotEmpty) wrong.add(c.pick(family));
        while (wrong.length < choices - 1) {
          final l = c.pick(all);
          if (l != letter && !wrong.contains(l)) wrong.add(l);
        }
        final (options, answer) = c.withAnswer(letter, wrong);
        return ChoiceTrial(
          promptKey: 'letter_joined',
          promptArgs: {'letter': letter},
          question: TextVisual(letter, isLetter: true),
          options: [for (final o in options) TextVisual(arInitial(o), isLetter: true)],
          answer: answer,
          speak: letter,
        );
      }(),
  ];
}

List<Trial> _letterCatch(_Ctx c) {
  final ms = c.load == 0 ? 2300 : 1600;
  if (c.ar) {
    final letters = [...arStableForms, ...arChangingForms];
    final target = c.pick(letters);
    final family = arDotFamily(target)?.where((l) => l != target).toList() ?? const <String>[];
    return [
      for (var i = 0; i < 12; i++)
        () {
          final isTarget = i == 0 || (i > 1 && c.rng.nextDouble() < 0.4);
          final letter = isTarget ? target : (family.isNotEmpty && c.rng.nextBool() ? c.pick(family) : c.pick(letters.where((l) => l != target).toList()));
          final shown = c.ic > 0 && c.rng.nextBool() ? arInitial(letter) : letter;
          return StreamItemTrial(
            visual: TextVisual(shown, isLetter: true),
            isTarget: isTarget,
            showFor: Duration(milliseconds: ms),
            targetLabel: TextVisual(target, isLetter: true),
            theme: StreamTheme.bubbles,
          );
        }(),
    ];
  }
  final letters = c.ic == 0 ? enLookAlikeCase : [for (var r = 65; r <= 90; r++) String.fromCharCode(r)];
  final target = c.pick(letters);
  final lower = target.toLowerCase();
  final confusable = enConfusables[lower] ?? const <String>[];
  final pool = [for (var r = 97; r <= 122; r++) String.fromCharCode(r)]..remove(lower);
  return [
    for (var i = 0; i < 12; i++)
      () {
        final isTarget = i == 0 || (i > 1 && c.rng.nextDouble() < 0.4);
        final letter = isTarget ? lower : (confusable.isNotEmpty && c.rng.nextBool() ? c.pick(confusable) : c.pick(pool));
        return StreamItemTrial(
          visual: TextVisual(letter, isLetter: true),
          isTarget: isTarget,
          showFor: Duration(milliseconds: ms),
          targetLabel: TextVisual(target, isLetter: true),
          theme: StreamTheme.bubbles,
        );
      }(),
  ];
}

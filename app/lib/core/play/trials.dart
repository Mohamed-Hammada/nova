import 'lexicon.dart';

/// One round inside a level. Each game turns its current rung into a list of
/// trials (see trial_factory.dart); a view presents one trial at a time and
/// reports whether the child's response was correct.
///
/// Everything here is plain Dart so correctness rules are unit-testable
/// without widgets.
sealed class Trial {
  const Trial();
}

// ---------------------------------------------------------------------------
// What a trial can show
// ---------------------------------------------------------------------------

enum Shape { circle, square, triangle, star, heart }

enum Hue { red, blue, yellow, green, purple }

class Token {
  const Token(this.shape, this.hue, {this.big = false});
  final Shape shape;
  final Hue hue;
  final bool big;

  @override
  bool operator ==(Object other) => other is Token && other.shape == shape && other.hue == hue && other.big == big;

  @override
  int get hashCode => Object.hash(shape, hue, big);
}

enum Emotion { happy, sad, surprised, angry }

enum Act { sleeping, eating, jumping, waving }

enum Who { bear, bunny, fox, robot }

/// Something shown on a card or as the question: a picture, a group of
/// objects, a numeral, text, a face, a tower...
sealed class Visual {
  const Visual();
}

class PicVisual extends Visual {
  const PicVisual(this.pic);
  final Pic pic;
}

class GroupVisual extends Visual {
  const GroupVisual(this.pic, this.count, {this.scattered = false, this.seed = 0});
  final Pic pic;
  final int count;
  final bool scattered;
  final int seed;
}

class NumeralVisual extends Visual {
  const NumeralVisual(this.value);
  final int value;
}

class TextVisual extends Visual {
  const TextVisual(this.text, {this.isLetter = false});
  final String text;
  final bool isLetter;
}

class TokenVisual extends Visual {
  const TokenVisual(this.token);
  final Token token;
}

/// A row of tokens with the last place empty (repeating patterns).
class PatternVisual extends Visual {
  const PatternVisual(this.shown);
  final List<Token> shown;
}

/// Towers of blocks, one per step (growing patterns).
class TowersVisual extends Visual {
  const TowersVisual(this.heights, {this.withGap = true});
  final List<int> heights;
  final bool withGap;
}

class FaceVisual extends Visual {
  const FaceVisual(this.who, this.emotion);
  final Who who;
  final Emotion emotion;
}

class SceneVisual extends Visual {
  const SceneVisual(this.who, this.action, {this.prop});
  final Who who;
  final Act action;
  final Pic? prop;
}

// ---------------------------------------------------------------------------
// Trial kinds
// ---------------------------------------------------------------------------

/// Pick the one correct option. Covers compare, match, pattern, letters,
/// feelings, listening, vocabulary, rhyme, first sounds, blending, reading.
class ChoiceTrial extends Trial {
  const ChoiceTrial({
    required this.promptKey,
    this.promptArgs = const {},
    this.question,
    required this.options,
    required this.answer,
    this.speak,
    this.optionsAreBig = false,
  });

  /// Key into the app's prompt strings (ui/theme/prompts.dart).
  final String promptKey;
  final Map<String, String> promptArgs;
  final Visual? question;
  final List<Visual> options;
  final int answer;

  /// Text to read aloud (the word to find, the sentence to understand...).
  final String? speak;
  final bool optionsAreBig;

  bool isCorrect(int chosen) => chosen == answer;
}

/// Drag the requested number onto the plate (drag-to-count).
class DragCountTrial extends Trial {
  const DragCountTrial({required this.target, required this.item, required this.pile, this.distractor, this.distractorCount = 0});
  final int target;
  final Pic item;
  final int pile;
  final Pic? distractor;
  final int distractorCount;

  bool isCorrect(int placedTargets, int placedDistractors) => placedTargets == target && placedDistractors == 0;
}

/// Tap each object while counting, then choose how many (tap-to-count).
class TapCountTrial extends Trial {
  const TapCountTrial({required this.count, required this.pic, required this.scattered, required this.choices, required this.seed});
  final int count;
  final Pic pic;
  final bool scattered;
  final List<int> choices;
  final int seed;

  bool isCorrect(int chosen) => chosen == count;
}

/// Watch a group change, then choose how many now (join-separate).
class JoinSeparateTrial extends Trial {
  const JoinSeparateTrial({required this.start, required this.change, required this.pic, required this.hidden, required this.choices});
  final int start;

  /// Positive: items join. Negative: items leave.
  final int change;
  final Pic pic;

  /// Objects covered; only the number sentence is shown.
  final bool hidden;
  final List<int> choices;

  int get result => start + change;
  bool isCorrect(int chosen) => chosen == result;
}

/// Tap where a number goes on a line (number-line-place).
class NumberLineTrial extends Trial {
  const NumberLineTrial({required this.max, required this.target, required this.labelEvery, required this.tolerance});
  final int max;
  final int target;

  /// 1: every mark labelled; 5: every fifth; 0: only the ends.
  final int labelEvery;

  /// How far off still counts, in marks (only-ends lines allow 1).
  final int tolerance;

  bool isCorrect(int mark) => (mark - target).abs() <= tolerance;
}

enum SortRule { colour, shape }

/// Drop one card into the bin that matches it by the current rule
/// (sort-by-rule and switch-sort-rule).
class SortTrial extends Trial {
  const SortTrial({required this.card, required this.rule, required this.bins, required this.switched, this.bordered = false});
  final Token card;
  final SortRule rule;

  /// The two bin labels (a colour or a shape each).
  final List<Token> bins;

  /// True on the first card after the rule changed.
  final bool switched;

  /// Border cue: a bordered card is sorted by shape (rule_complexity 2).
  final bool bordered;

  int get answer {
    for (var i = 0; i < bins.length; i++) {
      final match = rule == SortRule.colour ? bins[i].hue == card.hue : bins[i].shape == card.shape;
      if (match) return i;
    }
    return 0;
  }

  bool isCorrect(int bin) => bin == answer;
}

/// Find all pairs on a board of face-down cards (match-pairs).
class PairsTrial extends Trial {
  const PairsTrial({required this.cards, required this.pairs});
  final List<Pic> cards;
  final int pairs;

  /// A board counts as correct when the child needed no more wrong turns
  /// than there are pairs -- guessing on first sight is expected.
  bool isCorrect(int wrongTurns) => wrongTurns <= pairs;
}

/// Watch lights flash in order, then repeat the order (sequence-recall).
class SequenceTrial extends Trial {
  const SequenceTrial({required this.pads, required this.sequence});
  final int pads;
  final List<int> sequence;

  bool isCorrect(List<int> response) {
    if (response.length != sequence.length) return false;
    for (var i = 0; i < sequence.length; i++) {
      if (response[i] != sequence[i]) return false;
    }
    return true;
  }
}

/// One item passing by: act on targets, hold back on the rest (go-no-go and
/// catch-target). Each item is its own trial.
class StreamItemTrial extends Trial {
  const StreamItemTrial({required this.visual, required this.isTarget, required this.showFor, this.targetLabel, this.theme = StreamTheme.sea});
  final Visual visual;
  final bool isTarget;
  final Duration showFor;
  final Visual? targetLabel;
  final StreamTheme theme;

  bool isCorrect({required bool tapped}) => tapped == isTarget;
}

enum StreamTheme { sea, balloons, bubbles }

/// Hear a word and tap a drum once per syllable (segment-sounds).
class ClapTrial extends Trial {
  const ClapTrial({required this.word});
  final Word word;

  bool isCorrect(int taps) => taps == word.parts.length;
}

/// Tap where reading starts, or tap the words in reading order (print-follow).
class PrintTrial extends Trial {
  const PrintTrial({required this.lines, required this.rtl, required this.startOnly});
  final List<List<String>> lines;
  final bool rtl;

  /// Only find where reading starts.
  final bool startOnly;

  /// Words in reading order, as (line, index-in-line) pairs.
  List<(int, int)> get order => [
    for (var l = 0; l < lines.length; l++)
      for (var i = 0; i < lines[l].length; i++) (l, i),
  ];

  bool isCorrect(List<(int, int)> taps) {
    final want = startOnly ? order.take(1).toList() : order;
    if (taps.length != want.length) return false;
    for (var i = 0; i < want.length; i++) {
      if (taps[i] != want[i]) return false;
    }
    return true;
  }
}

/// Drag letter tiles into slots to build the pictured word (build-word).
class BuildWordTrial extends Trial {
  const BuildWordTrial({required this.word, required this.tiles, required this.rtl});
  final Word word;
  final List<String> tiles;
  final bool rtl;

  /// Built with no wrong tile placed.
  bool isCorrect(int wrongPlacements) => wrongPlacements == 0;
}

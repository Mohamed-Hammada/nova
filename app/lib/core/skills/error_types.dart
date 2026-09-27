/// The vocabulary of meaningful, mechanic-specific signals a game can
/// report about a response (the curriculum's `error_type` signal: "category
/// of each error, defined per game, used for diagnosis").
///
/// Games report these explicitly from what actually happened in the round
/// -- how many items were placed, which option was picked, which rule the
/// card was sorted by. Nothing here is inferred from accuracy.
abstract final class ErrorType {
  /// More items than asked for (counting on past the number).
  static const overCount = 'over_count';

  /// Fewer items than asked for (stopping early).
  static const underCount = 'under_count';

  /// An item that is not the kind asked for (a pear among apples, a wrong
  /// letter tile).
  static const wrongObject = 'wrong_object';

  /// A wrong option of a choice round.
  static const distractorSelected = 'distractor_selected';

  /// A choice round where the smaller group was picked for "more" (or the
  /// bigger for "fewer").
  static const choseSmaller = 'chose_smaller';
  static const choseBigger = 'chose_bigger';

  /// An order not kept: a light sequence, reading order.
  static const sequenceBreak = 'sequence_break';

  /// A wrong answer given too fast to have been thought about, or acting on
  /// a "don't" item in a go/no-go stream.
  static const impulsiveResponse = 'impulsive_response';

  /// A target that went by without an answer.
  static const missedTarget = 'missed_target';

  /// Sorting by the old rule after the rule changed.
  static const rulePerseveration = 'rule_perseveration';

  /// The same error again on the next try of the same round.
  static const repeatedError = 'repeated_error';

  // Social choices (the communication-skills games). What a choice means, as
  // the story says -- never a judgement of the child.

  /// Giving up on a need or a friend silently (saying nothing, walking away).
  static const passiveResponse = 'passive_response';

  /// Grabbing, pushing, shouting or blaming.
  static const aggressiveResponse = 'aggressive_response';

  /// Words or actions that would hurt a friend's feelings (laughing at them).
  static const unkindResponse = 'unkind_response';

  /// Going on with one's own thing while a friend needs something.
  static const selfFocused = 'self_focused';

  // Support and self-monitoring: reported like errors, but they describe how
  // the child worked, not a mistake.

  /// The child asked for a hint.
  static const hintRequested = 'hint_requested';

  /// The child fixed their own mistake before submitting, unprompted (for
  /// now: took back an extra or wrong item before saying "done").
  static const selfCorrection = 'self_correction';

  /// A grown-up helped.
  static const adultAssist = 'adult_assist';

  /// Types that describe support or self-monitoring rather than a mistake.
  static const support = {hintRequested, selfCorrection, adultAssist};

  static bool isMistake(String type) => !support.contains(type);
}

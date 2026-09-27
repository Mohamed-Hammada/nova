import 'package:nova_app/core/skills/error_types.dart';

import 'lexicon.dart';
import 'trials.dart';

/// Short moments for the communication-skills games, in both launch
/// languages. Which skills they practise follows the ENDCORE model
/// (Fujimoto & Daibo, 2007) and what those skills look like at 2-8 follows
/// the preschool social-skill factors of Takahashi et al. (2008):
/// self-expression (stating needs clearly), self-restraint (waiting, taking
/// turns, handling conflict) and cooperation (helping, sharing, empathy).
///
/// Interim presentation data, like stories.dart: every line needs review by
/// an early-years specialist and a native Arabic educator, and recorded
/// narration. The Arabic uses the generic second person (the open decision on
/// gendered forms applies here too).

/// "Show how you feel": a moment that happens to the child, and the feeling
/// that fits it (practises expressivity -- showing a feeling on one's face).
class FeelingMoment {
  const FeelingMoment(this.emotion, this.en, this.ar, {this.prop});
  final Emotion emotion;
  final String en;
  final String ar;
  final Pic? prop;
}

const feelingMoments = [
  FeelingMoment(Emotion.sad, 'Your tower fell down.', 'سقط برجك.'),
  FeelingMoment(Emotion.happy, 'Grandma gave you a big hug.', 'حضنتك جدّتك حضنًا كبيرًا.'),
  FeelingMoment(Emotion.surprised, 'A frog jumped out of your shoe!', 'قفز ضفدع من حذائك!'),
  FeelingMoment(Emotion.angry, 'Someone took your toy without asking.', 'أخذ أحدهم لعبتك دون استئذان.', prop: Pic.ball),
  FeelingMoment(Emotion.happy, "It's your birthday party!", 'إنها حفلة عيد ميلادك!', prop: Pic.cake),
  FeelingMoment(Emotion.sad, 'Your balloon flew away.', 'طار بالونك بعيدًا.', prop: Pic.balloon),
  FeelingMoment(Emotion.surprised, 'A present popped open all by itself!', 'انفتحت الهدية وحدها فجأة!', prop: Pic.gift),
  FeelingMoment(Emotion.angry, 'Someone scribbled on your drawing on purpose.', 'شخبط أحدهم على رسمتك عمدًا.'),
];

/// One way of answering a social moment. [error] is what choosing it means
/// (ErrorType); null for the kind, clear, calm or fair way.
class SocialOption {
  const SocialOption(this.en, this.ar, [this.error]);
  final String en;
  final String ar;
  final String? error;
  String text(String language) => language == 'ar' ? ar : en;
}

/// A moment with one good way through it and two that are not.
class SocialMoment {
  const SocialMoment(this.who, this.emotion, this.en, this.ar, this.good, this.others, {this.prop});
  final Who who;
  final Emotion emotion;
  final String en;
  final String ar;
  final SocialOption good;
  final List<SocialOption> others;
  final Pic? prop;
  String story(String language) => language == 'ar' ? ar : en;
}

const _passive = ErrorType.passiveResponse;
const _aggressive = ErrorType.aggressiveResponse;
const _unkind = ErrorType.unkindResponse;
const _self = ErrorType.selfFocused;
const _impulsive = ErrorType.impulsiveResponse;

/// Assertion: saying what you need, clearly and kindly -- not silently
/// giving up, not grabbing or shouting.
const kindWordsMoments = [
  SocialMoment(Who.fox, Emotion.angry, 'A friend took your crayon.', 'أخذ صديقك قلم التلوين الخاص بك.',
      SocialOption('Say: "Can I have my crayon back, please?"', 'تقول: «هل تعيد لي قلمي من فضلك؟»'),
      [SocialOption('Say nothing and look sad.', 'لا تقول شيئًا وتحزن.', _passive), SocialOption('Grab it and shout "Mine!"', 'تخطفه وتصرخ: «لي!»', _aggressive)]),
  SocialMoment(Who.bunny, Emotion.sad, 'You want a turn on the swing.', 'تريد دورًا على الأرجوحة.',
      SocialOption('Say: "Can I have a turn after you?"', 'تقول: «هل آخذ دوري بعدك؟»'),
      [SocialOption('Walk away and never ask.', 'تبتعد ولا تطلب أبدًا.', _passive), SocialOption('Push your friend off.', 'تدفع صديقك عن الأرجوحة.', _aggressive)]),
  SocialMoment(Who.bear, Emotion.sad, "You can't open your lunch box.", 'لا تستطيع فتح علبة طعامك.',
      SocialOption('Say: "Can you help me open it, please?"', 'تقول: «هل تساعدني في فتحها من فضلك؟»'),
      [SocialOption('Stay hungry and say nothing.', 'تبقى جائعًا ولا تقول شيئًا.', _passive), SocialOption('Throw the box on the floor.', 'ترمي العلبة على الأرض.', _aggressive)]),
  SocialMoment(Who.robot, Emotion.sad, 'A friend asks you to play, but you are very tired.', 'يطلب صديقك أن تلعبا، لكنك متعب جدًا.',
      SocialOption('Say: "Not now, I\'m tired. Let\'s play later!"', 'تقول: «ليس الآن، أنا متعب. لنلعب لاحقًا!»'),
      [SocialOption('Play anyway and feel grumpy.', 'تلعب رغمًا عنك وأنت منزعج.', _passive), SocialOption('Shout: "Go away!"', 'تصرخ: «ابتعد عني!»', _aggressive)]),
  SocialMoment(Who.fox, Emotion.surprised, "You don't understand the rules of the game.", 'لم تفهم قواعد اللعبة.',
      SocialOption('Say: "Can you explain the rules again?"', 'تقول: «هل تشرح القواعد مرة أخرى؟»'),
      [SocialOption('Pretend you understand.', 'تتظاهر بأنك فهمت.', _passive), SocialOption('Kick the pieces away.', 'تبعثر القطع بقدمك.', _aggressive)]),
  SocialMoment(Who.bunny, Emotion.sad, "Someone is standing in front of you and you can't see the show.", 'يقف أحدهم أمامك فلا ترى العرض.',
      SocialOption('Say: "Excuse me, could you move a little, please?"', 'تقول: «عذرًا، هل تتحرك قليلًا من فضلك؟»'),
      [SocialOption('Miss the show and say nothing.', 'يفوتك العرض ولا تقول شيئًا.', _passive), SocialOption('Shove them aside.', 'تدفعه جانبًا.', _aggressive)]),
];

/// Other-acceptance: caring about how a friend feels, respecting what they
/// like -- not ignoring them, not being unkind.
const helpFriendMoments = [
  SocialMoment(Who.bunny, Emotion.sad, "Luna's ice cream fell on the floor.", 'وقع مثلّج لونا على الأرض.',
      SocialOption('Give her a hug and share yours.', 'تعانقها وتشاركها مثلّجك.'),
      [SocialOption('Keep eating your own ice cream.', 'تكمل أكل مثلّجك.', _self), SocialOption('Laugh at her.', 'تضحك عليها.', _unkind)]),
  SocialMoment(Who.fox, Emotion.sad, 'Pip fell and hurt his knee.', 'وقع بيب وجرح ركبته.',
      SocialOption('Ask "Are you okay?" and get a grown-up.', 'تسأله «هل أنت بخير؟» وتنادي أحد الكبار.'),
      [SocialOption('Keep on playing.', 'تكمل اللعب.', _self), SocialOption('Say: "That was funny!"', 'تقول: «كان ذلك مضحكًا!»', _unkind)]),
  SocialMoment(Who.bear, Emotion.happy, 'Bruno loves blue, but you love red.', 'برونو يحب الأزرق، وأنت تحب الأحمر.',
      SocialOption('Say: "Blue is nice too!"', 'تقول: «الأزرق جميل أيضًا!»'),
      [SocialOption('Only talk about red.', 'تتحدث عن الأحمر فقط.', _self), SocialOption('Say: "Blue is ugly."', 'تقول: «الأزرق قبيح.»', _unkind)]),
  SocialMoment(Who.robot, Emotion.sad, 'Orbit is new and plays alone.', 'أوربت جديد ويلعب وحده.',
      SocialOption('Say: "Do you want to play with us?"', 'تقول: «هل تريد أن تلعب معنا؟»'),
      [SocialOption('Keep playing without him.', 'تكمل اللعب من دونه.', _self), SocialOption('Say: "You can\'t play."', 'تقول: «لا يمكنك اللعب.»', _unkind)]),
  SocialMoment(Who.bunny, Emotion.surprised, 'Luna is scared of the dark.', 'لونا تخاف من الظلام.',
      SocialOption('Hold her hand and turn on a light.', 'تمسك يدها وتضيء المصباح.'),
      [SocialOption('Run ahead on your own.', 'تركض وحدك إلى الأمام.', _self), SocialOption('Say: "Scaredy-cat!"', 'تقول: «يا جبانة!»', _unkind)]),
  SocialMoment(Who.fox, Emotion.sad, "Pip's tower fell down.", 'سقط برج بيب.',
      SocialOption('Say: "Let\'s build it again together!"', 'تقول: «هيّا نبنيه معًا من جديد!»'),
      [SocialOption('Build your own tower instead.', 'تبني برجك أنت بدلًا منه.', _self), SocialOption('Knock down the rest.', 'توقع ما تبقّى منه.', _unkind)]),
];

/// Self-control: a calm way through a big feeling or a hard wait -- not
/// grabbing at once, not hitting or throwing.
const calmDownMoments = [
  SocialMoment(Who.bear, Emotion.angry, 'You feel very angry because you lost the game.', 'تشعر بغضب شديد لأنك خسرت اللعبة.',
      SocialOption('Take three slow breaths.', 'تأخذ ثلاثة أنفاس بطيئة.'),
      [SocialOption('Throw the game pieces.', 'ترمي قطع اللعبة.', _aggressive), SocialOption('Quit and stomp off.', 'تترك اللعب وتضرب الأرض بقدميك.', _impulsive)]),
  SocialMoment(Who.bunny, Emotion.happy, "You really want a cookie, but it's almost dinner.", 'تريد كعكة كثيرًا، لكن العشاء قريب.',
      SocialOption('Wait, and ask again after dinner.', 'تنتظر وتطلبها بعد العشاء.'),
      [SocialOption('Grab the cookie now.', 'تأخذ الكعكة الآن.', _impulsive), SocialOption('Shout and cry until you get it.', 'تصرخ وتبكي حتى تحصل عليها.', _aggressive)]),
  SocialMoment(Who.fox, Emotion.angry, 'Your brother is using the toy you want.', 'أخوك يلعب باللعبة التي تريدها.',
      SocialOption('Count to ten and wait for your turn.', 'تعدّ إلى عشرة وتنتظر دورك.'),
      [SocialOption('Grab the toy.', 'تخطف اللعبة.', _impulsive), SocialOption('Hit your brother.', 'تضرب أخاك.', _aggressive)]),
  SocialMoment(Who.robot, Emotion.angry, 'Your drawing went wrong and you feel cross.', 'لم تعجبك رسمتك وتشعر بالضيق.',
      SocialOption('Squeeze a pillow, then try again.', 'تضغط على وسادة ثم تحاول مرة أخرى.'),
      [SocialOption('Rip the paper.', 'تمزّق الورقة.', _aggressive), SocialOption('Scribble over everything.', 'تشخبط على كل شيء.', _impulsive)]),
  SocialMoment(Who.bunny, Emotion.surprised, "You feel wild and bouncy, but it's quiet time.", 'تشعر بحماس كبير، لكنه وقت الهدوء.',
      SocialOption('Hug a soft toy and breathe slowly.', 'تحضن لعبة طرية وتتنفس ببطء.'),
      [SocialOption('Jump on the bed.', 'تقفز على السرير.', _impulsive), SocialOption('Bang on the door.', 'تطرق الباب بقوة.', _aggressive)]),
  SocialMoment(Who.bear, Emotion.sad, 'Someone laughed at you and you feel upset.', 'ضحك عليك أحدهم فانزعجت.',
      SocialOption('Tell a grown-up how you feel.', 'تخبر أحد الكبار بما تشعر به.'),
      [SocialOption('Push them.', 'تدفعه.', _aggressive), SocialOption('Shout mean words.', 'تصرخ بكلمات قاسية.', _impulsive)]),
];

/// Relationship regulation: keeping a friendship good -- taking turns,
/// sharing, making up -- not taking over, not walking away from it.
const fairPlayMoments = [
  SocialMoment(Who.fox, Emotion.angry, 'You and a friend both want the red car.', 'أنت وصديقك تريدان السيارة الحمراء.',
      SocialOption('Take turns: you first, then me.', 'نتبادل الأدوار: أنت أولًا ثم أنا.'),
      [SocialOption('Pull it away from them.', 'تشدّها منه.', _aggressive), SocialOption('Stop playing for good.', 'تترك اللعب نهائيًا.', _passive)]),
  SocialMoment(Who.bear, Emotion.sad, 'You and Pip argued about the game.', 'تجادلت أنت وبيب حول اللعبة.',
      SocialOption('Say sorry and play together again.', 'تعتذر وتلعبان معًا من جديد.'),
      [SocialOption('Say: "I\'ll never play with you!"', 'تقول: «لن ألعب معك أبدًا!»', _aggressive), SocialOption('Ignore him all day.', 'تتجاهله طوال اليوم.', _passive)]),
  SocialMoment(Who.bunny, Emotion.happy, 'There is one cake and three friends.', 'هناك كعكة واحدة وثلاثة أصدقاء.',
      SocialOption('Cut it so everyone gets a piece.', 'نقطعها ليأخذ كل واحد قطعة.'),
      [SocialOption('Eat it all yourself.', 'تأكلها كلها وحدك.', _self), SocialOption('Hide it from them.', 'تخبئها عنهم.', _self)], prop: Pic.cake),
  SocialMoment(Who.robot, Emotion.surprised, 'Luna and Bruno want to play different games.', 'لونا وبرونو يريدان لعبتين مختلفتين.',
      SocialOption('Play one game, then the other.', 'نلعب لعبة ثم الأخرى.'),
      [SocialOption('Only play the game you like.', 'تلعب اللعبة التي تحبها فقط.', _self), SocialOption('Everyone goes home.', 'يعود الجميع إلى البيت.', _passive)]),
  SocialMoment(Who.fox, Emotion.surprised, 'You bumped into a friend by accident.', 'اصطدمت بصديقك دون قصد.',
      SocialOption('Say sorry and ask if they are okay.', 'تعتذر وتسأله إن كان بخير.'),
      [SocialOption('Pretend it did not happen.', 'تتظاهر بأن شيئًا لم يحدث.', _passive), SocialOption('Say it was their fault.', 'تقول إنه هو السبب.', _aggressive)]),
  SocialMoment(Who.bear, Emotion.sad, 'Your team lost the race.', 'خسر فريقك السباق.',
      SocialOption('Say "Good game!" to the other team.', 'تقول للفريق الآخر: «لعبة جميلة!»'),
      [SocialOption('Say they cheated.', 'تقول إنهم غشّوا.', _aggressive), SocialOption('Walk off without a word.', 'تذهب دون كلمة.', _passive)]),
];

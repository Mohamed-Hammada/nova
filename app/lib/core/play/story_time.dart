import 'lexicon.dart';
import 'trials.dart';

/// Picture stories for Story Time, in both launch languages. Each page is
/// read aloud and followed by one question of the kinds dialogic reading
/// uses (Mol et al., 2008): who, what happened, or finish the sentence.
/// The answer is a picture, so the child needs no reading.
///
/// Interim presentation data, like stories.dart: to be reviewed by an
/// early-years specialist and a native Arabic educator, with recorded
/// narration.
class StoryPage {
  const StoryPage({required this.who, required this.action, this.prop, required this.en, required this.ar, required this.askEn, required this.askAr, required this.answer, required this.others});
  final Who who;
  final Act action;
  final Pic? prop;

  /// The page, read aloud.
  final String en;
  final String ar;

  /// The question after it.
  final String askEn;
  final String askAr;

  /// The right picture, and pictures that could tempt a child who was not
  /// listening (things from other pages of the same story first).
  final Visual answer;
  final List<Visual> others;
}

class Story {
  const Story(this.pages);
  final List<StoryPage> pages;
}

const storyTimeStories = [
  Story([
    StoryPage(
      who: Who.bear, action: Act.waving, prop: Pic.ball,
      en: 'Bruno the bear found a red ball in the garden.', ar: 'وجد الدبّ برونو كرة حمراء في الحديقة.',
      askEn: 'What did Bruno find?', askAr: 'ماذا وجد برونو؟',
      answer: PicVisual(Pic.ball), others: [PicVisual(Pic.apple), PicVisual(Pic.book)],
    ),
    StoryPage(
      who: Who.bear, action: Act.jumping, prop: Pic.ball,
      en: 'He kicked the ball high, and it landed in a tree!', ar: 'ركل الكرة عاليًا، فوقعت فوق شجرة!',
      askEn: 'Who kicked the ball?', askAr: 'من ركل الكرة؟',
      answer: FaceVisual(Who.bear, Emotion.happy), others: [FaceVisual(Who.fox, Emotion.happy), FaceVisual(Who.bunny, Emotion.happy)],
    ),
    StoryPage(
      who: Who.bear, action: Act.waving, prop: Pic.bird,
      en: 'A kind bird pushed the ball down, and Bruno said thank you.', ar: 'دفع طائر لطيف الكرة إلى الأسفل، فقال برونو: شكرًا.',
      askEn: 'Finish it: a kind bird pushed down the ...', askAr: 'أكمل: دفع طائر لطيف ...',
      answer: PicVisual(Pic.ball), others: [PicVisual(Pic.star), PicVisual(Pic.flower)],
    ),
  ]),
  Story([
    StoryPage(
      who: Who.bunny, action: Act.eating, prop: Pic.carrot,
      en: 'Luna the bunny was eating a crunchy carrot.', ar: 'كانت الأرنبة لونا تأكل جزرة مقرمشة.',
      askEn: 'What was Luna eating?', askAr: 'ماذا كانت لونا تأكل؟',
      answer: PicVisual(Pic.carrot), others: [PicVisual(Pic.cake), PicVisual(Pic.apple)],
    ),
    StoryPage(
      who: Who.bunny, action: Act.sleeping,
      en: 'Then she felt sleepy and took a nap under the moon.', ar: 'ثم شعرت بالنعاس ونامت تحت القمر.',
      askEn: 'What did Luna see when she took a nap?', askAr: 'ماذا رأت لونا حين نامت؟',
      answer: PicVisual(Pic.moon), others: [PicVisual(Pic.carrot), PicVisual(Pic.ball)],
    ),
    StoryPage(
      who: Who.bunny, action: Act.waving,
      en: 'In the morning she woke up and waved to the sun.', ar: 'وفي الصباح استيقظت ولوّحت للشمس.',
      askEn: 'Who waved to the sun?', askAr: 'من لوّح للشمس؟',
      answer: FaceVisual(Who.bunny, Emotion.happy), others: [FaceVisual(Who.bear, Emotion.happy), FaceVisual(Who.robot, Emotion.happy)],
    ),
  ]),
  Story([
    StoryPage(
      who: Who.fox, action: Act.waving, prop: Pic.cake,
      en: "It was Pip's birthday, and there was a big cake.", ar: 'كان عيد ميلاد بيب، وكانت هناك كعكة كبيرة.',
      askEn: 'What was on the table?', askAr: 'ماذا كان على الطاولة؟',
      answer: PicVisual(Pic.cake), others: [PicVisual(Pic.fish), PicVisual(Pic.book)],
    ),
    StoryPage(
      who: Who.robot, action: Act.waving, prop: Pic.gift,
      en: 'Orbit the robot brought Pip a present.', ar: 'أحضر الروبوت أوربت هدية لبيب.',
      askEn: 'Who brought a present?', askAr: 'من أحضر الهدية؟',
      answer: FaceVisual(Who.robot, Emotion.happy), others: [FaceVisual(Who.bunny, Emotion.happy), FaceVisual(Who.bear, Emotion.happy)],
    ),
    StoryPage(
      who: Who.fox, action: Act.jumping, prop: Pic.balloon,
      en: 'Inside the present was a balloon, and Pip jumped for joy.', ar: 'كان داخل الهدية بالون، فقفز بيب من الفرح.',
      askEn: 'Finish it: inside the present was a ...', askAr: 'أكمل: كان داخل الهدية ...',
      answer: PicVisual(Pic.balloon), others: [PicVisual(Pic.cake), PicVisual(Pic.egg)],
    ),
  ]),
  Story([
    StoryPage(
      who: Who.robot, action: Act.waving, prop: Pic.fish,
      en: 'Orbit went to the lake and saw a little fish.', ar: 'ذهب أوربت إلى البحيرة ورأى سمكة صغيرة.',
      askEn: 'What did Orbit see in the lake?', askAr: 'ماذا رأى أوربت في البحيرة؟',
      answer: PicVisual(Pic.fish), others: [PicVisual(Pic.bird), PicVisual(Pic.star)],
    ),
    StoryPage(
      who: Who.robot, action: Act.eating, prop: Pic.apple,
      en: 'He sat on the grass and ate a green apple.', ar: 'جلس على العشب وأكل تفاحة خضراء.',
      askEn: 'What did Orbit eat?', askAr: 'ماذا أكل أوربت؟',
      answer: PicVisual(Pic.apple), others: [PicVisual(Pic.fish), PicVisual(Pic.carrot)],
    ),
    StoryPage(
      who: Who.fox, action: Act.waving, prop: Pic.book,
      en: 'His friend Pip came and read him a book.', ar: 'جاء صديقه بيب وقرأ له كتابًا.',
      askEn: 'Who read Orbit a book?', askAr: 'من قرأ لأوربت كتابًا؟',
      answer: FaceVisual(Who.fox, Emotion.happy), others: [FaceVisual(Who.bear, Emotion.happy), FaceVisual(Who.bunny, Emotion.happy)],
    ),
  ]),
];

import 'lexicon.dart';
import 'trials.dart';

/// Short situations for "How do they feel?", in both launch languages.
/// Interim presentation data, like lexicon.dart: to be reviewed by specialists
/// and moved into content packs with recorded narration.
class Situation {
  const Situation(this.who, this.prop, this.emotion, this.en, this.ar);
  final Who who;
  final Pic? prop;
  final Emotion emotion;
  final String en;
  final String ar;
}

const situations = [
  Situation(Who.fox, Pic.balloon, Emotion.sad, "Pip's balloon flew far away.", 'طار بالون بيب بعيدًا.'),
  Situation(Who.bunny, Pic.gift, Emotion.happy, 'Luna got a present from her friend.', 'حصلت لونا على هدية من صديقتها.'),
  Situation(Who.robot, Pic.gift, Emotion.surprised, 'A toy jumped out of the box at Orbit!', 'قفزت لعبة من الصندوق فجأة أمام أوربت!'),
  Situation(Who.bear, null, Emotion.angry, "Someone knocked down Bruno's tower on purpose.", 'أوقع أحدهم برج برونو عمدًا.'),
  Situation(Who.fox, Pic.cake, Emotion.happy, "It's Pip's birthday and there is cake!", 'إنه عيد ميلاد بيب وهناك كعكة!'),
  Situation(Who.bunny, Pic.egg, Emotion.sad, 'Luna dropped her egg and it broke.', 'أوقعت لونا بيضتها فانكسرت.'),
  Situation(Who.bear, Pic.star, Emotion.surprised, 'A shooting star flew right past Bruno!', 'مرّ نجم لامع أمام برونو فجأة!'),
  Situation(Who.robot, Pic.ball, Emotion.angry, "Someone took Orbit's ball without asking.", 'أخذ أحدهم كرة أوربت دون استئذان.'),
  Situation(Who.bear, Pic.book, Emotion.happy, 'Bruno found the book he lost.', 'وجد برونو الكتاب الذي أضاعه.'),
  Situation(Who.fox, null, Emotion.sad, "Pip's friend had to go home early.", 'اضطر صديق بيب للعودة إلى البيت مبكرًا.'),
];

String whoName(Who who, String language) => switch (who) {
      Who.bear => language == 'ar' ? 'الدبّ' : 'bear',
      Who.bunny => language == 'ar' ? 'الأرنب' : 'bunny',
      Who.fox => language == 'ar' ? 'الثعلب' : 'fox',
      Who.robot => language == 'ar' ? 'الروبوت' : 'robot',
    };

String emotionWord(Emotion e, String language) => switch (e) {
      Emotion.happy => language == 'ar' ? 'سعيد' : 'happy',
      Emotion.sad => language == 'ar' ? 'حزين' : 'sad',
      Emotion.surprised => language == 'ar' ? 'متفاجئ' : 'surprised',
      Emotion.angry => language == 'ar' ? 'غاضب' : 'angry',
    };

/// "The bear is sleeping." / "The fox has a ball. The fox is jumping."
String sceneSentence(SceneVisual s, String language) {
  final who = whoName(s.who, language);
  if (language == 'ar') {
    final action = switch (s.action) {
      Act.sleeping => '$who نائم.',
      Act.eating => '$who يأكل.',
      Act.jumping => '$who يقفز.',
      Act.waving => '$who يلوّح بيده.',
    };
    if (s.prop == null) return action;
    final thing = wordFor('ar', s.prop!)?.text ?? '';
    return 'مع $who $thing. $action';
  }
  final action = switch (s.action) {
    Act.sleeping => 'The $who is sleeping.',
    Act.eating => 'The $who is eating.',
    Act.jumping => 'The $who is jumping.',
    Act.waving => 'The $who is waving.',
  };
  if (s.prop == null) return action;
  final thing = wordFor('en', s.prop!)?.text ?? '';
  final article = 'aeiou'.contains(thing.isEmpty ? 'x' : thing[0]) ? 'an' : 'a';
  return 'The $who has $article $thing. $action';
}

/// Short printed lines for the print-direction game, word by word in
/// reading order.
List<List<String>> printLines(String language) => language == 'ar'
    ? const [
        ['أنا', 'أرى', 'قطة'],
        ['الشمس', 'حارة', 'جدًا'],
        ['نحن', 'نحب', 'اللعب'],
        ['القمر', 'جميل', 'الليلة'],
        ['أمي', 'تقرأ', 'كتابًا'],
        ['الطائر', 'يطير', 'عاليًا'],
      ]
    : const [
        ['I', 'see', 'a', 'cat'],
        ['The', 'sun', 'is', 'hot'],
        ['We', 'like', 'to', 'play'],
        ['Look', 'at', 'the', 'moon'],
        ['My', 'mum', 'reads', 'books'],
        ['The', 'bird', 'can', 'fly'],
      ];

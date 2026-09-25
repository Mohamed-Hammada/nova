import 'lexicon.dart';
import 'stories.dart';
import 'trials.dart';

/// Matches what a child said to one of a round's answer options.
///
/// Speech recognition returns text ("three", "3", "ثلاثة", "the bee"); each
/// option has the ways a child might name it. The first option any heard
/// word matches wins; if none or several match, the answer is ignored and
/// the child can tap instead. A voice answer is scored exactly like a tap.
int? matchSpoken(String heard, List<Visual> options, String language) {
  final words = _normalize(heard).split(' ').where((w) => w.isNotEmpty).toSet();
  if (words.isEmpty) return null;
  final phrase = _normalize(heard);
  final hits = <int>[];
  for (var i = 0; i < options.length; i++) {
    final names = spokenNames(options[i], language);
    if (names.any((n) => n.contains(' ') ? phrase.contains(n) : words.contains(n))) hits.add(i);
  }
  return hits.length == 1 ? hits.single : null;
}

/// Same, for a plain list of numbers (count and add/take-away answers).
int? matchSpokenNumber(String heard, List<int> choices, String language) {
  final i = matchSpoken(heard, [for (final c in choices) NumeralVisual(c)], language);
  return i == null ? null : choices[i];
}

/// Whether every option in a round can be named aloud.
bool canAnswerByVoice(List<Visual> options, String language) => options.every((o) => spokenNames(o, language).isNotEmpty);

/// Every way a child might name [v], normalized.
Set<String> spokenNames(Visual v, String language) {
  final ar = language == 'ar';
  final out = <String>{};
  switch (v) {
    case NumeralVisual(:final value):
      out.add('$value');
      out.add(_arabicDigits('$value'));
      if (value >= 0 && value < _enNumbers.length) out.add(_enNumbers[value]);
      if (value >= 0 && value < _arNumbers.length) out.addAll(_arNumbers[value]);
    case TextVisual(:final text, :final isLetter):
      final letter = text.replaceAll('ـ', '').trim();
      out.add(letter.toLowerCase());
      if (isLetter) {
        out.addAll(_enLetterNames[letter.toLowerCase()] ?? const []);
        final arName = _arLetterNames[letter];
        if (arName != null) out.add(arName);
      }
    case PicVisual(:final pic):
      final w = wordFor(language, pic)?.text;
      if (w != null) {
        out.add(w.toLowerCase());
        if (!ar) out.add('${w.toLowerCase()}s');
      }
      if (ar) {
        final en = wordFor('en', pic)?.text;
        if (en != null) out.add(en); // bilingual homes
      }
    case FaceVisual(:final emotion):
      out.add(emotionWord(emotion, language));
      out.addAll(ar ? _arEmotionExtra[emotion]! : _enEmotionExtra[emotion]!);
    default:
      break;
  }
  return {for (final n in out) _normalize(n)}..remove('');
}

String _arabicDigits(String s) => s.split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

/// Lower-case, strip punctuation and Arabic diacritics, unify alef/ta
/// marbuta forms, and read Eastern Arabic digits as Western ones too.
String _normalize(String s) {
  var t = s.toLowerCase().trim();
  t = t.replaceAll(RegExp('[ً-ْـ]'), ''); // harakat, tatweel
  t = t.replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي');
  t = t.replaceAll(RegExp(r'[.,!?؟،"]'), ' ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _enNumbers = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', //
  'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen', 'twenty',
];

const _arNumbers = [
  ['صفر'],
  ['واحد', 'واحدة'],
  ['اثنان', 'اثنين', 'اتنين'],
  ['ثلاثة', 'ثلاث', 'تلاتة'],
  ['أربعة', 'أربع'],
  ['خمسة', 'خمس'],
  ['ستة', 'ست'],
  ['سبعة', 'سبع'],
  ['ثمانية', 'ثماني', 'تمانية'],
  ['تسعة', 'تسع'],
  ['عشرة', 'عشر'],
  ['أحد عشر', 'احدعش'],
  ['اثنا عشر', 'اثني عشر', 'اتناشر'],
  ['ثلاثة عشر', 'تلتاشر'],
  ['أربعة عشر', 'اربعتاشر'],
  ['خمسة عشر', 'خمستاشر'],
  ['ستة عشر', 'ستاشر'],
  ['سبعة عشر', 'سبعتاشر'],
  ['ثمانية عشر', 'تمنتاشر'],
  ['تسعة عشر', 'تسعتاشر'],
  ['عشرون', 'عشرين'],
];

const _enLetterNames = <String, List<String>>{
  'a': ['ay', 'eh'],
  'b': ['bee', 'be'],
  'c': ['see', 'sea', 'cee'],
  'd': ['dee'],
  'e': ['ee'],
  'f': ['ef', 'eff'],
  'g': ['gee', 'jee'],
  'h': ['aitch', 'haitch'],
  'i': ['eye', 'aye'],
  'j': ['jay'],
  'k': ['kay', 'okay'],
  'l': ['el', 'elle'],
  'm': ['em'],
  'n': ['en'],
  'o': ['oh', 'owe'],
  'p': ['pee', 'pea'],
  'q': ['queue', 'cue', 'kew'],
  'r': ['are', 'ar'],
  's': ['es', 'ess'],
  't': ['tee', 'tea'],
  'u': ['you', 'yoo'],
  'v': ['vee'],
  'w': ['double you', 'doubleyou'],
  'x': ['ex'],
  'y': ['why', 'wye'],
  'z': ['zed', 'zee'],
};

const _arLetterNames = <String, String>{
  'ا': 'ألف',
  'ب': 'باء',
  'ت': 'تاء',
  'ث': 'ثاء',
  'ج': 'جيم',
  'ح': 'حاء',
  'خ': 'خاء',
  'د': 'دال',
  'ذ': 'ذال',
  'ر': 'راء',
  'ز': 'زاي',
  'س': 'سين',
  'ش': 'شين',
  'ص': 'صاد',
  'ض': 'ضاد',
  'ط': 'طاء',
  'ظ': 'ظاء',
  'ع': 'عين',
  'غ': 'غين',
  'ف': 'فاء',
  'ق': 'قاف',
  'ك': 'كاف',
  'ل': 'لام',
  'م': 'ميم',
  'ن': 'نون',
  'ه': 'هاء',
  'و': 'واو',
  'ي': 'ياء',
};

const _enEmotionExtra = {
  Emotion.happy: ['glad', 'smiling', 'smile'],
  Emotion.sad: ['crying', 'upset', 'unhappy'],
  Emotion.surprised: ['surprise', 'shocked', 'wow'],
  Emotion.angry: ['mad', 'cross', 'grumpy'],
};

const _arEmotionExtra = {
  Emotion.happy: ['سعيدة', 'فرحان', 'فرحانة', 'مبسوط'],
  Emotion.sad: ['حزينة', 'زعلان', 'زعلانة'],
  Emotion.surprised: ['متفاجئة', 'مندهش', 'مندهشة'],
  Emotion.angry: ['غاضبة', 'معصب', 'زعلان'],
};

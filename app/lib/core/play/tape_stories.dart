import 'trials.dart';

/// Story problems for Tape Stories (テープ図, Murata 2008), in both launch
/// languages. Each is drawn as one tape: two parts side by side under the
/// whole. Numbers stay within 10.
///
/// Arabic counts agree with their noun (١ تفاحة واحدة، تفاحتان، ٣-١٠ تفاحات):
/// [TapeNoun] holds the forms. Interim presentation data: to be reviewed by
/// a native Arabic educator.
class TapeNoun {
  const TapeNoun(this.en, this.enPlural, this.arOne, this.arTwo, this.arFew, {this.arFeminine = true});
  final String en;
  final String enPlural;
  final String arOne;
  final String arTwo;

  /// The plural used with 3 to 10.
  final String arFew;

  /// Grammatical gender of the Arabic noun (one and two agree with it; the
  /// plural of a thing takes a feminine verb whatever its gender).
  final bool arFeminine;

  /// The Arabic verb form for [n] of this noun as subject: [fem] or [masc].
  String arVerb(int n, String fem, String masc) => n >= 3 || arFeminine ? fem : masc;

  String count(int n, String language) {
    if (language != 'ar') return '$n ${n == 1 ? en : enPlural}';
    if (n == 1) return arOne;
    if (n == 2) return arTwo;
    return '${easternDigits(n)} $arFew';
  }
}

const tapeNouns = [
  TapeNoun('apple', 'apples', 'تفاحة واحدة', 'تفاحتان', 'تفاحات'),
  TapeNoun('fish', 'fish', 'سمكة واحدة', 'سمكتان', 'سمكات'),
  TapeNoun('balloon', 'balloons', 'بالون واحد', 'بالونان', 'بالونات', arFeminine: false),
  TapeNoun('star', 'stars', 'نجمة واحدة', 'نجمتان', 'نجوم'),
];

/// Eastern Arabic digits (١٢٣), as the app shows numbers in Arabic.
String easternDigits(int n) => '$n'.split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

/// Who the story is about: English name, Arabic name, character, and
/// whether Arabic verbs take the feminine form.
class TapeHero {
  const TapeHero(this.en, this.ar, this.who, {this.female = false});
  final String en;
  final String ar;
  final Who who;
  final bool female;
}

const tapeHeroes = [
  TapeHero('Pip', 'بيب', Who.fox),
  TapeHero('Luna', 'لونا', Who.bunny, female: true),
  TapeHero('Bruno', 'برونو', Who.bear),
  TapeHero('Orbit', 'أوربت', Who.robot),
];

/// A join story (the whole is missing): "Pip has 5 apples. Then 3 more
/// came. How many now?" Arabic keeps every count in the nominative, with the
/// verb agreeing (جاءته ثلاث... / جاءه بالونان).
String joinStory(String language, TapeHero h, TapeNoun noun, int a, int b) {
  if (language != 'ar') return '${h.en} has ${noun.count(a, 'en')}. Then $b more ${b == 1 ? noun.en : noun.enPlural} came. How many now?';
  final to = h.female ? 'ها' : 'ه';
  final came = noun.arVerb(b, 'جاءت$to', 'جاء$to');
  return 'لدى ${h.ar} ${noun.count(a, 'ar')}، ثم $came ${noun.count(b, 'ar')}. كم أصبح لدي$to الآن؟';
}

/// A take-away story (a part is missing): "Luna had 8 balloons. 3 went
/// away. How many are left?"
String separateStory(String language, TapeHero h, TapeNoun noun, int whole, int gone) {
  if (language != 'ar') return '${h.en} had ${noun.count(whole, 'en')}. ${noun.count(gone, 'en')} went away. How many are left?';
  final went = noun.arVerb(gone, 'ذهبت', 'ذهب');
  return 'كان لدى ${h.ar} ${noun.count(whole, 'ar')}، ثم $went منها ${noun.count(gone, 'ar')}. كم بقي؟';
}

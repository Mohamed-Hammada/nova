/// Pictures the app can draw, and the words, syllables and rhymes for them
/// in each launch language.
///
/// This is interim presentation data for the literacy and listening games:
/// it names only things the app can actually picture. Syllable splits and
/// rhyme groups are Nova's working choices (Modern Standard Arabic for
/// Arabic), to be reviewed by language specialists and moved into the
/// language packs under data/ when narration is recorded.
library;

enum Pic {
  apple, pear, carrot, radish, fish, shark, star, ball, flower, shell, heart, bird, gem, balloon,
  cat, hat, sun, moon, spoon, dish, tree, bee, boat, goat, duck, truck, car, cup, house, book, door,
  kite, cake, banana, tomato, watermelon, egg, drum, gift, net, bus, butterfly, bear, bunny, fox, robot,
}

class Word {
  const Word(this.pic, this.text, this.parts, {this.rhyme});
  final Pic pic;
  final String text;

  /// Syllables, in reading order.
  final List<String> parts;

  /// Words sharing a rhyme group rhyme with each other.
  final String? rhyme;

  /// The first letter as written (Arabic hamza forms kept).
  String get firstLetter => String.fromCharCode(text.runes.first);

  /// Letters, one per tile, in writing order.
  List<String> get letters => [for (final r in text.runes) String.fromCharCode(r)];
}

const _en = [
  Word(Pic.cat, 'cat', ['cat'], rhyme: 'at'),
  Word(Pic.hat, 'hat', ['hat'], rhyme: 'at'),
  Word(Pic.star, 'star', ['star'], rhyme: 'ar'),
  Word(Pic.car, 'car', ['car'], rhyme: 'ar'),
  Word(Pic.moon, 'moon', ['moon'], rhyme: 'oon'),
  Word(Pic.spoon, 'spoon', ['spoon'], rhyme: 'oon'),
  Word(Pic.fish, 'fish', ['fish'], rhyme: 'ish'),
  Word(Pic.dish, 'dish', ['dish'], rhyme: 'ish'),
  Word(Pic.tree, 'tree', ['tree'], rhyme: 'ee'),
  Word(Pic.bee, 'bee', ['bee'], rhyme: 'ee'),
  Word(Pic.boat, 'boat', ['boat'], rhyme: 'oat'),
  Word(Pic.goat, 'goat', ['goat'], rhyme: 'oat'),
  Word(Pic.duck, 'duck', ['duck'], rhyme: 'uck'),
  Word(Pic.truck, 'truck', ['truck'], rhyme: 'uck'),
  Word(Pic.sun, 'sun', ['sun']),
  Word(Pic.ball, 'ball', ['ball']),
  Word(Pic.cup, 'cup', ['cup']),
  Word(Pic.apple, 'apple', ['ap', 'ple']),
  Word(Pic.carrot, 'carrot', ['car', 'rot']),
  Word(Pic.flower, 'flower', ['flow', 'er']),
  Word(Pic.heart, 'heart', ['heart']),
  Word(Pic.shell, 'shell', ['shell']),
  Word(Pic.kite, 'kite', ['kite']),
  Word(Pic.bird, 'bird', ['bird']),
  Word(Pic.house, 'house', ['house']),
  Word(Pic.book, 'book', ['book']),
  Word(Pic.door, 'door', ['door']),
  Word(Pic.cake, 'cake', ['cake']),
  Word(Pic.banana, 'banana', ['ba', 'na', 'na']),
  Word(Pic.tomato, 'tomato', ['to', 'ma', 'to']),
  Word(Pic.watermelon, 'watermelon', ['wa', 'ter', 'mel', 'on']),
  Word(Pic.bear, 'bear', ['bear']),
  Word(Pic.bunny, 'bunny', ['bun', 'ny']),
  Word(Pic.robot, 'robot', ['ro', 'bot']),
  Word(Pic.butterfly, 'butterfly', ['but', 'ter', 'fly']),
  Word(Pic.egg, 'egg', ['egg']),
  Word(Pic.drum, 'drum', ['drum']),
  Word(Pic.gift, 'gift', ['gift']),
  Word(Pic.net, 'net', ['net']),
  Word(Pic.bus, 'bus', ['bus']),
  Word(Pic.balloon, 'balloon', ['bal', 'loon']),
];

const _ar = [
  Word(Pic.sun, 'شمس', ['شمس']),
  Word(Pic.moon, 'قمر', ['قَ', 'مَر']),
  Word(Pic.ball, 'كرة', ['كُ', 'رة'], rhyme: 'ra'),
  Word(Pic.tree, 'شجرة', ['شَ', 'جَ', 'رة'], rhyme: 'ra'),
  Word(Pic.car, 'سيارة', ['سَي', 'يا', 'رة'], rhyme: 'ra'),
  Word(Pic.fish, 'سمكة', ['سَ', 'مَ', 'كة'], rhyme: 'ka'),
  Word(Pic.net, 'شبكة', ['شَ', 'بَ', 'كة'], rhyme: 'ka'),
  Word(Pic.cat, 'قطة', ['قِط', 'طة'], rhyme: 'tta'),
  Word(Pic.duck, 'بطة', ['بَط', 'طة'], rhyme: 'tta'),
  Word(Pic.book, 'كتاب', ['كِ', 'تاب'], rhyme: 'ab'),
  Word(Pic.door, 'باب', ['باب'], rhyme: 'ab'),
  Word(Pic.apple, 'تفاحة', ['تُف', 'فا', 'حة']),
  Word(Pic.carrot, 'جزرة', ['جَ', 'زَ', 'رة']),
  Word(Pic.banana, 'موزة', ['مَو', 'زة']),
  Word(Pic.watermelon, 'بطيخة', ['بَط', 'طي', 'خة']),
  Word(Pic.tomato, 'طماطم', ['طَ', 'ما', 'طِم']),
  Word(Pic.bunny, 'أرنب', ['أر', 'نب']),
  Word(Pic.bear, 'دب', ['دب']),
  Word(Pic.robot, 'روبوت', ['رو', 'بوت']),
  Word(Pic.star, 'نجمة', ['نَج', 'مة']),
  Word(Pic.house, 'بيت', ['بيت']),
  Word(Pic.cup, 'كوب', ['كوب']),
  Word(Pic.hat, 'قبعة', ['قُب', 'بَ', 'عة']),
  Word(Pic.flower, 'وردة', ['وَر', 'دة']),
  Word(Pic.heart, 'قلب', ['قلب']),
  Word(Pic.bird, 'عصفور', ['عُص', 'فور']),
  Word(Pic.butterfly, 'فراشة', ['فَ', 'را', 'شة']),
  Word(Pic.drum, 'طبل', ['طبل']),
  Word(Pic.gift, 'هدية', ['هَ', 'دي', 'ية']),
  Word(Pic.egg, 'بيضة', ['بَي', 'ضة']),
  Word(Pic.boat, 'قارب', ['قا', 'رب']),
  Word(Pic.shell, 'صدفة', ['صَ', 'دَ', 'فة']),
  Word(Pic.balloon, 'بالون', ['با', 'لون']),
];

List<Word> lexicon(String language) => language == 'ar' ? _ar : _en;

Word? wordFor(String language, Pic pic) {
  for (final w in lexicon(language)) {
    if (w.pic == pic) return w;
  }
  return null;
}

/// Everyday words for the vocabulary game, very common first.
const commonPics = [Pic.ball, Pic.cup, Pic.apple, Pic.sun, Pic.cat, Pic.fish, Pic.house, Pic.book, Pic.car, Pic.tree, Pic.bird, Pic.moon];
const lessCommonPics = [Pic.shell, Pic.drum, Pic.butterfly, Pic.watermelon, Pic.net, Pic.boat, Pic.gift, Pic.tomato, Pic.egg, Pic.flower];

/// English capital letters whose small form looks the same, and letters
/// children commonly confuse.
const enLookAlikeCase = ['C', 'O', 'S', 'U', 'V', 'W', 'X', 'Z', 'K', 'P'];
const enConfusables = {'b': ['d', 'p', 'q'], 'd': ['b', 'p', 'q'], 'p': ['q', 'b', 'd'], 'q': ['p', 'b', 'd'], 'n': ['u', 'm'], 'u': ['n', 'v'], 'm': ['n', 'w'], 'w': ['m', 'v']};

/// Arabic letters that join on both sides, grouped by how much the joined
/// form changes. Letters that never join to the next one (ا د ذ ر ز و)
/// have no starting form and are left out.
const arStableForms = ['ب', 'ت', 'ث', 'ن', 'ي', 'س', 'ش', 'ف', 'ق', 'ل', 'م'];
const arChangingForms = ['ع', 'غ', 'ه', 'ك', 'ج', 'ح', 'خ', 'ص', 'ض', 'ط'];

/// Letters with the same body that differ only by dots.
const arDotFamilies = [
  ['ب', 'ت', 'ث', 'ن', 'ي'],
  ['ج', 'ح', 'خ'],
  ['س', 'ش'],
  ['ص', 'ض'],
  ['ع', 'غ'],
  ['ف', 'ق'],
];

/// The joined, word-start form of an Arabic letter (a following tatweel
/// makes every text shaper draw the initial form).
String arInitial(String letter) => '$letterـ';

/// A letter's family of look-alikes, or null.
List<String>? arDotFamily(String letter) {
  for (final f in arDotFamilies) {
    if (f.contains(letter)) return f;
  }
  return null;
}

/// What the guide character says for each kind of round, in both launch
/// languages. `{name}` placeholders are filled from the trial's arguments.
const _prompts = <String, (String, String)>{
  'match_number': ('Find the group with {n}.', 'ابحث عن المجموعة التي فيها {n}.'),
  'pick_more': ('Which one has more?', 'أيّها فيه أكثر؟'),
  'pick_fewer': ('Which one has fewer?', 'أيّها فيه أقل؟'),
  'what_next': ('What comes next?', 'ماذا يأتي بعد ذلك؟'),
  'what_next_tower': ('Which tower comes next?', 'أي برج يأتي بعد ذلك؟'),
  'same_feeling': ('Who feels the same?', 'من يشعر بالشعور نفسه؟'),
  'how_feel': ('{story} How do they feel?', '{story} بماذا يشعر؟'),
  'listen_find': ('Listen, then find the picture.', 'استمع، ثم ابحث عن الصورة.'),
  'find_word': ('Find the {word}.', 'ابحث عن: {word}'),
  'rhyme': ('What rhymes with {word}?', 'ما الذي يتّفق في القافية مع {word}؟'),
  'first_letter': ('Which letter does {word} start with?', 'بأي حرف تبدأ كلمة {word}؟'),
  'blend': ('{parts}... What word is it?', '{parts}... ما هي الكلمة؟'),
  'read_find': ('Read the word, then find its picture.', 'اقرأ الكلمة، ثم ابحث عن صورتها.'),
  'letter_small': ('Find the small letter for {letter}.', 'ابحث عن الحرف الصغير للحرف {letter}.'),
  'letter_joined': ('Find {letter} at the start of a word.', 'ابحث عن الحرف {letter} في أول الكلمة.'),
  'drag_count': ('Give {name} {n} {thing}!', 'أعطِ {name} {n} ({thing})!'),
  'tap_count': ('Tap each one to count, then choose how many.', 'المس كل واحدة لتعدّها، ثم اختر كم عددها.'),
  'join': ('Watch the nest. How many now?', 'راقب جيدًا. كم العدد الآن؟'),
  'number_line': ('Where does {n} go? Tap the line.', 'أين يقع العدد {n}؟ المس الخط.'),
  'sort_colour': ('Sort by colour!', 'صنّف حسب اللون!'),
  'sort_shape': ('Sort by shape!', 'صنّف حسب الشكل!'),
  'sort_border': ('Gold border: sort by shape. No border: by colour.', 'إطار ذهبي: حسب الشكل. بلا إطار: حسب اللون.'),
  'new_rule': ('New rule!', 'قاعدة جديدة!'),
  'pairs': ('Find the matching pairs.', 'ابحث عن الأزواج المتطابقة.'),
  'simon_watch': ('Watch the lights...', 'راقب الأضواء...'),
  'simon_go': ('Now you! Tap them in the same order.', 'دورك الآن! المسها بالترتيب نفسه.'),
  'feed_fish': ('Tap to feed the fish. Wait when a shark comes!', 'المس لتطعم السمك. انتظر إذا جاء القرش!'),
  'catch': ('Catch every one that matches!', 'التقط كل ما يطابق!'),
  'clap': ('Tap the drum once for each part of the word.', 'اضرب الطبل مرة لكل مقطع في الكلمة.'),
  'print_start': ('Tap where the reading starts.', 'المس المكان الذي تبدأ منه القراءة.'),
  'print_follow': ('Tap the words in reading order.', 'المس الكلمات بترتيب القراءة.'),
  'build': ('Build the word for the picture.', 'ركّب كلمة الصورة.'),
  'done': ('Done', 'تم'),
};

String prompt(String key, String language, [Map<String, String> args = const {}]) {
  final entry = _prompts[key];
  var text = entry == null ? key : (language == 'ar' ? entry.$2 : entry.$1);
  args.forEach((k, v) => text = text.replaceAll('{$k}', v));
  return text;
}

import 'package:flutter/widgets.dart';

import 'age_band.dart';

/// Interface wording for the two launch languages. Curriculum text (game
/// names, skill names, hints) still comes from the content bundle's i18n;
/// this is only the app's own chrome.
class UiStrings {
  const UiStrings._(this.language);
  final String language;

  static const en = UiStrings._('en');
  static const ar = UiStrings._('ar');

  static UiStrings of(String language) => language == 'ar' ? ar : en;

  bool get isRtl => language == 'ar';
  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  String _t(String en, String ar) => language == 'ar' ? ar : en;

  String get appName => _t('Nova', 'نوفا');
  String greeting(String name) => _t("Hi! I'm $name!", 'مرحبًا! أنا $name!');
  String get letsPlay => _t("Let's play!", 'هيا نلعب!');
  String get pickYourAge => _t('How old are you?', 'كم عمرك؟');
  String get pickYourAgeSub => _t('Pick a friend to play with', 'اختر صديقًا لتلعب معه');
  String ageYears(AgeBand band) => _t('${band.ageLabel} years', '${band.ageLabel} سنوات');
  String bandTitle(AgeBand band) => switch (band) {
    AgeBand.tiny => _t('Little Stars', 'النجوم الصغيرة'),
    AgeBand.explorer => _t('Explorers', 'المستكشفون'),
    AgeBand.champion => _t('Champions', 'الأبطال'),
  };
  String get comingSoon => _t('Coming soon', 'قريبًا');
  String get play => _t('Play', 'العب');
  String get grownUps => _t('Grown-ups', 'للكبار');
  String get holdToOpen => _t('Hold to open', 'اضغط مطولًا للفتح');
  String giveApples(int n) => _t(n == 1 ? 'Give Bruno 1 apple!' : 'Give Bruno $n apples!', n == 1 ? 'أعطِ برونو تفاحة واحدة!' : 'أعطِ برونو $n تفاحات!');
  String get dragHint => _t('Drag an apple onto the plate', 'اسحب تفاحة إلى الطبق');
  String get yum => _t('Yum!', 'لذيذ!');
  String get greatJob => _t('Amazing!', 'رائع!');
  String get tryAgainSoon => _t('Nice try!', 'محاولة جميلة!');
  String get progressTitle => _t('Progress', 'التقدّم');
  String get skillProgress => _t('Skill progress', 'تقدّم المهارة');
  String get notDiagnosis => _t('This is an early estimate, not a diagnosis.', 'هذا تقدير مبدئي، وليس تشخيصًا.');
  String masteryLabel(String? state) => switch (state) {
    null => _t('Not yet', 'ليس بعد'),
    'emerging' => _t('Emerging', 'ناشئة'),
    'developing' => _t('Developing', 'في تطوّر'),
    'secure' => _t('Secure', 'متمكّنة'),
    'transfer' => _t('Transfer', 'انتقال'),
    _ => _t('Unknown', 'غير معروف'),
  };
  String get masteryHelp => _t(
    'Skills grow through five steps: not yet, emerging, developing, secure, and transfer to new situations.',
    'تنمو المهارات عبر خمس مراحل: ليس بعد، ناشئة، في تطوّر، متمكّنة، ثم الانتقال إلى مواقف جديدة.',
  );
  String get noSkillsYet => _t('Play a game to see progress here.', 'العب لعبة لترى التقدّم هنا.');
  String get home => _t('Home', 'الرئيسية');
  String get playAgain => _t('Play again', 'العب مرة أخرى');
}

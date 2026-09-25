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

  static String _digits(int n) => '$n'.split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

  String get appName => _t('Nova', 'نوفا');
  String greetingNamed(String child, String name) => _t('Hi $child! I\'m $name!', 'مرحبًا يا $child! أنا $name!');
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
  String levelLabel(int n) => _t('Level $n', 'المستوى ${_digits(n)}');
  String get levelDone => _t('Level complete!', 'أنهيت المستوى!');
  String get backToMap => _t('Map', 'الخريطة');
  String get journey => _t('My Journey', 'رحلتي');
  String get journeySub => _t('50 levels to explore', '٥٠ مستوى للاستكشاف');
  String get freePlay => _t('Free play', 'لعب حر');
  String chapter(int n) => _t('Chapter $n', 'الفصل ${_digits(n)}');
  String starsCount(int n, int of) => _t('$n of $of stars', '${_digits(n)} من ${_digits(of)} نجمة');
  String get settings => _t('Settings', 'الإعدادات');
  String get spokenPrompts => _t('Spoken instructions', 'التعليمات المسموعة');
  String get spokenPromptsSub => _t('The characters read every instruction aloud.', 'تقرأ الشخصيات كل تعليمة بصوت عالٍ.');
  String get voiceAnswers => _t('Answer by voice (microphone)', 'الإجابة بالصوت (الميكروفون)');
  String get voiceAnswersSub => _t(
    'Your child can say answers out loud. Speech is recognised on this device only; nothing is recorded or sent.',
    'يمكن لطفلك قول الإجابات بصوت عالٍ. يُتعرّف على الكلام على هذا الجهاز فقط؛ لا يُسجَّل أو يُرسَل أي شيء.',
  );
  String get cameraPlay => _t('Face play (camera)', 'اللعب بالوجه (الكاميرا)');
  String get cameraPlaySub => _t(
    'The characters can see your child smile, look around and play peekaboo. Faces are processed on this device only; no picture is saved or sent.',
    'تستطيع الشخصيات رؤية ابتسامة طفلك واللعب معه. تُعالج الوجوه على هذا الجهاز فقط؛ لا تُحفظ أي صورة ولا تُرسَل.',
  );
  String get notOnThisDevice => _t('Not available on this device.', 'غير متاح على هذا الجهاز.');
  String get permissionDenied => _t('Permission was not given. You can allow it in the device settings.', 'لم يُمنح الإذن. يمكنك السماح به من إعدادات الجهاز.');
  String get sayIt => _t('Say it!', 'قلها!');
  String get listening => _t('Listening...', 'أستمع...');
  String get aboutMe => _t('About me', 'عنّي');
  String get myName => _t('My name', 'اسمي');
  String get typeName => _t('Type your name', 'اكتب اسمك');
  String get howOld => _t('How old am I?', 'كم عمري؟');
  String get myFriend => _t('My friend', 'صديقي');
  String get myWorld => _t('My world', 'عالمي');
  String get automatic => _t('Auto', 'تلقائي');
  String get languageLabel => _t('Language', 'اللغة');
  String worldName(WorldKind w) => switch (w) {
        WorldKind.candyMeadow => _t('Candy Meadow', 'مرج الحلوى'),
        WorldKind.sunnyForest => _t('Sunny Forest', 'الغابة المشمسة'),
        WorldKind.cosmicLab => _t('Space Lab', 'مختبر الفضاء'),
      };
  String get graphics => _t('Graphics quality', 'جودة الرسوم');
  String graphicsName(String q) => switch (q) {
        'low' => _t('Low', 'منخفضة'),
        'balanced' => _t('Balanced', 'متوازنة'),
        _ => _t('High', 'عالية'),
      };
  String graphicsHelp(String q) => switch (q) {
        'low' => _t('Still backgrounds and simpler lighting. Best for older phones and longer battery.', 'خلفيات ثابتة وإضاءة أبسط. الأفضل للهواتف القديمة ولتوفير البطارية.'),
        'balanced' => _t('Moving worlds with fewer effects.', 'عوالم متحركة بمؤثرات أقل.'),
        _ => _t('Full lighting, light rays and particles.', 'إضاءة كاملة وأشعة وجزيئات.'),
      };
  String get home => _t('Home', 'الرئيسية');
  String get playAgain => _t('Play again', 'العب مرة أخرى');
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نوفا';

  @override
  String get homeGreeting => 'هيّا نلعب!';

  @override
  String get homeSubtitle => 'اختر لعبة لتبدأ.';

  @override
  String get playGame => 'العب';

  @override
  String get grownUps => 'للكبار';

  @override
  String get languageMenuTooltip => 'تغيير اللغة';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get loadingMessage => 'نستعدّ…';

  @override
  String get errorTitle => 'حدث خطأ ما';

  @override
  String get errorContentUnavailable => 'تعذّر تحميل الألعاب على هذا الجهاز.';

  @override
  String get errorGameUnavailable => 'تعذّر بدء هذه اللعبة.';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String get emptyGamesTitle => 'لا توجد ألعاب بعد';

  @override
  String get emptyGamesBody => 'ستظهر الألعاب هنا عندما تصبح جاهزة.';

  @override
  String get leaveGame => 'العودة إلى الألعاب';

  @override
  String gamePrompt(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أعطِ الدبّ $countText تفاحة',
      many: 'أعطِ الدبّ $countText تفاحة',
      few: 'أعطِ الدبّ $countText تفاحات',
      two: 'أعطِ الدبّ تفاحتين',
      one: 'أعطِ الدبّ تفاحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get gameHowTo => 'اسحب التفاحات إلى الصحن، أو المسها.';

  @override
  String get done => 'انتهيت';

  @override
  String get hint => 'ساعدني في العدّ';

  @override
  String hintOnPlate(String countText) {
    return 'في الصحن $countText';
  }

  @override
  String trialProgress(String current, String total) {
    return 'السؤال $current من $total';
  }

  @override
  String get feedbackCorrect => 'صحيح تمامًا! الدبّ سعيد.';

  @override
  String get feedbackTryAgain => 'ليس تمامًا. هيّا نعدّ مرة أخرى.';

  @override
  String get feedbackOnlyApples => 'الدبّ يريد التفاح فقط.';

  @override
  String get feedbackMoveOn => 'محاولة جيدة! هيّا إلى السؤال التالي.';

  @override
  String get next => 'التالي';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get saving => 'جارٍ الحفظ…';

  @override
  String get saveFailed => 'تعذّر حفظ التقدّم.';

  @override
  String get sessionCompleteTitle => 'انتهينا!';

  @override
  String get sessionCompleteBody => 'لقد ساعدت الدبّ. أحسنت!';

  @override
  String get playAgain => 'العب مرة أخرى';

  @override
  String get backHome => 'الرئيسية';

  @override
  String get itemApple => 'تفاحة';

  @override
  String get itemPear => 'كمثرى';

  @override
  String get itemGiveHint => 'أعطِها للدبّ';

  @override
  String get itemOnPlateApple => 'تفاحة في الصحن';

  @override
  String get itemOnPlatePear => 'كمثرى في الصحن';

  @override
  String get itemTakeBackHint => 'أعِدها';

  @override
  String get plateLabel => 'صحن الدبّ';

  @override
  String get plateEmpty => 'الصحن فارغ';

  @override
  String get pileLabel => 'الفاكهة على الطاولة';

  @override
  String get bearLabel => 'الدبّ';

  @override
  String get progressTitle => 'التقدّم';

  @override
  String get progressIntro => 'ما لاحظته الألعاب حتى الآن، مهارةً مهارة.';

  @override
  String get progressDisclaimer => 'هذا تقدير مبدئي، وليس تشخيصًا.';

  @override
  String get progressLoadFailed => 'تعذّر تحميل التقدّم.';

  @override
  String get masteryNotYet => 'ليس بعد';

  @override
  String get masteryEmerging => 'في البداية';

  @override
  String get masteryDeveloping => 'في تطوّر';

  @override
  String get masterySecure => 'راسخة';

  @override
  String get masteryTransfer => 'منقولة';

  @override
  String get masteryNotYetDescription => 'لم يُلعب بما يكفي للحكم بعد.';

  @override
  String get masteryEmergingDescription =>
      'بدأت المهارة تظهر، غالبًا مع مساعدة.';

  @override
  String get masteryDevelopingDescription =>
      'ينجح كثيرًا، وما زال يبني الثبات.';

  @override
  String get masterySecureDescription => 'ينجح بثبات ومن دون مساعدة.';

  @override
  String get masteryTransferDescription =>
      'يستخدم المهارة خارج هذه اللعبة أيضًا.';

  @override
  String masteryStepOf(String current, String total) {
    return 'المرحلة $current من $total';
  }

  @override
  String get graphicsQuality => 'جودة الرسوميات';

  @override
  String get graphicsAuto => 'تلقائي (موصى به)';

  @override
  String get graphicsAutoDesc => 'يتكيف تلقائياً مع قدرات الجهاز';

  @override
  String get graphicsHigh => 'عالية';

  @override
  String get graphicsHighDesc => 'أفضل مؤثرات ثلاثية الأبعاد وظلال ناعمة';

  @override
  String get graphicsMedium => 'متوسطة';

  @override
  String get graphicsMediumDesc => 'أداء ورسوميات متوازنة';

  @override
  String get graphicsLow => 'منخفضة';

  @override
  String get graphicsLowDesc => 'مناسبة للأجهزة البسيطة';

  @override
  String get graphics2D => 'الوضع ثنائي الأبعاد';

  @override
  String get graphics2DDesc => 'رسومات ثنائية الأبعاد، توفر البطارية';

  @override
  String get close => 'إغلاق';

  @override
  String greeting(String name) {
    return 'مرحبًا! أنا $name!';
  }

  @override
  String greetingNamed(String child, String name) {
    return 'مرحبًا يا $child! أنا $name!';
  }

  @override
  String get bandTiny => 'النجوم الصغيرة';

  @override
  String get bandExplorer => 'المستكشفون';

  @override
  String get bandChampion => 'الأبطال';

  @override
  String ageYears(String range) {
    return '$range سنوات';
  }

  @override
  String levelLabel(String number) {
    return 'المستوى $number';
  }

  @override
  String get levelDone => 'أنهيت المستوى!';

  @override
  String get backToMap => 'الخريطة';

  @override
  String get journeyTitle => 'رحلتي';

  @override
  String journeySubtitle(String count) {
    return '$count مستوى للاستكشاف';
  }

  @override
  String chapter(String number) {
    return 'الفصل $number';
  }

  @override
  String starsCount(String count, String total) {
    return '$count من $total نجمة';
  }

  @override
  String get moreGames => 'ألعاب أخرى';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get spokenPrompts => 'التعليمات المسموعة';

  @override
  String get spokenPromptsDesc => 'تقرأ الشخصيات كل تعليمة بصوت عالٍ.';

  @override
  String get voiceAnswers => 'الإجابة بالصوت (الميكروفون)';

  @override
  String get voiceAnswersDesc =>
      'يمكن لطفلك قول الإجابات بصوت عالٍ. يُتعرّف على الكلام على هذا الجهاز فقط؛ لا يُسجَّل أو يُرسَل أي شيء.';

  @override
  String get cameraPlay => 'اللعب بالوجه (الكاميرا)';

  @override
  String get cameraPlayDesc =>
      'تستطيع الشخصيات رؤية ابتسامة طفلك واللعب معه. تُعالج الوجوه على هذا الجهاز فقط؛ لا تُحفظ أي صورة ولا تُرسَل.';

  @override
  String get notOnThisDevice => 'غير متاح على هذا الجهاز.';

  @override
  String get permissionDenied =>
      'لم يُمنح الإذن. يمكنك السماح به من إعدادات الجهاز.';

  @override
  String get didntCatch => 'لم أسمع جيدًا. قلها مرة أخرى أو المس!';

  @override
  String get sayIt => 'قلها!';

  @override
  String get listening => 'أستمع…';

  @override
  String get aboutMe => 'عنّي';

  @override
  String get myName => 'اسمي';

  @override
  String get typeName => 'اكتب اسمك';

  @override
  String get howOld => 'كم عمري؟';

  @override
  String get myFriend => 'صديقي';

  @override
  String get myWorld => 'عالمي';

  @override
  String get automatic => 'تلقائي';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get worldCandyMeadow => 'مرج الحلوى';

  @override
  String get worldSunnyForest => 'الغابة المشمسة';

  @override
  String get worldSpaceLab => 'مختبر الفضاء';

  @override
  String get greatJob => 'رائع!';

  @override
  String get niceTry => 'محاولة جميلة!';

  @override
  String get repeatInstruction => 'أعد التعليمة';

  @override
  String get closeLevel => 'اخرج من المستوى';

  @override
  String levelLocked(String number) {
    return 'المستوى $number، مقفل';
  }

  @override
  String levelOpen(String number) {
    return 'المستوى $number';
  }

  @override
  String promptMatchNumber(String n) {
    return 'ابحث عن المجموعة التي فيها $n.';
  }

  @override
  String get promptPickMore => 'أيّها فيه أكثر؟';

  @override
  String get promptPickFewer => 'أيّها فيه أقل؟';

  @override
  String get promptWhatNext => 'ماذا يأتي بعد ذلك؟';

  @override
  String get promptWhatNextTower => 'أي برج يأتي بعد ذلك؟';

  @override
  String get promptSameFeeling => 'من يشعر بالشعور نفسه؟';

  @override
  String promptHowFeel(String story) {
    return '$story بماذا يشعر؟';
  }

  @override
  String get promptListenFind => 'استمع، ثم ابحث عن الصورة.';

  @override
  String promptFindWord(String word) {
    return 'ابحث عن: $word';
  }

  @override
  String promptRhyme(String word) {
    return 'ما الذي يتّفق في القافية مع $word؟';
  }

  @override
  String promptFirstLetter(String word) {
    return 'بأي حرف تبدأ كلمة $word؟';
  }

  @override
  String promptBlend(String parts) {
    return '$parts… ما هي الكلمة؟';
  }

  @override
  String get promptReadFind => 'اقرأ الكلمة، ثم ابحث عن صورتها.';

  @override
  String promptLetterSmall(String letter) {
    return 'ابحث عن الحرف الصغير للحرف $letter.';
  }

  @override
  String promptLetterJoined(String letter) {
    return 'ابحث عن الحرف $letter في أول الكلمة.';
  }

  @override
  String promptDragCount(String name, String n, String thing) {
    return 'أعطِ $name $n ($thing)!';
  }

  @override
  String get promptTapCount => 'المس كل واحدة لتعدّها، ثم اختر كم عددها.';

  @override
  String get promptJoin => 'راقب جيدًا. كم العدد الآن؟';

  @override
  String promptNumberLine(String n) {
    return 'أين يقع العدد $n؟ المس الخط.';
  }

  @override
  String get promptSortColour => 'صنّف حسب اللون!';

  @override
  String get promptSortShape => 'صنّف حسب الشكل!';

  @override
  String get promptSortBorder => 'إطار ذهبي: حسب الشكل. بلا إطار: حسب اللون.';

  @override
  String get promptNewRule => 'قاعدة جديدة!';

  @override
  String get promptPairs => 'ابحث عن الأزواج المتطابقة.';

  @override
  String get promptSimonWatch => 'راقب الأضواء…';

  @override
  String get promptSimonGo => 'دورك الآن! المسها بالترتيب نفسه.';

  @override
  String get promptFeedFish => 'المس لتطعم السمك. انتظر إذا جاء القرش!';

  @override
  String get promptCatch => 'التقط كل ما يطابق!';

  @override
  String get promptClap => 'اضرب الطبل مرة لكل مقطع في الكلمة.';

  @override
  String get promptPrintStart => 'المس المكان الذي تبدأ منه القراءة.';

  @override
  String get promptPrintFollow => 'المس الكلمات بترتيب القراءة.';

  @override
  String get promptBuild => 'ركّب كلمة الصورة.';

  @override
  String welcomeBack(String name) {
    return 'أهلًا بعودتك يا $name!';
  }

  @override
  String get welcomeBackNoName => 'أهلًا بعودتك!';

  @override
  String get letsExplore => 'هيّا نستكشف معًا.';

  @override
  String companionHello(String name) {
    return 'أنا $name. إلى أين نذهب اليوم؟';
  }

  @override
  String get continueJourney => 'تابع رحلتك';

  @override
  String get startJourney => 'ابدأ رحلتك';

  @override
  String get placesToExplore => 'أماكن نستكشفها';

  @override
  String activitiesCount(String count) {
    return 'الأنشطة: $count';
  }

  @override
  String get myTreasures => 'كنوزي';

  @override
  String starsCollected(String count) {
    return 'النجوم: $count';
  }

  @override
  String levelsExplored(String count) {
    return 'المستويات المكتملة: $count';
  }

  @override
  String get badgeFirstSteps => 'الخطوة الأولى';

  @override
  String get badgeStarCatcher => 'صائد النجوم';

  @override
  String get badgeExplorer => 'المستكشف الكبير';

  @override
  String get badgeLocked => 'واصل اللعب لتفتح هذه';

  @override
  String get catNumbers => 'مرج الأرقام';

  @override
  String get catLanguage => 'غابة الحكايات';

  @override
  String get catSounds => 'وادي الأصوات';

  @override
  String get catFeelings => 'حديقة المشاعر';

  @override
  String get catMemory => 'خليج الذاكرة';

  @override
  String get catDiscovery => 'تلّ الاكتشاف';

  @override
  String get catMovement => 'بركة الحركة';

  @override
  String get catNumbersTag => 'نعدّ ونقارن ونكتشف الأنماط';

  @override
  String get catLanguageTag => 'كلمات وحروف وحكايات';

  @override
  String get catSoundsTag => 'قوافٍ وإيقاعات وأصوات';

  @override
  String get catFeelingsTag => 'نفهم مشاعر أصدقائنا';

  @override
  String get catMemoryTag => 'نتذكّر ونطابق ونكرّر';

  @override
  String get catDiscoveryTag => 'نصنّف ونبدّل ونفكّر';

  @override
  String get catMovementTag => 'عيون سريعة وأيادٍ حذرة';

  @override
  String get newActivity => 'جديد';

  @override
  String get tryAgainGently => 'لنحاول مرة أخرى!';

  @override
  String get almostThere => 'اقتربت! أنت قادر على ذلك.';

  @override
  String get youDidIt => 'أحسنت!';

  @override
  String roundProgress(String current, String total) {
    return 'الجولة $current من $total';
  }

  @override
  String get journeyMap => 'خريطة الرحلة';

  @override
  String exploreCategory(String place) {
    return 'استكشف $place';
  }

  @override
  String onboardingHello(String name) {
    return 'مرحبًا! أنا $name.';
  }

  @override
  String get onboardingAskName => 'ما اسمك؟';

  @override
  String get onboardingNameHint => 'اسمك';

  @override
  String get onboardingAskAge => 'كم عمرك؟';

  @override
  String get yearsOld => 'سنوات';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingBack => 'رجوع';

  @override
  String onboardingReady(String name) {
    return 'تبدأ مغامرتك يا $name!';
  }

  @override
  String get onboardingReadyNoName => 'تبدأ مغامرتك!';

  @override
  String onboardingFirstStop(String stage) {
    return 'المحطة الأولى: $stage';
  }

  @override
  String get letsGo => 'هيّا بنا!';

  @override
  String get myJourney => 'رحلتي';

  @override
  String get youAreHere => 'أنت هنا';

  @override
  String stageDoneCount(String done, String total) {
    return 'أنجزت $done من $total';
  }

  @override
  String get nextAdventure => 'المغامرة التالية';

  @override
  String get todaysAdventure => 'مغامرة اليوم';

  @override
  String get exploreMore => 'استكشف المزيد';

  @override
  String get stageComplete => 'أنهيت هذه المغامرة!';

  @override
  String get newAdventure => 'مغامرة جديدة بانتظارك!';

  @override
  String get journeyAllDone => 'أنهيت الرحلة كلها! العب أي مغامرة من جديد.';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusLocked => 'مغلق';

  @override
  String get statusNext => 'التالي';

  @override
  String get statusMastered => 'نجم';

  @override
  String get statusAvailable => 'جاهز للعب';

  @override
  String get statusEarlier => 'مغامرة سابقة';

  @override
  String get roleRequired => 'أساسي';

  @override
  String get rolePractice => 'تدريب';

  @override
  String get roleChallenge => 'تحدٍّ';

  @override
  String get roleOptional => 'إضافي';

  @override
  String get roleReview => 'مراجعة';

  @override
  String get unlockHint => 'أنهِ الألعاب التي قبلها لتفتح هذه.';

  @override
  String weAreIn(String stage) {
    return 'نحن نستكشف $stage!';
  }

  @override
  String get childAge => 'عمر الطفل';

  @override
  String get changeAgeHelp =>
      'تتكيّف الرحلة مع العمر الجديد، ولا يُحذف أي شيء أنجزه طفلك.';

  @override
  String get journeyStage => 'مرحلة الرحلة';

  @override
  String get developmentalAreas => 'مجالات النمو';

  @override
  String get areasNote =>
      'نسبة أنشطة الرحلة المكتملة حتى الآن. هذه ليست درجة ولا تقييمًا.';

  @override
  String get activityHistory => 'سجلّ الأنشطة';

  @override
  String get noHistoryYet => 'لم يُلعب أي نشاط بعد.';

  @override
  String playedTimes(String count) {
    return 'مرات اللعب: $count';
  }

  @override
  String get domainSocialEmotional => 'المشاعر والأصدقاء';

  @override
  String get domainLanguage => 'اللغة';

  @override
  String get domainEarlyLiteracy => 'القراءة المبكرة';

  @override
  String get domainAuditory => 'الأصوات والاستماع';

  @override
  String get domainNumeracy => 'الأرقام';

  @override
  String get domainMemory => 'الذاكرة';

  @override
  String get domainAttention => 'الانتباه';

  @override
  String get domainProblemSolving => 'حلّ المشكلات';

  @override
  String get decreaseAge => 'أصغر';

  @override
  String get increaseAge => 'أكبر';

  @override
  String get greatEffort => 'يا له من مجهود رائع!';

  @override
  String get scaffoldModelled => 'سأريك أولًا كيف نلعب!';

  @override
  String get scaffoldGuided => 'سأساعدك خطوة بخطوة!';

  @override
  String get scaffoldIndependent => 'أنت جاهز للتحدّي!';
}

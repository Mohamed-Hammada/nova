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
}

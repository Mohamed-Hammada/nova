import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Product name, shown in the window title and header.
  ///
  /// In en, this message translates to:
  /// **'Nova'**
  String get appTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play!'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a game to start.'**
  String get homeSubtitle;

  /// Button on a game card that starts the game.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playGame;

  /// Entry point to the parent/caregiver progress area.
  ///
  /// In en, this message translates to:
  /// **'For grown-ups'**
  String get grownUps;

  /// No description provided for @languageMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageMenuTooltip;

  /// Endonym: always written in English, in every locale.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// Endonym: always written in Arabic, in every locale.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageNameArabic;

  /// No description provided for @loadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get loadingMessage;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorContentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The games could not be loaded on this device.'**
  String get errorContentUnavailable;

  /// No description provided for @errorGameUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This game could not be started.'**
  String get errorGameUnavailable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @emptyGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'No games yet'**
  String get emptyGamesTitle;

  /// No description provided for @emptyGamesBody.
  ///
  /// In en, this message translates to:
  /// **'Games will appear here when they are ready.'**
  String get emptyGamesBody;

  /// No description provided for @leaveGame.
  ///
  /// In en, this message translates to:
  /// **'Back to games'**
  String get leaveGame;

  /// What the bear asks for. countText is count already formatted for the locale's digits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Give the bear {countText} apple} other{Give the bear {countText} apples}}'**
  String gamePrompt(int count, String countText);

  /// No description provided for @gameHowTo.
  ///
  /// In en, this message translates to:
  /// **'Drag the apples to the plate, or tap them.'**
  String get gameHowTo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Help me count'**
  String get hint;

  /// Shown only after the child asks for help: the running count.
  ///
  /// In en, this message translates to:
  /// **'{countText} on the plate'**
  String hintOnPlate(String countText);

  /// Screen-reader label for the trial progress dots.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String trialProgress(String current, String total);

  /// No description provided for @feedbackCorrect.
  ///
  /// In en, this message translates to:
  /// **'That\'s just right! The bear is happy.'**
  String get feedbackCorrect;

  /// No description provided for @feedbackTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Not quite. Let\'s count again.'**
  String get feedbackTryAgain;

  /// No description provided for @feedbackOnlyApples.
  ///
  /// In en, this message translates to:
  /// **'The bear only wants apples.'**
  String get feedbackOnlyApples;

  /// No description provided for @feedbackMoveOn.
  ///
  /// In en, this message translates to:
  /// **'Good try! Let\'s do the next one.'**
  String get feedbackMoveOn;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your progress could not be saved.'**
  String get saveFailed;

  /// No description provided for @sessionCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get sessionCompleteTitle;

  /// No description provided for @sessionCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You helped the bear. Well done!'**
  String get sessionCompleteBody;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get backHome;

  /// No description provided for @itemApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get itemApple;

  /// No description provided for @itemPear.
  ///
  /// In en, this message translates to:
  /// **'Pear'**
  String get itemPear;

  /// No description provided for @itemGiveHint.
  ///
  /// In en, this message translates to:
  /// **'Give to the bear'**
  String get itemGiveHint;

  /// No description provided for @itemOnPlateApple.
  ///
  /// In en, this message translates to:
  /// **'Apple on the plate'**
  String get itemOnPlateApple;

  /// No description provided for @itemOnPlatePear.
  ///
  /// In en, this message translates to:
  /// **'Pear on the plate'**
  String get itemOnPlatePear;

  /// No description provided for @itemTakeBackHint.
  ///
  /// In en, this message translates to:
  /// **'Take back'**
  String get itemTakeBackHint;

  /// No description provided for @plateLabel.
  ///
  /// In en, this message translates to:
  /// **'The bear\'s plate'**
  String get plateLabel;

  /// No description provided for @plateEmpty.
  ///
  /// In en, this message translates to:
  /// **'The plate is empty'**
  String get plateEmpty;

  /// No description provided for @pileLabel.
  ///
  /// In en, this message translates to:
  /// **'Fruit on the table'**
  String get pileLabel;

  /// No description provided for @bearLabel.
  ///
  /// In en, this message translates to:
  /// **'The bear'**
  String get bearLabel;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressIntro.
  ///
  /// In en, this message translates to:
  /// **'What the games have seen so far, skill by skill.'**
  String get progressIntro;

  /// No description provided for @progressDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is an early estimate, not a diagnosis.'**
  String get progressDisclaimer;

  /// No description provided for @progressLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Progress could not be loaded.'**
  String get progressLoadFailed;

  /// No description provided for @masteryNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get masteryNotYet;

  /// No description provided for @masteryEmerging.
  ///
  /// In en, this message translates to:
  /// **'Emerging'**
  String get masteryEmerging;

  /// No description provided for @masteryDeveloping.
  ///
  /// In en, this message translates to:
  /// **'Developing'**
  String get masteryDeveloping;

  /// No description provided for @masterySecure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get masterySecure;

  /// No description provided for @masteryTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get masteryTransfer;

  /// No description provided for @masteryNotYetDescription.
  ///
  /// In en, this message translates to:
  /// **'Not enough play yet to say.'**
  String get masteryNotYetDescription;

  /// No description provided for @masteryEmergingDescription.
  ///
  /// In en, this message translates to:
  /// **'Starting to show this skill, often with support.'**
  String get masteryEmergingDescription;

  /// No description provided for @masteryDevelopingDescription.
  ///
  /// In en, this message translates to:
  /// **'Succeeds often, still building consistency.'**
  String get masteryDevelopingDescription;

  /// No description provided for @masterySecureDescription.
  ///
  /// In en, this message translates to:
  /// **'Succeeds consistently, without help.'**
  String get masterySecureDescription;

  /// No description provided for @masteryTransferDescription.
  ///
  /// In en, this message translates to:
  /// **'Also uses the skill outside this game.'**
  String get masteryTransferDescription;

  /// No description provided for @masteryStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String masteryStepOf(String current, String total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

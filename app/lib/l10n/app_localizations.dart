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

  /// No description provided for @graphicsQuality.
  ///
  /// In en, this message translates to:
  /// **'Graphics Quality'**
  String get graphicsQuality;

  /// No description provided for @graphicsAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (Recommended)'**
  String get graphicsAuto;

  /// No description provided for @graphicsAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically adapts to device capability'**
  String get graphicsAutoDesc;

  /// No description provided for @graphicsHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get graphicsHigh;

  /// No description provided for @graphicsHighDesc.
  ///
  /// In en, this message translates to:
  /// **'Richest 3D visuals, soft shadows, and effects'**
  String get graphicsHighDesc;

  /// No description provided for @graphicsMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get graphicsMedium;

  /// No description provided for @graphicsMediumDesc.
  ///
  /// In en, this message translates to:
  /// **'Balanced performance and visuals'**
  String get graphicsMediumDesc;

  /// No description provided for @graphicsLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get graphicsLow;

  /// No description provided for @graphicsLowDesc.
  ///
  /// In en, this message translates to:
  /// **'Best for budget devices'**
  String get graphicsLowDesc;

  /// No description provided for @graphics2D.
  ///
  /// In en, this message translates to:
  /// **'2D Mode'**
  String get graphics2D;

  /// No description provided for @graphics2DDesc.
  ///
  /// In en, this message translates to:
  /// **'Classic 2D sprites, saves battery'**
  String get graphics2DDesc;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// The guide character introduces itself.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m {name}!'**
  String greeting(String name);

  /// No description provided for @greetingNamed.
  ///
  /// In en, this message translates to:
  /// **'Hi {child}! I\'m {name}!'**
  String greetingNamed(String child, String name);

  /// Age group 2-3.
  ///
  /// In en, this message translates to:
  /// **'Little Stars'**
  String get bandTiny;

  /// Age group 4-5.
  ///
  /// In en, this message translates to:
  /// **'Explorers'**
  String get bandExplorer;

  /// Age group 6-8.
  ///
  /// In en, this message translates to:
  /// **'Champions'**
  String get bandChampion;

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{range} years'**
  String ageYears(String range);

  /// number is already formatted for the locale.
  ///
  /// In en, this message translates to:
  /// **'Level {number}'**
  String levelLabel(String number);

  /// No description provided for @levelDone.
  ///
  /// In en, this message translates to:
  /// **'Level complete!'**
  String get levelDone;

  /// No description provided for @backToMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get backToMap;

  /// No description provided for @journeyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Journey'**
  String get journeyTitle;

  /// No description provided for @journeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} levels to explore'**
  String journeySubtitle(String count);

  /// No description provided for @chapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapter(String number);

  /// No description provided for @starsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} stars'**
  String starsCount(String count, String total);

  /// No description provided for @moreGames.
  ///
  /// In en, this message translates to:
  /// **'More games'**
  String get moreGames;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @spokenPrompts.
  ///
  /// In en, this message translates to:
  /// **'Spoken instructions'**
  String get spokenPrompts;

  /// No description provided for @spokenPromptsDesc.
  ///
  /// In en, this message translates to:
  /// **'The characters read every instruction aloud.'**
  String get spokenPromptsDesc;

  /// No description provided for @voiceAnswers.
  ///
  /// In en, this message translates to:
  /// **'Answer by voice (microphone)'**
  String get voiceAnswers;

  /// No description provided for @voiceAnswersDesc.
  ///
  /// In en, this message translates to:
  /// **'Your child can say answers out loud. Speech is recognised on this device only; nothing is recorded or sent.'**
  String get voiceAnswersDesc;

  /// No description provided for @cameraPlay.
  ///
  /// In en, this message translates to:
  /// **'Face play (camera)'**
  String get cameraPlay;

  /// No description provided for @cameraPlayDesc.
  ///
  /// In en, this message translates to:
  /// **'The characters can see your child smile, look around and play peekaboo. Faces are processed on this device only; no picture is saved or sent.'**
  String get cameraPlayDesc;

  /// No description provided for @notOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device.'**
  String get notOnThisDevice;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission was not given. You can allow it in the device settings.'**
  String get permissionDenied;

  /// No description provided for @didntCatch.
  ///
  /// In en, this message translates to:
  /// **'I didn\'t catch that. Say it again, or tap!'**
  String get didntCatch;

  /// No description provided for @sayIt.
  ///
  /// In en, this message translates to:
  /// **'Say it!'**
  String get sayIt;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listening;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// No description provided for @myName.
  ///
  /// In en, this message translates to:
  /// **'My name'**
  String get myName;

  /// No description provided for @typeName.
  ///
  /// In en, this message translates to:
  /// **'Type your name'**
  String get typeName;

  /// No description provided for @howOld.
  ///
  /// In en, this message translates to:
  /// **'How old am I?'**
  String get howOld;

  /// No description provided for @myFriend.
  ///
  /// In en, this message translates to:
  /// **'My friend'**
  String get myFriend;

  /// No description provided for @myWorld.
  ///
  /// In en, this message translates to:
  /// **'My world'**
  String get myWorld;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get automatic;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @worldCandyMeadow.
  ///
  /// In en, this message translates to:
  /// **'Candy Meadow'**
  String get worldCandyMeadow;

  /// No description provided for @worldSunnyForest.
  ///
  /// In en, this message translates to:
  /// **'Sunny Forest'**
  String get worldSunnyForest;

  /// No description provided for @worldSpaceLab.
  ///
  /// In en, this message translates to:
  /// **'Space Lab'**
  String get worldSpaceLab;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Amazing!'**
  String get greatJob;

  /// No description provided for @niceTry.
  ///
  /// In en, this message translates to:
  /// **'Nice try!'**
  String get niceTry;

  /// No description provided for @repeatInstruction.
  ///
  /// In en, this message translates to:
  /// **'Say it again'**
  String get repeatInstruction;

  /// No description provided for @closeLevel.
  ///
  /// In en, this message translates to:
  /// **'Leave level'**
  String get closeLevel;

  /// No description provided for @levelLocked.
  ///
  /// In en, this message translates to:
  /// **'Level {number}, locked'**
  String levelLocked(String number);

  /// No description provided for @levelOpen.
  ///
  /// In en, this message translates to:
  /// **'Level {number}'**
  String levelOpen(String number);

  /// No description provided for @promptMatchNumber.
  ///
  /// In en, this message translates to:
  /// **'Find the group with {n}.'**
  String promptMatchNumber(String n);

  /// No description provided for @promptPickMore.
  ///
  /// In en, this message translates to:
  /// **'Which one has more?'**
  String get promptPickMore;

  /// No description provided for @promptPickFewer.
  ///
  /// In en, this message translates to:
  /// **'Which one has fewer?'**
  String get promptPickFewer;

  /// No description provided for @promptWhatNext.
  ///
  /// In en, this message translates to:
  /// **'What comes next?'**
  String get promptWhatNext;

  /// No description provided for @promptWhatNextTower.
  ///
  /// In en, this message translates to:
  /// **'Which tower comes next?'**
  String get promptWhatNextTower;

  /// No description provided for @promptSameFeeling.
  ///
  /// In en, this message translates to:
  /// **'Who feels the same?'**
  String get promptSameFeeling;

  /// No description provided for @promptHowFeel.
  ///
  /// In en, this message translates to:
  /// **'{story} How do they feel?'**
  String promptHowFeel(String story);

  /// No description provided for @promptListenFind.
  ///
  /// In en, this message translates to:
  /// **'Listen, then find the picture.'**
  String get promptListenFind;

  /// No description provided for @promptFindWord.
  ///
  /// In en, this message translates to:
  /// **'Find the {word}.'**
  String promptFindWord(String word);

  /// No description provided for @promptRhyme.
  ///
  /// In en, this message translates to:
  /// **'What rhymes with {word}?'**
  String promptRhyme(String word);

  /// No description provided for @promptFirstLetter.
  ///
  /// In en, this message translates to:
  /// **'Which letter does {word} start with?'**
  String promptFirstLetter(String word);

  /// No description provided for @promptBlend.
  ///
  /// In en, this message translates to:
  /// **'{parts}… What word is it?'**
  String promptBlend(String parts);

  /// No description provided for @promptReadFind.
  ///
  /// In en, this message translates to:
  /// **'Read the word, then find its picture.'**
  String get promptReadFind;

  /// No description provided for @promptLetterSmall.
  ///
  /// In en, this message translates to:
  /// **'Find the small letter for {letter}.'**
  String promptLetterSmall(String letter);

  /// No description provided for @promptLetterJoined.
  ///
  /// In en, this message translates to:
  /// **'Find {letter} at the start of a word.'**
  String promptLetterJoined(String letter);

  /// No description provided for @promptDragCount.
  ///
  /// In en, this message translates to:
  /// **'Give {name} {n} {thing}!'**
  String promptDragCount(String name, String n, String thing);

  /// No description provided for @promptTapCount.
  ///
  /// In en, this message translates to:
  /// **'Tap each one to count, then choose how many.'**
  String get promptTapCount;

  /// No description provided for @promptJoin.
  ///
  /// In en, this message translates to:
  /// **'Watch closely. How many now?'**
  String get promptJoin;

  /// No description provided for @promptNumberLine.
  ///
  /// In en, this message translates to:
  /// **'Where does {n} go? Tap the line.'**
  String promptNumberLine(String n);

  /// No description provided for @promptSortColour.
  ///
  /// In en, this message translates to:
  /// **'Sort by colour!'**
  String get promptSortColour;

  /// No description provided for @promptSortShape.
  ///
  /// In en, this message translates to:
  /// **'Sort by shape!'**
  String get promptSortShape;

  /// No description provided for @promptSortBorder.
  ///
  /// In en, this message translates to:
  /// **'Gold border: sort by shape. No border: by colour.'**
  String get promptSortBorder;

  /// No description provided for @promptNewRule.
  ///
  /// In en, this message translates to:
  /// **'New rule!'**
  String get promptNewRule;

  /// No description provided for @promptPairs.
  ///
  /// In en, this message translates to:
  /// **'Find the matching pairs.'**
  String get promptPairs;

  /// No description provided for @promptSimonWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch the lights…'**
  String get promptSimonWatch;

  /// No description provided for @promptSimonGo.
  ///
  /// In en, this message translates to:
  /// **'Now you! Tap them in the same order.'**
  String get promptSimonGo;

  /// No description provided for @promptFeedFish.
  ///
  /// In en, this message translates to:
  /// **'Tap to feed the fish. Wait when a shark comes!'**
  String get promptFeedFish;

  /// No description provided for @promptCatch.
  ///
  /// In en, this message translates to:
  /// **'Catch every one that matches!'**
  String get promptCatch;

  /// No description provided for @promptClap.
  ///
  /// In en, this message translates to:
  /// **'Tap the drum once for each part of the word.'**
  String get promptClap;

  /// No description provided for @promptPrintStart.
  ///
  /// In en, this message translates to:
  /// **'Tap where the reading starts.'**
  String get promptPrintStart;

  /// No description provided for @promptPrintFollow.
  ///
  /// In en, this message translates to:
  /// **'Tap the words in reading order.'**
  String get promptPrintFollow;

  /// No description provided for @promptBuild.
  ///
  /// In en, this message translates to:
  /// **'Build the word for the picture.'**
  String get promptBuild;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBack(String name);

  /// No description provided for @welcomeBackNoName.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBackNoName;

  /// No description provided for @letsExplore.
  ///
  /// In en, this message translates to:
  /// **'Let\'s explore together.'**
  String get letsExplore;

  /// No description provided for @companionHello.
  ///
  /// In en, this message translates to:
  /// **'I\'m {name}. Where shall we go today?'**
  String companionHello(String name);

  /// No description provided for @continueJourney.
  ///
  /// In en, this message translates to:
  /// **'Continue your journey'**
  String get continueJourney;

  /// No description provided for @startJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your journey'**
  String get startJourney;

  /// No description provided for @placesToExplore.
  ///
  /// In en, this message translates to:
  /// **'Places to explore'**
  String get placesToExplore;

  /// No description provided for @activitiesCount.
  ///
  /// In en, this message translates to:
  /// **'Activities: {count}'**
  String activitiesCount(String count);

  /// No description provided for @myTreasures.
  ///
  /// In en, this message translates to:
  /// **'My treasures'**
  String get myTreasures;

  /// No description provided for @starsCollected.
  ///
  /// In en, this message translates to:
  /// **'{count} stars'**
  String starsCollected(String count);

  /// No description provided for @levelsExplored.
  ///
  /// In en, this message translates to:
  /// **'{count} levels explored'**
  String levelsExplored(String count);

  /// No description provided for @badgeFirstSteps.
  ///
  /// In en, this message translates to:
  /// **'First steps'**
  String get badgeFirstSteps;

  /// No description provided for @badgeStarCatcher.
  ///
  /// In en, this message translates to:
  /// **'Star catcher'**
  String get badgeStarCatcher;

  /// No description provided for @badgeExplorer.
  ///
  /// In en, this message translates to:
  /// **'Great explorer'**
  String get badgeExplorer;

  /// No description provided for @badgeLocked.
  ///
  /// In en, this message translates to:
  /// **'Keep playing to unlock this'**
  String get badgeLocked;

  /// No description provided for @catNumbers.
  ///
  /// In en, this message translates to:
  /// **'Number Meadow'**
  String get catNumbers;

  /// No description provided for @catLanguage.
  ///
  /// In en, this message translates to:
  /// **'Story Woods'**
  String get catLanguage;

  /// No description provided for @catSounds.
  ///
  /// In en, this message translates to:
  /// **'Sound Valley'**
  String get catSounds;

  /// No description provided for @catFeelings.
  ///
  /// In en, this message translates to:
  /// **'Heart Garden'**
  String get catFeelings;

  /// No description provided for @catMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory Cove'**
  String get catMemory;

  /// No description provided for @catDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery Hill'**
  String get catDiscovery;

  /// No description provided for @catMovement.
  ///
  /// In en, this message translates to:
  /// **'Splash Pond'**
  String get catMovement;

  /// No description provided for @catNumbersTag.
  ///
  /// In en, this message translates to:
  /// **'Count, compare and find patterns'**
  String get catNumbersTag;

  /// No description provided for @catLanguageTag.
  ///
  /// In en, this message translates to:
  /// **'Words, letters and stories'**
  String get catLanguageTag;

  /// No description provided for @catSoundsTag.
  ///
  /// In en, this message translates to:
  /// **'Rhymes, beats and first sounds'**
  String get catSoundsTag;

  /// No description provided for @catFeelingsTag.
  ///
  /// In en, this message translates to:
  /// **'Understand how friends feel'**
  String get catFeelingsTag;

  /// No description provided for @catMemoryTag.
  ///
  /// In en, this message translates to:
  /// **'Remember, match and repeat'**
  String get catMemoryTag;

  /// No description provided for @catDiscoveryTag.
  ///
  /// In en, this message translates to:
  /// **'Sort, switch and think'**
  String get catDiscoveryTag;

  /// No description provided for @catMovementTag.
  ///
  /// In en, this message translates to:
  /// **'Quick eyes, careful hands'**
  String get catMovementTag;

  /// No description provided for @newActivity.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newActivity;

  /// No description provided for @tryAgainGently.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try again!'**
  String get tryAgainGently;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost! You can do it.'**
  String get almostThere;

  /// No description provided for @youDidIt.
  ///
  /// In en, this message translates to:
  /// **'You did it!'**
  String get youDidIt;

  /// No description provided for @roundProgress.
  ///
  /// In en, this message translates to:
  /// **'Round {current} of {total}'**
  String roundProgress(String current, String total);

  /// No description provided for @journeyMap.
  ///
  /// In en, this message translates to:
  /// **'Journey map'**
  String get journeyMap;

  /// No description provided for @exploreCategory.
  ///
  /// In en, this message translates to:
  /// **'Explore {place}'**
  String exploreCategory(String place);

  /// No description provided for @onboardingHello.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m {name}.'**
  String onboardingHello(String name);

  /// No description provided for @onboardingAskName.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingAskName;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardingNameHint;

  /// No description provided for @onboardingAskAge.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get onboardingAskAge;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'years old'**
  String get yearsOld;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingReady.
  ///
  /// In en, this message translates to:
  /// **'Your adventure begins, {name}!'**
  String onboardingReady(String name);

  /// No description provided for @onboardingReadyNoName.
  ///
  /// In en, this message translates to:
  /// **'Your adventure begins!'**
  String get onboardingReadyNoName;

  /// No description provided for @onboardingFirstStop.
  ///
  /// In en, this message translates to:
  /// **'First stop: {stage}'**
  String onboardingFirstStop(String stage);

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get letsGo;

  /// No description provided for @myJourney.
  ///
  /// In en, this message translates to:
  /// **'My journey'**
  String get myJourney;

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get youAreHere;

  /// No description provided for @stageDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String stageDoneCount(String done, String total);

  /// No description provided for @nextAdventure.
  ///
  /// In en, this message translates to:
  /// **'Next adventure'**
  String get nextAdventure;

  /// No description provided for @todaysAdventure.
  ///
  /// In en, this message translates to:
  /// **'Today\'s adventure'**
  String get todaysAdventure;

  /// No description provided for @exploreMore.
  ///
  /// In en, this message translates to:
  /// **'Explore more'**
  String get exploreMore;

  /// No description provided for @stageComplete.
  ///
  /// In en, this message translates to:
  /// **'You finished this adventure!'**
  String get stageComplete;

  /// No description provided for @newAdventure.
  ///
  /// In en, this message translates to:
  /// **'A new adventure is waiting!'**
  String get newAdventure;

  /// No description provided for @journeyAllDone.
  ///
  /// In en, this message translates to:
  /// **'You finished the whole journey! Replay any adventure.'**
  String get journeyAllDone;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusCompleted;

  /// No description provided for @statusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get statusLocked;

  /// No description provided for @statusNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get statusNext;

  /// No description provided for @statusMastered.
  ///
  /// In en, this message translates to:
  /// **'Star player'**
  String get statusMastered;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ready to play'**
  String get statusAvailable;

  /// No description provided for @statusEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier adventure'**
  String get statusEarlier;

  /// No description provided for @roleRequired.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get roleRequired;

  /// No description provided for @rolePractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get rolePractice;

  /// No description provided for @roleChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get roleChallenge;

  /// No description provided for @roleOptional.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get roleOptional;

  /// No description provided for @roleReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get roleReview;

  /// No description provided for @unlockHint.
  ///
  /// In en, this message translates to:
  /// **'Finish the games before it to open this one.'**
  String get unlockHint;

  /// No description provided for @weAreIn.
  ///
  /// In en, this message translates to:
  /// **'We\'re exploring {stage}!'**
  String weAreIn(String stage);

  /// No description provided for @childAge.
  ///
  /// In en, this message translates to:
  /// **'Child\'s age'**
  String get childAge;

  /// No description provided for @changeAgeHelp.
  ///
  /// In en, this message translates to:
  /// **'The journey adapts to the new age. Nothing your child has done is removed.'**
  String get changeAgeHelp;

  /// No description provided for @journeyStage.
  ///
  /// In en, this message translates to:
  /// **'Journey stage'**
  String get journeyStage;

  /// No description provided for @developmentalAreas.
  ///
  /// In en, this message translates to:
  /// **'Developmental areas'**
  String get developmentalAreas;

  /// No description provided for @areasNote.
  ///
  /// In en, this message translates to:
  /// **'Share of journey activities completed so far. This is not a score or an assessment.'**
  String get areasNote;

  /// No description provided for @activityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity history'**
  String get activityHistory;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing played yet.'**
  String get noHistoryYet;

  /// No description provided for @playedTimes.
  ///
  /// In en, this message translates to:
  /// **'Played {count} times'**
  String playedTimes(String count);

  /// No description provided for @domainSocialEmotional.
  ///
  /// In en, this message translates to:
  /// **'Feelings & friends'**
  String get domainSocialEmotional;

  /// No description provided for @domainLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get domainLanguage;

  /// No description provided for @domainEarlyLiteracy.
  ///
  /// In en, this message translates to:
  /// **'Early reading'**
  String get domainEarlyLiteracy;

  /// No description provided for @domainAuditory.
  ///
  /// In en, this message translates to:
  /// **'Sounds & listening'**
  String get domainAuditory;

  /// No description provided for @domainNumeracy.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get domainNumeracy;

  /// No description provided for @domainMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get domainMemory;

  /// No description provided for @domainAttention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get domainAttention;

  /// No description provided for @domainProblemSolving.
  ///
  /// In en, this message translates to:
  /// **'Problem solving'**
  String get domainProblemSolving;

  /// No description provided for @decreaseAge.
  ///
  /// In en, this message translates to:
  /// **'Younger'**
  String get decreaseAge;

  /// No description provided for @increaseAge.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get increaseAge;
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

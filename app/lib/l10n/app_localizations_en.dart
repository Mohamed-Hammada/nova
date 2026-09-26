// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nova';

  @override
  String get homeGreeting => 'Let\'s play!';

  @override
  String get homeSubtitle => 'Pick a game to start.';

  @override
  String get playGame => 'Play';

  @override
  String get grownUps => 'For grown-ups';

  @override
  String get languageMenuTooltip => 'Change language';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get loadingMessage => 'Getting ready…';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorContentUnavailable =>
      'The games could not be loaded on this device.';

  @override
  String get errorGameUnavailable => 'This game could not be started.';

  @override
  String get retry => 'Try again';

  @override
  String get emptyGamesTitle => 'No games yet';

  @override
  String get emptyGamesBody => 'Games will appear here when they are ready.';

  @override
  String get leaveGame => 'Back to games';

  @override
  String gamePrompt(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Give the bear $countText apples',
      one: 'Give the bear $countText apple',
    );
    return '$_temp0';
  }

  @override
  String get gameHowTo => 'Drag the apples to the plate, or tap them.';

  @override
  String get done => 'Done';

  @override
  String get hint => 'Help me count';

  @override
  String hintOnPlate(String countText) {
    return '$countText on the plate';
  }

  @override
  String trialProgress(String current, String total) {
    return 'Question $current of $total';
  }

  @override
  String get feedbackCorrect => 'That\'s just right! The bear is happy.';

  @override
  String get feedbackTryAgain => 'Not quite. Let\'s count again.';

  @override
  String get feedbackOnlyApples => 'The bear only wants apples.';

  @override
  String get feedbackMoveOn => 'Good try! Let\'s do the next one.';

  @override
  String get next => 'Next';

  @override
  String get tryAgain => 'Try again';

  @override
  String get saving => 'Saving…';

  @override
  String get saveFailed => 'Your progress could not be saved.';

  @override
  String get sessionCompleteTitle => 'All done!';

  @override
  String get sessionCompleteBody => 'You helped the bear. Well done!';

  @override
  String get playAgain => 'Play again';

  @override
  String get backHome => 'Home';

  @override
  String get itemApple => 'Apple';

  @override
  String get itemPear => 'Pear';

  @override
  String get itemGiveHint => 'Give to the bear';

  @override
  String get itemOnPlateApple => 'Apple on the plate';

  @override
  String get itemOnPlatePear => 'Pear on the plate';

  @override
  String get itemTakeBackHint => 'Take back';

  @override
  String get plateLabel => 'The bear\'s plate';

  @override
  String get plateEmpty => 'The plate is empty';

  @override
  String get pileLabel => 'Fruit on the table';

  @override
  String get bearLabel => 'The bear';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressIntro =>
      'What the games have seen so far, skill by skill.';

  @override
  String get progressDisclaimer =>
      'This is an early estimate, not a diagnosis.';

  @override
  String get progressLoadFailed => 'Progress could not be loaded.';

  @override
  String get masteryNotYet => 'Not yet';

  @override
  String get masteryEmerging => 'Emerging';

  @override
  String get masteryDeveloping => 'Developing';

  @override
  String get masterySecure => 'Secure';

  @override
  String get masteryTransfer => 'Transfer';

  @override
  String get masteryNotYetDescription => 'Not enough play yet to say.';

  @override
  String get masteryEmergingDescription =>
      'Starting to show this skill, often with support.';

  @override
  String get masteryDevelopingDescription =>
      'Succeeds often, still building consistency.';

  @override
  String get masterySecureDescription => 'Succeeds consistently, without help.';

  @override
  String get masteryTransferDescription =>
      'Also uses the skill outside this game.';

  @override
  String masteryStepOf(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get graphicsQuality => 'Graphics Quality';

  @override
  String get graphicsAuto => 'Auto (Recommended)';

  @override
  String get graphicsAutoDesc => 'Automatically adapts to device capability';

  @override
  String get graphicsHigh => 'High';

  @override
  String get graphicsHighDesc =>
      'Richest 3D visuals, soft shadows, and effects';

  @override
  String get graphicsMedium => 'Medium';

  @override
  String get graphicsMediumDesc => 'Balanced performance and visuals';

  @override
  String get graphicsLow => 'Low';

  @override
  String get graphicsLowDesc => 'Best for budget devices';

  @override
  String get graphics2D => '2D Mode';

  @override
  String get graphics2DDesc => 'Classic 2D sprites, saves battery';

  @override
  String get close => 'Close';

  @override
  String greeting(String name) {
    return 'Hi! I\'m $name!';
  }

  @override
  String greetingNamed(String child, String name) {
    return 'Hi $child! I\'m $name!';
  }

  @override
  String get bandTiny => 'Little Stars';

  @override
  String get bandExplorer => 'Explorers';

  @override
  String get bandChampion => 'Champions';

  @override
  String ageYears(String range) {
    return '$range years';
  }

  @override
  String levelLabel(String number) {
    return 'Level $number';
  }

  @override
  String get levelDone => 'Level complete!';

  @override
  String get backToMap => 'Map';

  @override
  String get journeyTitle => 'My Journey';

  @override
  String journeySubtitle(String count) {
    return '$count levels to explore';
  }

  @override
  String chapter(String number) {
    return 'Chapter $number';
  }

  @override
  String starsCount(String count, String total) {
    return '$count of $total stars';
  }

  @override
  String get moreGames => 'More games';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get spokenPrompts => 'Spoken instructions';

  @override
  String get spokenPromptsDesc =>
      'The characters read every instruction aloud.';

  @override
  String get voiceAnswers => 'Answer by voice (microphone)';

  @override
  String get voiceAnswersDesc =>
      'Your child can say answers out loud. Speech is recognised on this device only; nothing is recorded or sent.';

  @override
  String get cameraPlay => 'Face play (camera)';

  @override
  String get cameraPlayDesc =>
      'The characters can see your child smile, look around and play peekaboo. Faces are processed on this device only; no picture is saved or sent.';

  @override
  String get notOnThisDevice => 'Not available on this device.';

  @override
  String get permissionDenied =>
      'Permission was not given. You can allow it in the device settings.';

  @override
  String get didntCatch => 'I didn\'t catch that. Say it again, or tap!';

  @override
  String get sayIt => 'Say it!';

  @override
  String get listening => 'Listening…';

  @override
  String get aboutMe => 'About me';

  @override
  String get myName => 'My name';

  @override
  String get typeName => 'Type your name';

  @override
  String get howOld => 'How old am I?';

  @override
  String get myFriend => 'My friend';

  @override
  String get myWorld => 'My world';

  @override
  String get automatic => 'Auto';

  @override
  String get languageLabel => 'Language';

  @override
  String get worldCandyMeadow => 'Candy Meadow';

  @override
  String get worldSunnyForest => 'Sunny Forest';

  @override
  String get worldSpaceLab => 'Space Lab';

  @override
  String get greatJob => 'Amazing!';

  @override
  String get niceTry => 'Nice try!';

  @override
  String get repeatInstruction => 'Say it again';

  @override
  String get closeLevel => 'Leave level';

  @override
  String levelLocked(String number) {
    return 'Level $number, locked';
  }

  @override
  String levelOpen(String number) {
    return 'Level $number';
  }

  @override
  String promptMatchNumber(String n) {
    return 'Find the group with $n.';
  }

  @override
  String get promptPickMore => 'Which one has more?';

  @override
  String get promptPickFewer => 'Which one has fewer?';

  @override
  String get promptWhatNext => 'What comes next?';

  @override
  String get promptWhatNextTower => 'Which tower comes next?';

  @override
  String get promptSameFeeling => 'Who feels the same?';

  @override
  String promptHowFeel(String story) {
    return '$story How do they feel?';
  }

  @override
  String get promptListenFind => 'Listen, then find the picture.';

  @override
  String promptFindWord(String word) {
    return 'Find the $word.';
  }

  @override
  String promptRhyme(String word) {
    return 'What rhymes with $word?';
  }

  @override
  String promptFirstLetter(String word) {
    return 'Which letter does $word start with?';
  }

  @override
  String promptBlend(String parts) {
    return '$parts… What word is it?';
  }

  @override
  String get promptReadFind => 'Read the word, then find its picture.';

  @override
  String promptLetterSmall(String letter) {
    return 'Find the small letter for $letter.';
  }

  @override
  String promptLetterJoined(String letter) {
    return 'Find $letter at the start of a word.';
  }

  @override
  String promptDragCount(String name, String n, String thing) {
    return 'Give $name $n $thing!';
  }

  @override
  String get promptTapCount => 'Tap each one to count, then choose how many.';

  @override
  String get promptJoin => 'Watch closely. How many now?';

  @override
  String promptNumberLine(String n) {
    return 'Where does $n go? Tap the line.';
  }

  @override
  String get promptSortColour => 'Sort by colour!';

  @override
  String get promptSortShape => 'Sort by shape!';

  @override
  String get promptSortBorder =>
      'Gold border: sort by shape. No border: by colour.';

  @override
  String get promptNewRule => 'New rule!';

  @override
  String get promptPairs => 'Find the matching pairs.';

  @override
  String get promptSimonWatch => 'Watch the lights…';

  @override
  String get promptSimonGo => 'Now you! Tap them in the same order.';

  @override
  String get promptFeedFish => 'Tap to feed the fish. Wait when a shark comes!';

  @override
  String get promptCatch => 'Catch every one that matches!';

  @override
  String get promptClap => 'Tap the drum once for each part of the word.';

  @override
  String get promptPrintStart => 'Tap where the reading starts.';

  @override
  String get promptPrintFollow => 'Tap the words in reading order.';

  @override
  String get promptBuild => 'Build the word for the picture.';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get welcomeBackNoName => 'Welcome back!';

  @override
  String get letsExplore => 'Let\'s explore together.';

  @override
  String companionHello(String name) {
    return 'I\'m $name. Let\'s keep going!';
  }

  @override
  String get continueJourney => 'Continue your journey';

  @override
  String get startJourney => 'Start your journey';

  @override
  String get placesToExplore => 'Places to explore';

  @override
  String activitiesCount(String count) {
    return 'Activities: $count';
  }

  @override
  String get myTreasures => 'My treasures';

  @override
  String starsCollected(String count) {
    return '$count stars';
  }

  @override
  String levelsExplored(String count) {
    return '$count levels explored';
  }

  @override
  String get badgeFirstSteps => 'First steps';

  @override
  String get badgeStarCatcher => 'Star catcher';

  @override
  String get badgeExplorer => 'Great explorer';

  @override
  String get badgeLocked => 'Keep playing to unlock this';

  @override
  String get catNumbers => 'Number Meadow';

  @override
  String get catLanguage => 'Story Woods';

  @override
  String get catSounds => 'Sound Valley';

  @override
  String get catFeelings => 'Heart Garden';

  @override
  String get catMemory => 'Memory Cove';

  @override
  String get catDiscovery => 'Discovery Hill';

  @override
  String get catMovement => 'Splash Pond';

  @override
  String get catNumbersTag => 'Count, compare and find patterns';

  @override
  String get catLanguageTag => 'Words, letters and stories';

  @override
  String get catSoundsTag => 'Rhymes, beats and first sounds';

  @override
  String get catFeelingsTag => 'Understand how friends feel';

  @override
  String get catMemoryTag => 'Remember, match and repeat';

  @override
  String get catDiscoveryTag => 'Sort, switch and think';

  @override
  String get catMovementTag => 'Quick eyes, careful hands';

  @override
  String get newActivity => 'New';

  @override
  String get tryAgainGently => 'Let\'s try again!';

  @override
  String get almostThere => 'Almost! You can do it.';

  @override
  String get youDidIt => 'You did it!';

  @override
  String roundProgress(String current, String total) {
    return 'Round $current of $total';
  }

  @override
  String get journeyMap => 'Journey map';

  @override
  String exploreCategory(String place) {
    return 'Explore $place';
  }

  @override
  String onboardingHello(String name) {
    return 'Hi! I\'m $name.';
  }

  @override
  String get onboardingAskName => 'What\'s your name?';

  @override
  String get onboardingNameHint => 'Your name';

  @override
  String get onboardingAskAge => 'How old are you?';

  @override
  String get yearsOld => 'years old';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String onboardingReady(String name) {
    return 'Your adventure begins, $name!';
  }

  @override
  String get onboardingReadyNoName => 'Your adventure begins!';

  @override
  String onboardingFirstStop(String stage) {
    return 'First stop: $stage';
  }

  @override
  String get letsGo => 'Let\'s go!';

  @override
  String get myJourney => 'My journey';

  @override
  String get youAreHere => 'You are here';

  @override
  String stageDoneCount(String done, String total) {
    return '$done of $total done';
  }

  @override
  String get nextAdventure => 'Next adventure';

  @override
  String get todaysAdventure => 'Today\'s adventure';

  @override
  String get exploreMore => 'Explore more';

  @override
  String get stageComplete => 'You finished this adventure!';

  @override
  String get newAdventure => 'A new adventure is waiting!';

  @override
  String get currentAdventure => 'Current adventure';

  @override
  String stageCompleteNamed(String stage) {
    return 'Well done! You finished $stage!';
  }

  @override
  String get biggerAdventure => 'A bigger adventure begins!';

  @override
  String get exploreMoreHint => 'More to play on your journey';

  @override
  String get journeyAllDone =>
      'You finished the whole journey! Replay any adventure.';

  @override
  String get statusCompleted => 'Done';

  @override
  String get statusLocked => 'Locked';

  @override
  String get statusNext => 'Next';

  @override
  String get statusMastered => 'Star player';

  @override
  String get statusAvailable => 'Ready to play';

  @override
  String get statusEarlier => 'Earlier adventure';

  @override
  String get roleRequired => 'Main';

  @override
  String get rolePractice => 'Practice';

  @override
  String get roleChallenge => 'Challenge';

  @override
  String get roleOptional => 'Bonus';

  @override
  String get roleReview => 'Review';

  @override
  String get unlockHint => 'Finish the games before it to open this one.';

  @override
  String weAreIn(String stage) {
    return 'We\'re exploring $stage!';
  }

  @override
  String get childAge => 'Child\'s age';

  @override
  String get changeAgeHelp =>
      'The journey adapts to the new age. Nothing your child has done is removed.';

  @override
  String get journeyStage => 'Journey stage';

  @override
  String get developmentalAreas => 'Developmental areas';

  @override
  String get areasNote =>
      'Share of journey activities completed so far. This is not a score or an assessment.';

  @override
  String get activityHistory => 'Activity history';

  @override
  String get noHistoryYet => 'Nothing played yet.';

  @override
  String playedTimes(String count) {
    return 'Played $count times';
  }

  @override
  String get domainSocialEmotional => 'Feelings & friends';

  @override
  String get domainLanguage => 'Language';

  @override
  String get domainEarlyLiteracy => 'Early reading';

  @override
  String get domainAuditory => 'Sounds & listening';

  @override
  String get domainNumeracy => 'Numbers';

  @override
  String get domainMemory => 'Memory';

  @override
  String get domainAttention => 'Attention';

  @override
  String get domainProblemSolving => 'Problem solving';

  @override
  String get decreaseAge => 'Younger';

  @override
  String get increaseAge => 'Older';

  @override
  String get greatEffort => 'What great effort!';

  @override
  String get scaffoldModelled => 'Let me show you first!';

  @override
  String get scaffoldGuided => 'I\'ll help you along the way!';

  @override
  String get scaffoldIndependent => 'You\'re ready for a challenge!';

  @override
  String get recPractice => 'Let\'s practise that a little more!';

  @override
  String get recTryAgain => 'Let\'s try that one again together!';

  @override
  String reportAge(String age) {
    return 'Age: $age';
  }

  @override
  String get completedStages => 'Completed stages';

  @override
  String get noneYet => 'None yet';

  @override
  String get completionNote =>
      'Completing an activity means it was played to the end. Mastery states come from the assessment of many sessions and are shown separately.';

  @override
  String get masteryEvidenceTitle => 'Mastery evidence';

  @override
  String get activityCompletionTitle => 'Activity completion';

  @override
  String get recentPerformance => 'Recent performance';

  @override
  String accuracyPercent(String percent) {
    return '$percent% right on the first try';
  }

  @override
  String hintsPerRound(String hints) {
    return '$hints hints per round';
  }

  @override
  String get moveAdvance => 'Moved up a level';

  @override
  String get moveStay => 'Stayed at this level';

  @override
  String get moveRetreat => 'Easier level, more help';

  @override
  String get needsPractice => 'Areas to practise more';

  @override
  String get needsPracticeNone => 'Nothing stands out yet.';

  @override
  String get practiced => 'Practiced';

  @override
  String choiceLabel(String n) {
    return 'Choice $n';
  }

  @override
  String cardLabel(String n) {
    return 'Card $n';
  }

  @override
  String cardFaceLabel(String n, String picture) {
    return 'Card $n: $picture';
  }

  @override
  String get drumLabel => 'Drum';

  @override
  String get choiceTried => 'Already tried';

  @override
  String get retryNudge => 'So close! Let\'s try another one.';

  @override
  String get foundIt => 'We found it!';

  @override
  String get revealHere => 'Here it is! Let\'s tap it.';

  @override
  String get firstStepHint => 'Not this one. Now there are fewer to look at!';

  @override
  String get showHint => 'Look where my hand is pointing!';

  @override
  String get demoThisOne => 'Watch me: I\'d pick this one!';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get soundEffectsDesc =>
      'Gentle chimes and pops while playing. Everything is also shown on screen.';

  @override
  String get onARoll => 'You\'re on a roll!';

  @override
  String get withYou => 'I\'m right here with you. Let\'s look again together!';
}

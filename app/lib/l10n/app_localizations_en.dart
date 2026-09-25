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
}

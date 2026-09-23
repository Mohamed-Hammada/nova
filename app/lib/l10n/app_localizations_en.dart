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
}

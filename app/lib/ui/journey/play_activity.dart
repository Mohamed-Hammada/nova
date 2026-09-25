import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/play/session.dart';
import 'package:nova_app/providers.dart';

import '../game/game_catalog.dart';
import '../game/game_screen.dart';
import '../play/level_screen.dart';
import 'journey_providers.dart';
import 'stage_celebration.dart';

/// Plays one journey activity: checks it is open, records the start, runs
/// the game with only the configuration it needs (which game, which
/// pictures), records the finish, and -- if that finish completed the
/// stage -- celebrates and shows the adventure it unlocked.
Future<void> playJourneyActivity(BuildContext context, WidgetRef ref, Activity activity) async {
  final before = ref.read(journeyProgressProvider);
  if (before == null || !ref.read(curriculumEngineProvider).canStart(before, activity.id)) return;

  final recorder = ref.read(journeyRecorderProvider);
  await recorder.start(childId: currentChildId, activityId: activity.id);
  if (!context.mounted) return;

  final language = ref.read(languageProvider);
  final gameId = activity.gameFor(language);
  Future<void> finished(int stars, double accuracy) => recorder.finish(childId: currentChildId, activityId: activity.id, stars: stars, accuracy: accuracy);

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => playableGames.containsKey(gameId)
          ? GameScreen(
              gameId: gameId,
              skillId: ref.read(contentRuntimeProvider).game(gameId).primarySkillIds.first,
              onComplete: (accuracy) => finished(starsFor(accuracy), accuracy),
            )
          : LevelScreen(
              journey: Journey(id: 'journey.activity', nameKey: '', ageRange: [activity.minAge, activity.maxAge], levels: [activity.level]),
              levelIndex: 0,
              onFinished: finished,
            ),
    ),
  );

  ref.invalidate(activityRecordsProvider);
  ref.invalidate(levelStarsProvider);
  await ref.read(activityRecordsProvider.future);
  final after = ref.read(journeyProgressProvider);
  if (after == null || !context.mounted) return;
  final stageCompleted = after.currentIndex > before.currentIndex || (after.finished && !before.finished);
  if (stageCompleted) {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, _, _) => StageCelebration(completed: before.current.stage, next: after.finished ? null : after.current.stage),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }
}

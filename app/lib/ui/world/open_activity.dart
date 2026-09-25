import 'package:flutter/material.dart';
import 'package:nova_app/core/content/models.dart';

import '../game/game_catalog.dart';
import '../game/game_screen.dart';
import '../play/level_screen.dart';

/// Opens one activity outside the journey: games with their own dedicated
/// screen play there, every other game plays one free level.
Future<void> openActivity(BuildContext context, Game game) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => playableGames.containsKey(game.id)
            ? GameScreen(gameId: game.id, skillId: game.primarySkillIds.first)
            : LevelScreen(
                journey: Journey(id: 'journey.free', nameKey: '', ageRange: game.ageRange, levels: [JourneyLevel(id: 'free-${game.id}', gameId: game.id)]),
                levelIndex: 0,
              ),
      ),
    );

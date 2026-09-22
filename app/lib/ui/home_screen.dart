import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';

import 'game_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentRuntimeProvider);
    final game = content.game('game.math.bear-apples');
    final title = content.i18n(game.nameKey, 'en');

    return Scaffold(
      appBar: AppBar(title: const Text('Nova')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GameScreen(gameId: game.id, skillId: game.primarySkillIds.first)),
          ),
          child: Text(title),
        ),
      ),
    );
  }
}

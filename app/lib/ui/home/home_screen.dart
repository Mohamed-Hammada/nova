import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/game/game_catalog.dart';
import 'package:nova_app/ui/game/game_screen.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/progress/progress_screen.dart';
import 'package:nova_app/ui/shell/language_menu.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final games = ref.watch(playableGamesProvider);
    final theme = Theme.of(context);
    final compact = NovaWidthClass.of(context) == NovaWidthClass.compact;

    void openProgress() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProgressScreen()));

    return NovaPage(
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        ExcludeSemantics(child: Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 28)),
        const SizedBox(width: NovaSpace.xs),
        Flexible(child: Text(l10n.appTitle, style: theme.textTheme.headlineSmall, overflow: TextOverflow.ellipsis)),
      ]),
      actions: [
        const LanguageMenuButton(),
        compact
            ? IconButton(tooltip: l10n.grownUps, onPressed: openProgress, icon: const Icon(Icons.family_restroom_rounded))
            : NovaButton(label: l10n.grownUps, icon: Icons.family_restroom_rounded, variant: NovaButtonVariant.quiet, onPressed: openProgress),
      ],
      body: games.isEmpty
          ? NovaEmptyView(title: l10n.emptyGamesTitle, body: l10n.emptyGamesBody, icon: Icons.extension_rounded)
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: NovaSpace.lg),
              children: [
                Semantics(header: true, child: Text(l10n.homeGreeting, style: theme.textTheme.headlineMedium)),
                const SizedBox(height: NovaSpace.xs),
                Text(l10n.homeSubtitle, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: NovaSpace.lg),
                _GameGrid(games: games),
              ],
            ),
    );
  }
}

class _GameGrid extends StatelessWidget {
  const _GameGrid({required this.games});
  final List<Game> games;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // From the space actually available (the page caps content width),
      // not the window size: cards stay at least ~300dp wide.
      final columns = (constraints.maxWidth / 300).floor().clamp(1, 3);
      const gap = NovaSpace.md;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final game in games) SizedBox(width: width, child: _GameCard(game: game))],
      );
    });
  }
}

class _GameCard extends ConsumerWidget {
  const _GameCard({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentRuntimeProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = context.contentLanguage;
    final name = contentText(content, game.nameKey, language);
    final skillId = game.primarySkillIds.first;
    final skillName = contentText(content, content.skill(skillId).nameKey, language);

    return NovaCard(
      semanticLabel: '$name. ${l10n.playGame}',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => GameScreen(gameId: game.id, skillId: skillId)),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 150,
            color: theme.colorScheme.primaryContainer,
            alignment: Alignment.center,
            child: playableGames[game.id]!.cardArt(context),
          ),
          Padding(
            padding: const EdgeInsets.all(NovaSpace.lg),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: NovaSpace.xxs),
                  Text(skillName, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ),
              const SizedBox(width: NovaSpace.sm),
              // Visual affordance only: the whole card is the button.
              Container(
                width: NovaSize.childTouch,
                height: NovaSize.childTouch,
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                child: Icon(Icons.play_arrow_rounded, color: theme.colorScheme.onPrimary, size: 40),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

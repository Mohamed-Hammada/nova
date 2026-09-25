import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/game/game_catalog.dart';
import 'package:nova_app/ui/game/game_screen.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/characters/character_rig.dart';
import 'package:nova_app/ui/characters/character_view.dart';
import 'package:nova_app/ui/progress/progress_screen.dart';
import 'package:nova_app/ui/settings/face_play.dart';
import 'package:nova_app/ui/play/game_art.dart';
import 'package:nova_app/ui/play/journey_card.dart';
import 'package:nova_app/ui/play/level_screen.dart';
import 'package:nova_app/ui/settings/profile_screen.dart';
import 'package:nova_app/ui/shell/language_menu.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final band = ref.watch(ageBandProvider);
    final language = context.contentLanguage;
    // Games made for the child's age group and language; games with a
    // dedicated screen (the catalog) are always offered.
    final games = [
      for (final g in ref.watch(allPlayableGamesProvider))
        if (playableGames.containsKey(g.id) ||
            (band.overlaps(g.ageRange) && (g.languageDependencies.isEmpty || g.languageDependencies.contains(language))))
          g,
    ];
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
                const _Greeting(),
                const SizedBox(height: NovaSpace.lg),
                const JourneyCard(),
                const SizedBox(height: NovaSpace.lg),
                Semantics(header: true, child: Text(l10n.moreGames, style: theme.textTheme.titleLarge)),
                const SizedBox(height: NovaSpace.sm),
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
        MaterialPageRoute<void>(
          builder: (_) => playableGames.containsKey(game.id)
              ? GameScreen(gameId: game.id, skillId: skillId)
              : LevelScreen(
                  journey: Journey(id: 'journey.free', nameKey: '', ageRange: game.ageRange, levels: [JourneyLevel(id: 'free-${game.id}', gameId: game.id)]),
                  levelIndex: 0,
                ),
        ),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 150,
            color: theme.colorScheme.primaryContainer,
            alignment: Alignment.center,
            child: playableGames[game.id]?.cardArt(context) ?? gameArt(game, 150, language),
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

/// The child's companion says hello (by name, once the child has set one),
/// with the way into "About me".
class _Greeting extends ConsumerStatefulWidget {
  const _Greeting();

  @override
  ConsumerState<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends ConsumerState<_Greeting> {
  final _guide = CharacterController();

  @override
  void dispose() {
    _guide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final companion = ref.watch(companionProvider);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final name = rtl ? companion.displayNameAr : companion.displayName;
    final child = ref.watch(childNameProvider).trim();
    return Row(
      children: [
        SizedBox(
          width: 110,
          height: 124,
          child: Stack(children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _guide.react(Reaction.wave),
                child: CharacterView(key: ValueKey(companion), kind: companion, controller: _guide, entrance: Reaction.wave),
              ),
            ),
            PositionedDirectional(top: 0, end: 0, child: FacePlay(controller: _guide)),
          ]),
        ),
        const SizedBox(width: NovaSpace.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text(l10n.homeGreeting, style: theme.textTheme.headlineMedium)),
            const SizedBox(height: NovaSpace.xs),
            Text(
              child.isEmpty ? l10n.greeting(name) : l10n.greetingNamed(child, name),
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: NovaSpace.xxs),
            Text(l10n.homeSubtitle, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: NovaSpace.xs),
            NovaButton(
              label: l10n.aboutMe,
              icon: Icons.face_rounded,
              variant: NovaButtonVariant.quiet,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
            ),
          ]),
        ),
      ],
    );
  }
}

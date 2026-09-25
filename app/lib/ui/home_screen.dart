import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';

import 'age_picker.dart';
import 'characters/character_rig.dart';
import 'characters/character_view.dart';
import 'game_screen.dart';
import 'parent_view.dart';
import 'play/game_art.dart';
import 'play/journey_screen.dart';
import 'play/level_screen.dart';
import 'widgets/props.dart';
import 'scene/world_backdrop.dart';
import 'theme/age_band.dart';
import 'theme/nova_theme.dart';
import 'theme/strings.dart';
import 'widgets/game_card.dart';
import 'widgets/jelly_button.dart';
import 'widgets/speech_bubble.dart';

/// Bear's Apples keeps its dedicated screen (the original vertical slice);
/// every other game plays through the shared level screen.
const _bearApples = 'game.math.bear-apples';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _guide = CharacterController();

  @override
  void dispose() {
    _guide.dispose();
    super.dispose();
  }

  void _open(Game game) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, _, _) => game.id == _bearApples
            ? GameScreen(gameId: game.id, skillId: game.primarySkillIds.first)
            : LevelScreen(journey: Journey(id: 'journey.free', nameKey: '', ageRange: game.ageRange, levels: [JourneyLevel(id: 'free-${game.id}', gameId: game.id)]), levelIndex: 0),
        transitionsBuilder: (_, animation, _, child) {
          // A "zoom into the world" cut.
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween(begin: 1.15, end: 1.0).animate(curved), child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentRuntimeProvider);
    final band = ref.watch(ageBandProvider);
    final lang = ref.watch(languageProvider);
    final s = UiStrings.of(lang);
    final p = band.palette;
    final name = lang == 'ar' ? band.character.displayNameAr : band.character.displayName;

    final factory = ref.watch(trialFactoryProvider);
    bool playable(Game g) => g.id == _bearApples || factory.canPlay(g.id);
    final games = content.games
        .where((g) => band.overlaps(g.ageRange) && (g.languageDependencies.isEmpty || g.languageDependencies.contains(lang)))
        .toList()
      ..sort((a, b) => (playable(a) ? 0 : 1).compareTo(playable(b) ? 0 : 1));
    final hasJourney = content.journeyForAge(band.minAge) != null;

    return Scaffold(
      body: WorldBackdrop(
        world: band.world,
        groundLevel: 0.62,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth > box.maxHeight * 1.05;
              final cardWidth = (wide ? box.maxHeight * 0.4 : box.maxWidth * 0.56).clamp(180.0, 280.0) * (band.uiScale > 1.2 ? 1.08 : 1.0);

              final hero = GestureDetector(
                onTap: () => _guide.react(Reaction.wave),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: 40,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AspectRatio(
                          aspectRatio: 0.9,
                          child: CharacterView(key: ValueKey(band), kind: band.character, controller: _guide, rimColor: p.glow, entrance: Reaction.wave),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      end: 0,
                      child: Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: SpeechBubble(text: s.greeting(name), fontSize: 18 * band.uiScale),
                      ),
                    ),
                  ],
                ),
              );

              final shelf = SizedBox(
                height: cardWidth * 1.42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: games.length + (hasJourney ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(width: 20),
                  itemBuilder: (context, index) {
                    if (hasJourney && index == 0) {
                      return Center(
                        child: _Entrance(
                          delay: 0,
                          child: _JourneyCard(width: cardWidth, band: band, strings: s, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JourneyScreen()))),
                        ),
                      );
                    }
                    final i = index - (hasJourney ? 1 : 0);
                    final g = games[i];
                    return Center(
                      child: _Entrance(
                        delay: i * 90,
                        child: GameCard(
                          width: cardWidth,
                          title: content.i18n(g.nameKey, lang),
                          mechanicId: g.mechanicId,
                          palette: p,
                          playable: playable(g),
                          art: gameArt(g, cardWidth, lang),
                          playLabel: s.play,
                          comingSoonLabel: s.comingSoon,
                          ageLabel: '${g.ageRange.first}–${g.ageRange.last}',
                          onPlay: () => _open(g),
                        ),
                      ),
                    );
                  },
                ),
              );

              return Column(
                children: [
                  _TopBar(band: band, strings: s),
                  Expanded(
                    child: wide
                        ? Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Padding(padding: const EdgeInsets.fromLTRB(24, 8, 8, 24), child: hero),
                              ),
                              Expanded(flex: 6, child: Center(child: shelf)),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4), child: hero),
                              ),
                              shelf,
                              const SizedBox(height: 12),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.band, required this.strings});
  final AgeBand band;
  final UiStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = band.palette;
    final chipColor = p.isNight ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.75);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Who's playing: tap to switch age group / friend.
          Semantics(
            button: true,
            label: strings.pickYourAge,
            child: GestureDetector(
              onTap: () => showAgePicker(context),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 16, 4),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [shade(p.accent, 0.6), p.accent]),
                      ),
                      child: ClipOval(
                        child: OverflowBox(
                          maxHeight: 100,
                          maxWidth: 80,
                          alignment: const Alignment(0, -0.3),
                          child: SizedBox(width: 80, height: 100, child: CharacterPainterBox(kind: band.character)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(strings.bandTitle(band), style: novaText(17, weight: 800, color: p.isNight ? Colors.white : p.onSurface)),
                        Text(strings.ageYears(band), style: novaText(13, weight: 600, color: (p.isNight ? Colors.white : p.onSurface).withValues(alpha: 0.7))),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.expand_more_rounded, color: p.isNight ? Colors.white70 : p.onSurface.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          JellyButton(
            onPressed: () => ref.read(languageProvider.notifier).state = strings.isRtl ? 'en' : 'ar',
            color: const Color(0xFF7C6CF2),
            size: 44,
            semanticLabel: strings.isRtl ? 'English' : 'العربية',
            child: Text(strings.isRtl ? 'EN' : 'ع', style: novaText(18, weight: 800, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          _GrownUpsButton(strings: strings),
        ],
      ),
    );
  }
}

/// A static (non-animated) thumbnail of a character, for avatars.
class CharacterPainterBox extends StatelessWidget {
  const CharacterPainterBox({super.key, required this.kind});
  final CharacterKind kind;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: CharacterPainter(kind: kind, pose: const Pose(smile: 0.9)),
    size: Size.infinite,
  );
}

/// Opening the grown-ups area takes a deliberate press-and-hold, so a
/// child's stray tap does not leave the game.
class _GrownUpsButton extends StatefulWidget {
  const _GrownUpsButton({required this.strings});
  final UiStrings strings;

  @override
  State<_GrownUpsButton> createState() => _GrownUpsButtonState();
}

class _GrownUpsButtonState extends State<_GrownUpsButton> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hold.reset();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentView()));
      }
    });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.strings.holdToOpen,
      child: Semantics(
        button: true,
        label: '${widget.strings.grownUps}. ${widget.strings.holdToOpen}',
        child: GestureDetector(
          onTapDown: (_) => _hold.forward(),
          onTapUp: (_) => _hold.reverse(),
          onTapCancel: () => _hold.reverse(),
          child: AnimatedBuilder(
            animation: _hold,
            builder: (context, _) => SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.85),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF5B4A70)),
                  ),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(value: _hold.value, strokeWidth: 4, color: const Color(0xFF7C6CF2), backgroundColor: Colors.transparent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cards rise into place one after another when the screen opens.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.delay, required this.child});
  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final total = 700 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutBack),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 60 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

/// The way into the level map: the biggest, brightest card on the shelf.
class _JourneyCard extends ConsumerWidget {
  const _JourneyCard({required this.width, required this.band, required this.strings, required this.onTap});
  final double width;
  final AgeBand band;
  final UiStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = band.palette;
    final stars = ref.watch(levelStarsProvider).value ?? const <String, int>{};
    final done = stars.length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: width * 1.3,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [shade(p.accent, 0.25), p.accentDeep]),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: p.accentDeep.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 14))],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.map_rounded, size: width * 0.5, color: Colors.white.withValues(alpha: 0.25)),
                  Positioned(top: 8, left: 10, child: StarShape(size: width * 0.14)),
                  Positioned(bottom: 16, right: 12, child: StarShape(size: width * 0.1)),
                  Text('50', style: novaText(width * 0.3, weight: 800, color: Colors.white).copyWith(shadows: const [Shadow(blurRadius: 10, color: Color(0x55000000))])),
                ],
              ),
            ),
            Text(strings.journey, textAlign: TextAlign.center, style: novaText(width * 0.11, weight: 800, color: Colors.white)),
            Text(done == 0 ? strings.journeySub : strings.levelLabel(done + 1), style: novaText(width * 0.065, weight: 600, color: Colors.white.withValues(alpha: 0.9))),
            const SizedBox(height: 10),
            JellyButton(onPressed: onTap, color: const Color(0xFFFFB12E), icon: Icons.play_arrow_rounded, label: strings.play, size: width * 0.2),
          ],
        ),
      ),
    );
  }
}

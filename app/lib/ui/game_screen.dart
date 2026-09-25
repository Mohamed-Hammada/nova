import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/mechanics_flutter/drag_to_count_mechanic.dart';
import 'package:nova_app/providers.dart';

import 'characters/character_rig.dart';
import 'characters/character_view.dart';
import 'parent_view.dart';
import 'scene/world_backdrop.dart';
import 'theme/nova_theme.dart';
import 'theme/strings.dart';
import 'widgets/confetti.dart';
import 'widgets/jelly_button.dart';
import 'widgets/speech_bubble.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.gameId, required this.skillId});
  final String gameId;
  final String skillId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with SingleTickerProviderStateMixin {
  // A fixed request of 1 for this slice's single rung; varying it by the
  // adaptive-chosen rung's item_complexity anchor is Plan 2 polish.
  static const _requested = 1;

  late final DragToCountController _controller;
  final _events = <RawMechanicEvent>[];
  final _bear = CharacterController();
  final _bearKey = GlobalKey();

  /// Paces the celebration before moving on, so the child sees the payoff.
  late final AnimationController _finale = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  String? _line;
  int _confetti = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = DragToCountController(requestedTotal: _requested);
    // DragToCountView owns the mechanic's "Done" button (it calls
    // controller.submitTrial() itself); this screen reacts to the
    // resulting events rather than adding a second button.
    _controller.rawEvents.listen((event) {
      _events.add(event);
      if (event is ItemPlaced) _onItemPlaced();
      if (event is TrialSubmitted) _onTrialSubmitted(event);
    });
    _controller.start(rngSeed: 1);

    final content = ref.read(contentRuntimeProvider);
    final audio = ref.read(audioPortProvider);
    final game = content.game(widget.gameId);
    final asset = content.audioAsset(game.nameKey, ref.read(languageProvider));
    if (asset != null) audio.play(asset);
  }

  void _onItemPlaced() {
    _bear.lookAt(null);
    _bear.react(Reaction.eat);
    setState(() => _line = UiStrings.of(ref.read(languageProvider)).yum);
  }

  Future<void> _onTrialSubmitted(TrialSubmitted event) async {
    if (_finished) return;
    _finished = true;
    final s = UiStrings.of(ref.read(languageProvider));
    // Warm either way: a wrong count gets encouragement, never a buzzer.
    setState(() {
      _line = event.correct ? s.greatJob : s.tryAgainSoon;
      if (event.correct) _confetti++;
    });
    _bear.react(event.correct ? Reaction.cheer : Reaction.encourage);

    await Future.wait([
      ref
          .read(gameRuntimeProvider)
          .completeSession(
            childId: currentChildId,
            gameId: widget.gameId,
            skillId: widget.skillId,
            rawEvents: List.of(_events),
            mapper: bearApplesSignalMapper,
          ),
      _finale.forward().orCancel.catchError((_) {}),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => ParentView(skillId: widget.skillId, celebrate: event.correct),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  void _watchApple(Offset global) {
    final box = _bearKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(global);
    final head = Offset(box.size.width / 2, box.size.height * 0.3);
    final d = local - head;
    _bear.lookAt(Offset((d.dx / box.size.width * 2).clamp(-1.0, 1.0), (d.dy / box.size.height * 2).clamp(-1.0, 1.0)));
  }

  @override
  void dispose() {
    _controller.dispose();
    _bear.dispose();
    _finale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final band = ref.watch(ageBandProvider);
    final lang = ref.watch(languageProvider);
    final s = UiStrings.of(lang);
    final p = ref.watch(paletteProvider);
    final content = ref.watch(contentRuntimeProvider);
    final title = content.i18n(content.game(widget.gameId).nameKey, lang);

    return Scaffold(
      body: WorldBackdrop(
        world: ref.watch(worldProvider),
        groundLevel: 0.6,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        JellyButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          color: p.accent,
                          circle: true,
                          size: 48,
                          semanticLabel: s.home,
                          child: Icon(s.isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: p.isNight ? 0.14 : 0.8),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: novaText(20 * band.uiScale, weight: 800, color: p.isNight ? Colors.white : p.onSurface),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: DragToCountView(
                      controller: _controller,
                      appleCount: 1,
                      appleSize: 72 * band.uiScale,
                      doneLabel: s.isRtl ? 'تم' : 'Done',
                      onDragMove: _watchApple,
                      onDragEnd: () => _bear.lookAt(null),
                      host: LayoutBuilder(
                        builder: (context, box) {
                          final bearH = box.maxHeight * 0.92;
                          return Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              SizedBox(
                                key: _bearKey,
                                height: bearH,
                                width: bearH * 0.85,
                                child: CharacterView(kind: CharacterKind.bear, controller: _bear, rimColor: p.glow, entrance: Reaction.wave),
                              ),
                              PositionedDirectional(
                                top: 0,
                                start: box.maxWidth / 2 + bearH * 0.22,
                                end: 8,
                                child: Align(
                                  alignment: AlignmentDirectional.topStart,
                                  child: SpeechBubble(text: _line ?? s.giveApples(_requested), fontSize: 20 * band.uiScale),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: ConfettiBurst(play: _confetti, origin: const Alignment(0, -0.2)),
            ),
          ],
        ),
      ),
    );
  }
}

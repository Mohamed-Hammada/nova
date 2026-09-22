import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/mechanics_flutter/drag_to_count_mechanic.dart';
import 'package:nova_app/providers.dart';

import 'parent_view.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.gameId, required this.skillId});
  final String gameId;
  final String skillId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final DragToCountController _controller;
  final _events = <RawMechanicEvent>[];

  @override
  void initState() {
    super.initState();
    // A fixed request of 1 for this slice's single rung; varying it by the
    // adaptive-chosen rung's item_complexity anchor is Plan 2 polish.
    _controller = DragToCountController(requestedTotal: 1);
    // DragToCountView owns the mechanic's "Done" button (it calls
    // controller.submitTrial() itself); this screen reacts to the
    // resulting TrialSubmitted event rather than adding a second button.
    _controller.rawEvents.listen((event) {
      _events.add(event);
      if (event is TrialSubmitted) _onTrialSubmitted();
    });
    _controller.start(rngSeed: 1);

    final content = ref.read(contentRuntimeProvider);
    final audio = ref.read(audioPortProvider);
    final game = content.game(widget.gameId);
    final asset = content.audioAsset(game.nameKey, 'en');
    if (asset != null) audio.play(asset);
  }

  Future<void> _onTrialSubmitted() async {
    await ref.read(gameRuntimeProvider).completeSession(
          childId: currentChildId, gameId: widget.gameId, skillId: widget.skillId,
          rawEvents: List.of(_events), mapper: bearApplesSignalMapper,
        );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ParentView(skillId: widget.skillId)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bear\'s Apples')),
      body: DragToCountView(controller: _controller, appleCount: 1),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nova_app/ui/widgets/jelly_button.dart';
import 'package:nova_app/ui/widgets/props.dart';
import 'package:nova_app/core/mechanics/game_mechanic.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';

/// All counting logic lives here, in plain Dart -- unit-testable without
/// pumping a widget. DragToCountView below only turns gestures into calls
/// on this controller and renders the plate/apples.
///
/// This mechanic has no continuous animation loop -- it is a discrete
/// drag-and-drop interaction -- so it is implemented with plain Flutter
/// Draggable/DragTarget rather than Flame. Flame (declared as a dependency,
/// Task 4) remains the chosen engine for the app and is exercised starting
/// with a future continuous/timed mechanic (Plan 2's catch-target), where
/// its game-loop is what actually earns its keep.
class DragToCountController implements GameMechanic {
  DragToCountController({required this.requestedTotal, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final int requestedTotal;
  final DateTime Function() _now;
  final _controller = StreamController<RawMechanicEvent>.broadcast();

  int _runningTotal = 0;
  int _hintsThisTrial = 0;

  int get runningTotal => _runningTotal;

  @override
  String get mechanicId => 'drag-to-count';

  @override
  Stream<RawMechanicEvent> get rawEvents => _controller.stream;

  @override
  void start({required int rngSeed}) {
    _runningTotal = 0;
    _hintsThisTrial = 0;
  }

  /// Called when the child drags one apple onto the plate.
  void placeItem() {
    _runningTotal += 1;
    _controller.add(ItemPlaced(runningTotal: _runningTotal, requestedTotal: requestedTotal, usedHint: false, at: _now()));
  }

  void useHint() => _hintsThisTrial += 1;

  /// Called when the child taps "Done".
  void submitTrial() {
    final correct = _runningTotal == requestedTotal;
    _controller.add(TrialSubmitted(correct: correct, hintsUsedThisTrial: _hintsThisTrial, at: _now()));
  }

  @override
  void dispose() => _controller.close();
}

/// The drag-to-count stage: a shelf of apples, a plate to drop them on,
/// and a big "Done" button. Pure presentation -- every count goes through
/// [DragToCountController].
///
/// [host] (for example the bear) is drawn behind the plate, so apples are
/// visibly handed *to* someone. [onDragMove] reports the finger position
/// while an apple is carried, so the host can watch it.
class DragToCountView extends StatefulWidget {
  const DragToCountView({
    super.key,
    required this.controller,
    required this.appleCount,
    this.host,
    this.onDragMove,
    this.onDragEnd,
    this.appleSize = 72,
    this.doneLabel = 'Done',
    this.accent = const Color(0xFF34C77B),
  });

  final DragToCountController controller;
  final int appleCount;
  final Widget? host;
  final ValueChanged<Offset>? onDragMove;
  final VoidCallback? onDragEnd;
  final double appleSize;
  final String doneLabel;
  final Color accent;

  @override
  State<DragToCountView> createState() => _DragToCountViewState();
}

class _DragToCountViewState extends State<DragToCountView> {
  /// Which tray apples have been handed over, in the order they landed.
  final _placed = <int>[];

  void _accept(int index) {
    if (_placed.contains(index)) return;
    setState(() => _placed.add(index));
    widget.controller.placeItem();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appleSize;
    return Semantics(
      label: 'Drag apples onto the plate for the bear',
      child: LayoutBuilder(
        builder: (context, box) {
          final plateWidth = (box.maxWidth * 0.5).clamp(200.0, 360.0);
          return Column(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      if (widget.host != null) Positioned.fill(bottom: plateWidth * 0.18, child: widget.host!),
                      // Placing an item only counts when it is actually dropped on
                      // the plate -- Draggable.onDragEnd fires on ANY drag end
                      // regardless of where it lands, which previously counted a
                      // drag started and released anywhere on screen.
                      // DragTarget.onAcceptWithDetails only fires when the drop
                      // lands on this target.
                      DragTarget<int>(
                        onAcceptWithDetails: (d) => _accept(d.data),
                        builder: (context, candidate, rejected) => TweenAnimationBuilder<double>(
                          tween: Tween(end: candidate.isNotEmpty ? 1 : 0),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, glow, _) => Transform.scale(
                            scale: 1 + 0.06 * glow,
                            child: Plate3D(
                              width: plateWidth,
                              glow: glow,
                              child: _PlatedApples(count: _placed.length, appleSize: a * 0.8, plateWidth: plateWidth),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Shelf(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: a * 0.3,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < widget.appleCount; i++)
                      if (_placed.contains(i))
                        SizedBox(width: a, height: a)
                      else
                        Draggable<int>(
                          data: i,
                          onDragUpdate: widget.onDragMove == null ? null : (d) => widget.onDragMove!(d.globalPosition),
                          onDragEnd: (_) => widget.onDragEnd?.call(),
                          feedback: Transform.rotate(angle: -0.12, child: Apple3D(size: a * 1.25, lifted: true)),
                          childWhenDragging: SizedBox(
                            width: a,
                            height: a,
                            child: Opacity(opacity: 0.25, child: Apple3D(size: a)),
                          ),
                          child: _Wiggle(child: Apple3D(size: a)),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              JellyButton(
                onPressed: widget.controller.submitTrial,
                color: widget.accent,
                icon: Icons.check_rounded,
                label: widget.doneLabel,
                size: (a * 0.85).clamp(56.0, 84.0),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

/// Apples resting on the plate, each dropping in with a bounce.
class _PlatedApples extends StatelessWidget {
  const _PlatedApples({required this.count, required this.appleSize, required this.plateWidth});
  final int count;
  final double appleSize;
  final double plateWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < count; i++)
          Positioned(
            left: plateWidth / 2 - appleSize / 2 + ((i % 3) - 1) * appleSize * 0.7 + (i ~/ 3) * appleSize * 0.35,
            top: plateWidth * 0.21 - appleSize * 0.82 - (i ~/ 3) * appleSize * 0.35,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.bounceOut,
              builder: (context, v, child) => Transform.translate(offset: Offset(0, -80 * (1 - v)), child: child),
              child: Apple3D(size: appleSize),
            ),
          ),
      ],
    );
  }
}

/// A wooden shelf the apples sit on.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE2A969), Color(0xFFC07F3F), Color(0xFF8E5426)],
          stops: [0, 0.6, 1],
        ),
        border: Border.all(color: const Color(0xFFF3CB94), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x552A1640), blurRadius: 18, offset: Offset(0, 10)),
          BoxShadow(color: Color(0xFF6E3E1A), offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

/// A gentle one-time wiggle so apples say "pick me up" when they appear.
class _Wiggle extends StatelessWidget {
  const _Wiggle({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 900),
    builder: (context, v, child) => Transform.rotate(angle: 0.18 * (1 - v) * math.sin(v * math.pi * 6), child: child),
    child: child,
  );
}

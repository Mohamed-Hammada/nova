import 'dart:async';

import 'package:flutter/material.dart';
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

class DragToCountView extends StatelessWidget {
  const DragToCountView({super.key, required this.controller, required this.appleCount});
  final DragToCountController controller;
  final int appleCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Drag apples onto the plate for the bear',
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            children: [
              for (var i = 0; i < appleCount; i++)
                Draggable<int>(
                  data: i,
                  feedback: const _Apple(),
                  childWhenDragging: const SizedBox(width: 48, height: 48),
                  child: const _Apple(),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Placing an item only counts when it is actually dropped on the
          // plate -- Draggable.onDragEnd fires on ANY drag end regardless of
          // where it lands, which previously counted a drag started and
          // released anywhere on screen. DragTarget.onAcceptWithDetails only
          // fires when the drop lands on this target.
          DragTarget<int>(
            onAcceptWithDetails: (_) => controller.placeItem(),
            builder: (context, candidate, rejected) => const _Plate(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: controller.submitTrial, child: const Text('Done')),
        ],
      ),
    );
  }
}

class _Apple extends StatelessWidget {
  const _Apple();
  @override
  Widget build(BuildContext context) =>
      Container(width: 48, height: 48, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle));
}

class _Plate extends StatelessWidget {
  const _Plate();
  @override
  Widget build(BuildContext context) => Container(width: 200, height: 80, color: Colors.brown.shade100);
}

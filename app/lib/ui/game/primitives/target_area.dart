import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';
import 'package:nova_app/ui/game/art/game_art.dart';


/// An illustrated drop target container (e.g. picnic basket, plate) with 2.5D
/// visual depth, squash-and-stretch receiving reaction, and full accessibility semantics.
class TargetArea extends StatefulWidget {
  const TargetArea({
    super.key,
    required this.containerId,
    required this.enabled,
    required this.semanticLabel,
    required this.emptyLabel,
    required this.onAccept,
    required this.onWillAccept,
    required this.itemCount,
    required this.content,
    this.header,
    this.minWidth,
  });

  final String containerId;
  final bool enabled;
  final String semanticLabel;
  final String emptyLabel;
  final ValueChanged<int> onAccept;
  final bool Function(int itemId) onWillAccept;
  final int itemCount;
  final Widget content;
  final Widget? header;
  final double? minWidth;

  @override
  State<TargetArea> createState() => _TargetAreaState();
}

class _TargetAreaState extends State<TargetArea> with SingleTickerProviderStateMixin {
  late final AnimationController _jiggleController;
  late final Animation<double> _scaleXAnimation;
  late final Animation<double> _scaleYAnimation;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.itemCount;
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleXAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.98), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _jiggleController, curve: Curves.easeOut));

    _scaleYAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.03), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _jiggleController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant TargetArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != _lastCount) {
      _lastCount = widget.itemCount;
      if (!NovaMotion.reduced(context)) {
        _jiggleController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _jiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      key: const ValueKey('drag-to-count.plate'),
      onWillAcceptWithDetails: (d) => widget.enabled && widget.onWillAccept(d.data),
      onAcceptWithDetails: (d) => widget.onAccept(d.data),
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;

        Widget targetVisual = GameArt.container(
          containerId: widget.containerId,
          highlighted: highlighted,
          child: widget.content,
        );

        if (!NovaMotion.reduced(context)) {
          targetVisual = AnimatedBuilder(
            animation: _jiggleController,
            builder: (context, child) => Transform.scale(
              scaleX: _scaleXAnimation.value,
              scaleY: _scaleYAnimation.value,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
            child: targetVisual,
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.header != null) widget.header!,
            Semantics(
              container: true,
              label: widget.semanticLabel,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: widget.minWidth ?? 240,
                ),
                child: targetVisual,
              ),
            ),
          ],
        );
      },
    );
  }
}

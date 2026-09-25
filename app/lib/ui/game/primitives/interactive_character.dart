import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';
import 'package:nova_app/ui/game/art/game_art.dart';

import 'game_animation.dart';

/// An interactive, expressive children's game companion widget.
///
/// Features:
/// - Supports all 6 visual states: [idle], [thinking], [encourage], [happy],
///   [celebrate], [confused].
/// - Ambient breathing & organic posture transitions.
/// - Active gameplay gestures: pointing towards interactive items, greeting pop-in.
/// - Companion delight: child can tap the companion directly for a joyful bounce
///   reaction without affecting learning evidence or scoring.
/// - Attached request/speech bubble for pre-readers (numeral + fruit icon).
/// - Respects [NovaMotion.reduced] for full accessibility.
class InteractiveCharacter extends StatefulWidget {
  const InteractiveCharacter({
    super.key,
    required this.characterId,
    required this.state,
    required this.semanticLabel,
    this.size = 120,
    this.requestWidget,
    this.pointing = false,
    this.pointingDirection = AxisDirection.down,
    this.onTapCompanion,
  });

  final String characterId;
  final CharacterVisualState state;
  final String semanticLabel;
  final double size;
  final Widget? requestWidget;
  final bool pointing;
  final AxisDirection pointingDirection;
  final VoidCallback? onTapCompanion;

  @override
  State<InteractiveCharacter> createState() => _InteractiveCharacterState();
}

class _InteractiveCharacterState extends State<InteractiveCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final Animation<double> _breathingAnimation;

  late final AnimationController _hopController;
  late final Animation<double> _hopAnimation;

  bool _tappedJoyfully = false;

  @override
  void initState() {
    super.initState();

    // Subtle breathing cycle
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _breathingAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: GameAnimation.breatheCurve),
    );

    // Companion interaction hop
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _hopAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _hopController, curve: Curves.easeOut));

    _cycleBreathing();
  }

  void _cycleBreathing() {
    if (!mounted) return;
    _breathingController.forward().then((_) {
      if (mounted) {
        _breathingController.reverse();
      }
    });
  }

  void _playHop() {
    if (!mounted) return;
    if (!NovaMotion.reduced(context)) {
      _hopController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == CharacterVisualState.happy ||
          widget.state == CharacterVisualState.celebrate ||
          widget.state == CharacterVisualState.encourage) {
        _playHop();
      } else {
        _cycleBreathing();
      }
    }
  }

  Timer? _delightTimer;

  @override
  void dispose() {
    _delightTimer?.cancel();
    _breathingController.dispose();
    _hopController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _delightTimer?.cancel();
    setState(() => _tappedJoyfully = true);
    _playHop();
    widget.onTapCompanion?.call();

    _delightTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _tappedJoyfully = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = NovaMotion.reduced(context);

    Widget art = GameArt.character(
      characterId: widget.characterId,
      state: widget.state,
      size: widget.size,
      animate: true,
    );

    if (!reduced) {
      art = AnimatedBuilder(
        animation: Listenable.merge([_breathingAnimation, _hopAnimation]),
        builder: (context, child) {
          final scale = _hopController.isAnimating
              ? _hopAnimation.value
              : _breathingAnimation.value;
          return Transform.scale(
            scaleY: scale,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        },
        child: art,
      );
    }

    // Interactive companion touch target
    Widget interactiveBody = InkResponse(
      onTap: _handleTap,
      radius: widget.size * 0.6,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          art,
          if (_tappedJoyfully && !reduced)
            PositionedDirectional(
              top: -8,
              end: 4,
              child: GameArt.feedback(effectId: 'sparkle', size: 28),
            ),
        ],
      ),
    );

    // Gesturing / pointing indicator (for hints or demonstration)
    Widget? pointingIndicator;
    if (widget.pointing && !reduced) {
      pointingIndicator = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (context, val, child) {
          final nudge = (val < 0.5 ? val : 1.0 - val) * 12.0;
          return Transform.translate(
            offset: Offset(0, nudge),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(NovaSpace.xxs),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    final rowContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            interactiveBody,
            if (pointingIndicator != null) ...[
              const SizedBox(height: NovaSpace.xxs),
              pointingIndicator,
            ],
          ],
        ),
        if (widget.requestWidget != null) ...[
          const SizedBox(width: NovaSpace.sm),
          widget.requestWidget!,
        ],
      ],
    );

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: rowContent,
    );
  }
}

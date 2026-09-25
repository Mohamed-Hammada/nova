import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';
import 'package:nova_app/ui/game/art/game_art.dart';

/// Reusable visual feedback effects (star bursts, sparkles, hint highlights).
class FeedbackEffect extends StatefulWidget {
  const FeedbackEffect({
    super.key,
    required this.active,
    this.effectId = 'star_gold',
  });

  final bool active;
  final String effectId;

  @override
  State<FeedbackEffect> createState() => _FeedbackEffectState();
}

class _FeedbackEffectState extends State<FeedbackEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.active) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant FeedbackEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || NovaMotion.reduced(context)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final opacity = (1.0 - t).clamp(0.0, 1.0);

          return Stack(
            children: [
              for (int i = 0; i < 8; i++)
                _buildParticle(i, t, opacity),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index, double progress, double opacity) {
    final angle = index * (math.pi / 4) + (_random.nextDouble() * 0.2);
    final distance = 40.0 + progress * 100.0;
    final dx = distance * math.cos(angle);
    final dy = distance * math.sin(angle) - (progress * 30.0); // Slight upward float
    final scale = (1.0 - progress * 0.4).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: GameArt.feedback(
              effectId: index.isEven ? 'star_gold' : 'sparkle',
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

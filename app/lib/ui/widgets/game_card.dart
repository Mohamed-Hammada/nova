import 'package:flutter/material.dart';

import '../theme/age_band.dart';
import '../theme/nova_theme.dart';
import 'jelly_button.dart';
import 'props.dart';

/// A tactile game card: tilts toward the finger in 3D while pressed, with a
/// lit illustration panel, the game name, and a play button (or a lock for
/// games whose mechanic is not built yet).
class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.title,
    required this.mechanicId,
    required this.palette,
    required this.playable,
    required this.playLabel,
    required this.comingSoonLabel,
    required this.ageLabel,
    required this.onPlay,
    this.width = 230,
  });

  final String title;
  final String mechanicId;
  final WorldPalette palette;
  final bool playable;
  final String playLabel;
  final String comingSoonLabel;
  final String ageLabel;
  final VoidCallback onPlay;
  final double width;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  Offset _tilt = Offset.zero;

  void _updateTilt(Offset local) {
    final w = widget.width, h = widget.width * 1.3;
    setState(() => _tilt = Offset((local.dx / w - 0.5) * 2, (local.dy / h - 0.5) * 2));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final w = widget.width;
    final surface = p.isNight ? const Color(0xFF2A2360) : Colors.white;
    final text = p.isNight ? Colors.white : const Color(0xFF3A2A4A);

    // Raw pointer events drive the tilt so the card never competes with the
    // carousel's scroll gesture; only the tap goes through the arena.
    return Listener(
      onPointerDown: (e) => _updateTilt(e.localPosition),
      onPointerMove: (e) => _updateTilt(e.localPosition),
      onPointerUp: (_) => setState(() => _tilt = Offset.zero),
      onPointerCancel: (_) => setState(() => _tilt = Offset.zero),
      child: GestureDetector(
        onTap: widget.playable ? widget.onPlay : null,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(end: _tilt),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, tilt, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-tilt.dy * 0.12)
              ..rotateY(tilt.dx * 0.12),
            child: child,
          ),
          child: Opacity(
            opacity: widget.playable ? 1 : 0.82,
            child: Container(
              width: w,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: p.isNight ? 0.15 : 0.9), width: 2),
                boxShadow: [
                  BoxShadow(color: shade(p.accentDeep, -0.5).withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 16)),
                  BoxShadow(color: p.accent.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: w * 0.62,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [shade(p.accent, 0.55), shade(p.accent, 0.1)],
                              ),
                            ),
                          ),
                          Positioned(
                            left: -w * 0.2,
                            right: -w * 0.2,
                            bottom: -w * 0.18,
                            height: w * 0.36,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: shade(p.hillNear, 0.15), borderRadius: BorderRadius.all(Radius.elliptical(w, w * 0.2))),
                            ),
                          ),
                          _GameArt(mechanicId: widget.mechanicId, width: w),
                          if (!widget.playable)
                            Container(
                              color: Colors.black.withValues(alpha: 0.25),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                                child: Icon(Icons.lock_rounded, size: w * 0.14, color: const Color(0xFF6B5A7A)),
                              ),
                            ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20)),
                              child: Text(widget.ageLabel, style: novaText(13, weight: 700, color: p.accentDeep)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: novaText(w * 0.1, weight: 800, color: text),
                  ),
                  const SizedBox(height: 8),
                  if (widget.playable)
                    JellyButton(onPressed: widget.onPlay, color: p.accent, icon: Icons.play_arrow_rounded, label: widget.playLabel, size: w * 0.2)
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: w * 0.05),
                      child: Text(widget.comingSoonLabel, style: novaText(w * 0.075, weight: 700, color: text.withValues(alpha: 0.6))),
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

class _GameArt extends StatelessWidget {
  const _GameArt({required this.mechanicId, required this.width});
  final String mechanicId;
  final double width;

  @override
  Widget build(BuildContext context) {
    final w = width;
    if (mechanicId == 'drag-to-count') {
      return Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: w * 0.06,
            child: Plate3D(width: w * 0.62),
          ),
          Positioned(
            bottom: w * 0.14,
            left: w * 0.24,
            child: Apple3D(size: w * 0.2),
          ),
          Positioned(
            bottom: w * 0.15,
            left: w * 0.38,
            child: Apple3D(size: w * 0.22),
          ),
          Positioned(
            bottom: w * 0.26,
            left: w * 0.3,
            child: Apple3D(size: w * 0.2),
          ),
          Positioned(
            top: w * 0.08,
            right: w * 0.1,
            child: _NumberBadge(text: '3', size: w * 0.2),
          ),
        ],
      );
    }
    // Generic art: a numeral card with a group of dots.
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: w * 0.12,
          top: w * 0.12,
          child: _NumberBadge(text: '4', size: w * 0.26),
        ),
        Positioned(
          right: w * 0.12,
          bottom: w * 0.1,
          child: Wrap(spacing: 6, runSpacing: 6, children: [for (var i = 0; i < 4; i++) _Dot(size: w * 0.09)]),
        ),
      ],
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.text, required this.size});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(center: Alignment(-0.35, -0.4), colors: [Color(0xFFFFF4B8), Color(0xFFFFC83D), Color(0xFFE08A00)], stops: [0, 0.5, 1]),
      boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 8, offset: Offset(0, 4))],
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Text(text, style: novaText(size * 0.55, weight: 800, color: const Color(0xFF7A3E00))),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(center: Alignment(-0.35, -0.4), colors: [Color(0xFFB9F1FF), Color(0xFF28B8E8), Color(0xFF0F6FA0)], stops: [0, 0.5, 1]),
    ),
  );
}

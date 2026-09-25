import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';
import 'package:nova_app/ui/game/art/game_art.dart';

import 'game_animation.dart';

/// An interactive in-game object (e.g. apple, pear) with dual drag & tap interaction,
/// settle bounce animation, count badge support, and full accessibility semantics.
class InteractiveObject extends StatelessWidget {
  const InteractiveObject({
    super.key,
    required this.id,
    required this.objectId,
    required this.enabled,
    required this.label,
    required this.actionHint,
    required this.onActivate,
    this.size = NovaSize.gameItem,
    this.badge,
    this.visual,
    this.onPlate = false,
  });

  final int id;
  final String objectId;
  final bool enabled;
  final String label;
  final String actionHint;
  final VoidCallback onActivate;
  final double size;
  final String? badge;
  final Widget? visual;
  final bool onPlate;

  @override
  Widget build(BuildContext context) {
    final art = visual ?? GameArt.object(objectId: objectId, size: size);

    final visualStack = Stack(
      clipBehavior: Clip.none,
      children: [
        art,
        if (badge != null)
          PositionedDirectional(
            top: -4,
            end: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badge!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
      ],
    );

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: badge == null ? label : '$label, $badge',
      hint: actionHint,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: enabled ? onActivate : null,
          radius: size * 0.6,
          child: ExcludeSemantics(
            child: GameAnimation.settleBounce(
              key: ValueKey('settle-$id-$onPlate'),
              context: context,
              child: Padding(
                padding: const EdgeInsets.all(NovaSpace.xxs),
                child: visualStack,
              ),
            ),
          ),
        ),
      ),
    );

    if (!enabled) return button;

    return Draggable<int>(
      data: id,
      feedback: Material(
        type: MaterialType.transparency,
        child: Transform.scale(
          scale: 1.15,
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: art,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: Padding(
          padding: const EdgeInsets.all(NovaSpace.xxs),
          child: art,
        ),
      ),
      child: button,
    );
  }
}

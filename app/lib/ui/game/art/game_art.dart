import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';

import 'vector_painters.dart';

/// The visual state or emotional posture of an in-game character.
enum CharacterVisualState {
  idle,
  thinking,
  encourage,
  happy,
  celebrate,
  confused; // gentle_retry

  static CharacterVisualState fromString(String state) {
    switch (state.toLowerCase().replaceAll('-', '_')) {
      case 'happy':
      case 'success':
        return CharacterVisualState.happy;
      case 'thinking':
      case 'help':
        return CharacterVisualState.thinking;
      case 'encourage':
      case 'support':
      case 'encouraging':
        return CharacterVisualState.encourage;
      case 'celebrating':
      case 'celebrate':
        return CharacterVisualState.celebrate;
      case 'confused':
      case 'retry':
      case 'gentle_retry':
        return CharacterVisualState.confused;
      case 'idle':
      case 'waiting':
      default:
        return CharacterVisualState.idle;
    }
  }
}

/// Central registry and widget resolver for all illustrated game art assets.
/// Provides offline, child-friendly illustrated scenes with dual-mode rendering:
/// local high-resolution PNG assets with vector CustomPainter fallbacks.
class GameArt {
  const GameArt._();

  static const String _artBase = 'assets/art';

  // --- Asset path helpers ---

  static String characterAsset(String characterId, CharacterVisualState state) {
    final stateName = switch (state) {
      CharacterVisualState.idle => 'idle',
      CharacterVisualState.thinking => 'thinking',
      CharacterVisualState.encourage => 'encourage',
      CharacterVisualState.happy => 'happy',
      CharacterVisualState.celebrate => 'celebrate',
      CharacterVisualState.confused => 'confused',
    };
    return '$_artBase/characters/${characterId}_$stateName.png';
  }

  static String environmentAsset(String environmentId) {
    final id = switch (environmentId) {
      'forest_clearing' => 'forest_clearing_bg',
      'sun' => 'sun_warm',
      'cloud' => 'cloud_fluffy',
      _ => environmentId,
    };
    return '$_artBase/environments/$id.png';
  }

  static String objectAsset(String objectId) => '$_artBase/objects/$objectId.png';

  static String feedbackAsset(String effectId) => '$_artBase/feedback/$effectId.png';

  /// Preloads standard game raster art into Flutter's image cache for instant, flicker-free rendering.
  static Future<void> preload(BuildContext context, {String characterId = 'bear'}) async {
    final imagesToPrecache = [
      characterAsset(characterId, CharacterVisualState.idle),
      characterAsset(characterId, CharacterVisualState.happy),
      characterAsset(characterId, CharacterVisualState.thinking),
      characterAsset(characterId, CharacterVisualState.encourage),
      characterAsset(characterId, CharacterVisualState.celebrate),
      characterAsset(characterId, CharacterVisualState.confused),
      objectAsset('apple'),
      objectAsset('pear'),
      objectAsset('basket'),
      objectAsset('basket_rim'),
      environmentAsset('forest_clearing_bg'),
      environmentAsset('tree_branch'),
      environmentAsset('picnic_blanket'),
      environmentAsset('cloud_fluffy'),
      environmentAsset('sun_warm'),
      feedbackAsset('star_gold'),
      feedbackAsset('sparkle'),
    ];

    for (final path in imagesToPrecache) {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {
        // Fallbacks silently handle any missing raster assets via CustomPainters
      }
    }
  }

  // --- Widget Builders ---

  /// Renders a character (e.g. bear, bunny, penguin) in the requested visual state.
  static Widget character({
    Key? key,
    required String characterId,
    required CharacterVisualState state,
    double size = 120,
    bool animate = true,
  }) {
    return _CharacterWidget(
      key: key,
      characterId: characterId,
      state: state,
      size: size,
      animate: animate,
    );
  }

  /// Renders an in-game interactive object (e.g. apple, pear, acorn, carrot).
  static Widget object({
    Key? key,
    required String objectId,
    double size = NovaSize.gameItem,
  }) {
    return _ObjectWidget(
      key: key,
      objectId: objectId,
      size: size,
    );
  }

  /// Renders an environment element or background (e.g. forest_clearing_bg, tree_branch, picnic_blanket).
  static Widget environment({
    Key? key,
    required String environmentId,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return _EnvironmentWidget(
      key: key,
      environmentId: environmentId,
      width: width,
      height: height,
      fit: fit,
    );
  }

  /// Renders a target container (e.g. picnic basket, plate, treasure chest).
  static Widget container({
    Key? key,
    required String containerId,
    required bool highlighted,
    required Widget child,
    bool frontOnly = false,
    double? width,
    double? height,
  }) {
    return _ContainerWidget(
      key: key,
      containerId: containerId,
      highlighted: highlighted,
      frontOnly: frontOnly,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Renders a feedback decoration (e.g. star_gold, sparkle, confetti).
  static Widget feedback({
    Key? key,
    required String effectId,
    double size = 48,
  }) {
    return _FeedbackWidget(
      key: key,
      effectId: effectId,
      size: size,
    );
  }
}

class _CharacterWidget extends StatelessWidget {
  const _CharacterWidget({
    super.key,
    required this.characterId,
    required this.state,
    required this.size,
    required this.animate,
  });

  final String characterId;
  final CharacterVisualState state;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final assetPath = GameArt.characterAsset(characterId, state);
    final fallbackPainter = VectorArtPainters.characterPainter(characterId, state);

    Widget art = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => CustomPaint(
        size: Size.square(size),
        painter: fallbackPainter,
      ),
    );

    if (animate && !NovaMotion.reduced(context)) {
      final isBouncing = state == CharacterVisualState.happy || state == CharacterVisualState.celebrate;
      art = AnimatedScale(
        scale: isBouncing ? 1.08 : 1.0,
        duration: NovaMotion.of(context, NovaMotion.medium),
        curve: NovaMotion.emphasized,
        child: art,
      );
    }

    return SizedBox.square(dimension: size, child: art);
  }
}

class _ObjectWidget extends StatelessWidget {
  const _ObjectWidget({
    super.key,
    required this.objectId,
    required this.size,
  });

  final String objectId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = GameArt.objectAsset(objectId);
    final fallbackPainter = VectorArtPainters.objectPainter(objectId);

    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => CustomPaint(
          size: Size.square(size),
          painter: fallbackPainter,
        ),
      ),
    );
  }
}

class _EnvironmentWidget extends StatelessWidget {
  const _EnvironmentWidget({
    super.key,
    required this.environmentId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String environmentId;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final assetPath = GameArt.environmentAsset(environmentId);
    final fallbackPainter = VectorArtPainters.environmentPainter(environmentId);

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: fallbackPainter),
      ),
    );
  }
}

class _ContainerWidget extends StatelessWidget {
  const _ContainerWidget({
    super.key,
    required this.containerId,
    required this.highlighted,
    required this.child,
    this.frontOnly = false,
    this.width,
    this.height,
  });

  final String containerId;
  final bool highlighted;
  final Widget child;
  final bool frontOnly;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rimColor = highlighted ? theme.colorScheme.primary : NovaPalette.plateRim;

    if (containerId == 'basket') {
      final assetPath = GameArt.objectAsset(frontOnly ? 'basket_rim' : 'basket');
      return AnimatedContainer(
        duration: NovaMotion.of(context, NovaMotion.short),
        curve: NovaMotion.curve,
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NovaRadius.lg),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => CustomPaint(
                  painter: VectorArtPainters.basketPainter(highlighted: highlighted, frontOnly: frontOnly),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NovaSpace.lg, vertical: NovaSpace.md),
              child: child,
            ),
          ],
        ),
      );
    }

    // Default plate/mat container
    return AnimatedContainer(
      duration: NovaMotion.of(context, NovaMotion.short),
      curve: NovaMotion.curve,
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: NovaPalette.plate,
        shape: StadiumBorder(side: BorderSide(color: rimColor, width: highlighted ? 6 : 4)),
        shadows: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: NovaSpace.lg, vertical: NovaSpace.md),
      child: child,
    );
  }
}

class _FeedbackWidget extends StatelessWidget {
  const _FeedbackWidget({
    super.key,
    required this.effectId,
    required this.size,
  });

  final String effectId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = GameArt.feedbackAsset(effectId);
    final fallbackPainter = VectorArtPainters.feedbackPainter(effectId);

    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => CustomPaint(
          size: Size.square(size),
          painter: fallbackPainter,
        ),
      ),
    );
  }
}

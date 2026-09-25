import 'package:flutter/widgets.dart';

/// How much visual richness to draw. Low suits older or slower phones and
/// saves battery; High is the full look.
enum GraphicsQuality {
  low,
  balanced,
  high;

  /// Floating particles in the background worlds.
  int get particles => switch (this) {
    low => 0,
    balanced => 12,
    high => 22,
  };

  /// Drifting clouds.
  int get clouds => switch (this) {
    low => 2,
    balanced => 4,
    high => 5,
  };

  /// Sun rays, nebula glow, shooting stars, rainbow.
  bool get skyEffects => this != low;

  /// Rim light and ground bounce light on characters.
  bool get fullLighting => this == high;

  /// Rim light only (no bounce) on characters.
  bool get rimLight => this != low;

  /// Background worlds keep moving (clouds drift, stars twinkle).
  bool get animatedBackdrop => this != low;

  int get confetti => switch (this) {
    low => 30,
    balanced => 60,
    high => 90,
  };
}

/// Makes the chosen [GraphicsQuality] available to painters below it.
class Graphics extends InheritedWidget {
  const Graphics({super.key, required this.quality, required super.child});
  final GraphicsQuality quality;

  static GraphicsQuality of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Graphics>()?.quality ?? GraphicsQuality.high;

  @override
  bool updateShouldNotify(Graphics old) => old.quality != quality;
}

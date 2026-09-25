import 'package:flutter/widgets.dart';

/// Whether looping, decorative animation (breathing characters, drifting
/// clouds, twinkling stars) should run.
///
/// Off when the platform asks for reduced motion, and switchable for tests
/// -- widget tests settle by waiting for animation to stop, which a looping
/// idle animation never does. One-shot reactions (a cheer, a bounce) always
/// play, because they carry feedback, not decoration.
class AmbientMotion extends InheritedWidget {
  const AmbientMotion({super.key, required this.enabled, required super.child});

  final bool enabled;

  static bool of(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final scope = context.dependOnInheritedWidgetOfExactType<AmbientMotion>();
    return !reduce && (scope?.enabled ?? !_underTest);
  }

  /// Widget tests that pump a single widget have no scope; looping idle
  /// motion would keep them from ever settling, so it defaults off there
  /// (the app itself always provides a scope).
  static final bool _underTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  bool updateShouldNotify(AmbientMotion oldWidget) => oldWidget.enabled != enabled;
}

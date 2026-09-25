import 'package:flutter/material.dart';

import '../tokens.dart';

/// Where the child is in a session: one dot per step. Completed steps are
/// filled and carry a check, the current step is larger and ringed, upcoming
/// steps are hollow -- so position reads by shape and size, not colour alone.
/// Screen readers get [semanticLabel] (e.g. "Question 2 of 6") instead of the
/// dots.
class NovaStepDots extends StatelessWidget {
  const NovaStepDots({super.key, required this.total, required this.current, required this.semanticLabel});

  final int total;

  /// Zero-based index of the step in progress; `total` means all are done.
  final int current;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = NovaMotion.of(context, NovaMotion.medium);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Wrap(
        spacing: NovaSpace.xs,
        runSpacing: NovaSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: duration,
              curve: NovaMotion.curve,
              width: i == current ? 26 : 18,
              height: i == current ? 26 : 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < current ? scheme.primary : scheme.surfaceContainerLowest,
                border: Border.all(color: i <= current ? scheme.primary : scheme.outline, width: i == current ? 4 : 2),
              ),
              child: i < current ? Icon(Icons.check_rounded, size: 12, color: scheme.onPrimary) : null,
            ),
        ],
      ),
    );
  }
}

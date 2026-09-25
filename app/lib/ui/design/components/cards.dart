import 'package:flutter/material.dart';

import '../tokens.dart';

/// A rounded, outlined surface. With [onTap] the whole card is one
/// focusable, keyboard-activatable button whose semantics label is
/// [semanticLabel] (so a screen reader announces one meaningful action, not
/// every text fragment inside the card).
class NovaCard extends StatelessWidget {
  const NovaCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(NovaSpace.lg),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(NovaRadius.lg);
    final content = Padding(padding: padding, child: child);
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Semantics(
              button: true,
              label: semanticLabel,
              excludeSemantics: semanticLabel != null,
              child: InkWell(onTap: onTap, borderRadius: radius, child: content),
            ),
    );
  }
}

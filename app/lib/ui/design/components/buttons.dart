import 'package:flutter/material.dart';

import '../tokens.dart';

enum NovaButtonVariant { primary, secondary, quiet }

enum NovaButtonSize {
  /// For grown-up surfaces: the 48dp platform minimum.
  standard,

  /// For anything a child taps during play: 64dp, larger label.
  child,
}

/// The one button Nova uses. It wraps Material's buttons, so keyboard focus,
/// Enter/Space activation, hover, and screen-reader semantics come from the
/// framework rather than being re-implemented; a null [onPressed] renders
/// the disabled state.
class NovaButton extends StatelessWidget {
  const NovaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = NovaButtonVariant.primary,
    this.size = NovaButtonSize.standard,
    this.expand = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NovaButtonVariant variant;
  final NovaButtonSize size;

  /// Fill the available width (e.g. the main action of a narrow screen).
  final bool expand;

  /// Take keyboard focus when shown (e.g. the action that appears with
  /// feedback, so Enter continues without hunting for it).
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isChild = size == NovaButtonSize.child;
    final height = isChild ? NovaSize.childTouch : NovaSize.minTouch;
    final textStyle = isChild
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.labelLarge;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(expand ? double.infinity : height, height)),
      textStyle: WidgetStatePropertyAll(textStyle),
      iconSize: WidgetStatePropertyAll(isChild ? 28 : 22),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: isChild ? NovaSpace.xl : NovaSpace.lg)),
    );
    final text = Text(label, textAlign: TextAlign.center);
    final iconWidget = icon == null ? null : Icon(icon);

    return switch (variant) {
      NovaButtonVariant.primary => iconWidget == null
          ? FilledButton(onPressed: onPressed, autofocus: autofocus, style: style, child: text)
          : FilledButton.icon(onPressed: onPressed, autofocus: autofocus, style: style, icon: iconWidget, label: text),
      NovaButtonVariant.secondary => iconWidget == null
          ? OutlinedButton(onPressed: onPressed, autofocus: autofocus, style: style, child: text)
          : OutlinedButton.icon(onPressed: onPressed, autofocus: autofocus, style: style, icon: iconWidget, label: text),
      NovaButtonVariant.quiet => iconWidget == null
          ? TextButton(onPressed: onPressed, autofocus: autofocus, style: style, child: text)
          : TextButton.icon(onPressed: onPressed, autofocus: autofocus, style: style, icon: iconWidget, label: text),
    };
  }
}

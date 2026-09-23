import 'package:flutter/material.dart';

import '../tokens.dart';

/// The page frame every Nova screen uses: an app bar, safe-area padding, and
/// a body centred and capped at a readable width on tablets, desktop and
/// web, with gutters that grow with the window. All padding is directional,
/// so the frame mirrors correctly under RTL.
class NovaPage extends StatelessWidget {
  const NovaPage({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions = const [],
    this.maxWidth = NovaSize.maxContentWidth,
    this.bottom,
  });

  final Widget body;
  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final double maxWidth;

  /// Pinned below the body (e.g. the game's action bar), inside the same
  /// width cap.
  final Widget? bottom;

  static double gutterFor(NovaWidthClass widthClass) => switch (widthClass) {
        NovaWidthClass.compact => NovaSpace.md,
        NovaWidthClass.medium => NovaSpace.lg,
        NovaWidthClass.expanded => NovaSpace.xl,
      };

  @override
  Widget build(BuildContext context) {
    final gutter = gutterFor(NovaWidthClass.of(context));
    // Top-anchored, not centred: content that is shorter than the window
    // (a scroll view shrink-wraps) stays under the app bar instead of
    // floating mid-screen and jumping as its height changes.
    Widget capped(Widget child) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: gutter), child: child),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: title,
        leading: leading,
        actions: [...actions, SizedBox(width: gutter - NovaSpace.xs)],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: capped(body)),
            if (bottom != null)
              capped(Padding(padding: const EdgeInsets.only(top: NovaSpace.xs, bottom: NovaSpace.md), child: bottom)),
          ],
        ),
      ),
    );
  }
}

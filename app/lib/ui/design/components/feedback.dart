import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

enum NovaFeedbackKind { success, retry, info, error }

/// A feedback message that never relies on colour alone: every kind has its
/// own icon shape and its message is always written out. It is a live
/// region, so screen readers announce it when it appears.
class NovaFeedbackBanner extends StatelessWidget {
  const NovaFeedbackBanner({super.key, required this.kind, required this.message, this.action});

  final NovaFeedbackKind kind;
  final String message;

  /// Optional action (e.g. a "Next" button), beside the message when there
  /// is room and below it on narrow screens.
  final Widget? action;

  static IconData iconFor(NovaFeedbackKind kind) => switch (kind) {
        NovaFeedbackKind.success => Icons.check_circle_rounded,
        NovaFeedbackKind.retry => Icons.replay_circle_filled_rounded,
        NovaFeedbackKind.info => Icons.info_rounded,
        NovaFeedbackKind.error => Icons.error_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final colors = NovaFeedbackColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, iconColor) = switch (kind) {
      NovaFeedbackKind.success => (colors.successContainer, colors.onSuccessContainer, colors.success),
      NovaFeedbackKind.retry => (colors.retryContainer, colors.onRetryContainer, colors.retry),
      NovaFeedbackKind.info => (colors.infoContainer, colors.onInfoContainer, scheme.primary),
      NovaFeedbackKind.error => (scheme.errorContainer, scheme.onErrorContainer, scheme.error),
    };

    final text = Semantics(
      liveRegion: true,
      child: Text(message, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: foreground)),
    );
    final messageRow = Row(children: [
      Icon(iconFor(kind), color: iconColor, size: 36),
      const SizedBox(width: NovaSpace.sm),
      Expanded(child: text),
    ]);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(NovaRadius.lg),
        border: Border.all(color: iconColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NovaSpace.md),
        child: action == null
            ? messageRow
            : LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [messageRow, const SizedBox(height: NovaSpace.sm), action!],
                  );
                }
                return Row(children: [Expanded(child: messageRow), const SizedBox(width: NovaSpace.md), action!]);
              }),
      ),
    );
  }
}

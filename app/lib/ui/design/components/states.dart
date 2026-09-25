import 'package:flutter/material.dart';

import '../tokens.dart';
import 'buttons.dart';

/// A full-area loading state with a written message (not a bare spinner).
class NovaLoadingView extends StatelessWidget {
  const NovaLoadingView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(dimension: 48, child: CircularProgressIndicator(strokeWidth: 5)),
            const SizedBox(height: NovaSpace.lg),
            Text(message, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Shared layout for empty and error states: icon, title, body, one action.
class NovaMessageView extends StatelessWidget {
  const NovaMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(NovaSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 72, color: iconColor ?? theme.colorScheme.primary)),
              const SizedBox(height: NovaSpace.lg),
              Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              ),
              if (body != null) ...[
                const SizedBox(height: NovaSpace.sm),
                Text(
                  body!,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: NovaSpace.xl),
                NovaButton(label: actionLabel!, onPressed: onAction, icon: Icons.refresh_rounded),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NovaEmptyView extends StatelessWidget {
  const NovaEmptyView({super.key, required this.title, this.body, this.icon = Icons.inbox_rounded});
  final String title;
  final String? body;
  final IconData icon;

  @override
  Widget build(BuildContext context) => NovaMessageView(icon: icon, title: title, body: body);
}

class NovaErrorView extends StatelessWidget {
  const NovaErrorView({super.key, required this.title, this.message, this.retryLabel, this.onRetry});
  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => NovaMessageView(
        icon: Icons.error_outline_rounded,
        iconColor: Theme.of(context).colorScheme.error,
        title: title,
        body: message,
        actionLabel: retryLabel,
        onAction: onRetry,
      );
}

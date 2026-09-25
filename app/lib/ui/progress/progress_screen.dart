import 'package:nova_app/ui/settings/grown_up_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/shell/language_menu.dart';

/// The mastery states in order. `null` ("Not yet") is before the first.
const masteryLadder = ['emerging', 'developing', 'secure', 'transfer'];

String masteryLabel(AppLocalizations l10n, String? state) => switch (state) {
      'emerging' => l10n.masteryEmerging,
      'developing' => l10n.masteryDeveloping,
      'secure' => l10n.masterySecure,
      'transfer' => l10n.masteryTransfer,
      _ => l10n.masteryNotYet,
    };

String masteryDescription(AppLocalizations l10n, String? state) => switch (state) {
      'emerging' => l10n.masteryEmergingDescription,
      'developing' => l10n.masteryDevelopingDescription,
      'secure' => l10n.masterySecureDescription,
      'transfer' => l10n.masteryTransferDescription,
      _ => l10n.masteryNotYetDescription,
    };

/// For grown-ups: each skill the playable games assess, with its current
/// mastery state as the engines computed it. Read-only; presentation only.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final skillIds = {for (final game in ref.watch(allPlayableGamesProvider)) ...game.primarySkillIds}.toList();

    return NovaPage(
      title: Text(l10n.progressTitle),
      actions: const [LanguageMenuButton()],
      maxWidth: 820,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: NovaSpace.lg),
        children: [
          Text(l10n.progressIntro, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: NovaSpace.md),
          // Every threshold behind these states is provisional (curriculum
          // spec 3.5/3.6), and Nova's claims are non-clinical.
          NovaFeedbackBanner(kind: NovaFeedbackKind.info, message: l10n.progressDisclaimer),
          const SizedBox(height: NovaSpace.lg),
          for (final skillId in skillIds) ...[
            _SkillProgressCard(skillId: skillId),
            const SizedBox(height: NovaSpace.md),
          ],
          const SizedBox(height: NovaSpace.md),
          const GrownUpSettings(),
        ],
      ),
    );
  }
}

class _SkillProgressCard extends ConsumerWidget {
  const _SkillProgressCard({required this.skillId});
  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final content = ref.watch(contentRuntimeProvider);
    final skill = content.skill(skillId);
    final language = context.contentLanguage;
    final mastery = ref.watch(masteryProvider(skillId));

    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(contentText(content, skill.nameKey, language), style: theme.textTheme.titleLarge)),
          const SizedBox(height: NovaSpace.xxs),
          Text(
            contentText(content, skill.descriptionKey, language),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: NovaSpace.md),
          switch (mastery) {
            AsyncData(:final value) => _MasteryView(record: value),
            AsyncError() => Row(children: [
                Expanded(child: Text(l10n.progressLoadFailed, style: theme.textTheme.bodyLarge)),
                NovaButton(
                  label: l10n.retry,
                  variant: NovaButtonVariant.secondary,
                  onPressed: () => ref.invalidate(masteryProvider(skillId)),
                ),
              ]),
            _ => const Padding(
                padding: EdgeInsets.all(NovaSpace.sm),
                child: Center(child: SizedBox.square(dimension: 28, child: CircularProgressIndicator())),
              ),
          },
        ],
      ),
    );
  }
}

class _MasteryView extends StatelessWidget {
  const _MasteryView({required this.record});
  final MasteryRecord? record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = record?.state;
    final reached = state == null ? 0 : masteryLadder.indexOf(state) + 1;
    final stepText = l10n.masteryStepOf(NovaNumbers.format(context, reached), NovaNumbers.format(context, masteryLadder.length));

    return Semantics(
      label: '${masteryLabel(l10n, state)}. $stepText. ${masteryDescription(l10n, state)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(masteryLabel(l10n, state), style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: NovaSpace.xxs),
          Text(masteryDescription(l10n, state), style: theme.textTheme.bodyLarge),
          const SizedBox(height: NovaSpace.md),
          _Ladder(reached: reached),
        ],
      ),
    );
  }
}

/// The four states as steps; reached ones are filled with a check and
/// labelled, so the position reads without relying on colour.
class _Ladder extends StatelessWidget {
  const _Ladder({required this.reached});
  final int reached;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: NovaSpace.xs,
      runSpacing: NovaSpace.xs,
      children: [
        for (var i = 0; i < masteryLadder.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: NovaSpace.sm, vertical: NovaSpace.xs),
            decoration: BoxDecoration(
              color: i < reached ? scheme.primaryContainer : scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(NovaRadius.pill),
              border: Border.all(color: i < reached ? scheme.primary : scheme.outlineVariant, width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                i < reached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: i < reached ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: NovaSpace.xxs),
              Text(
                masteryLabel(l10n, masteryLadder[i]),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: i < reached ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                    ),
              ),
            ]),
          ),
      ],
    );
  }
}

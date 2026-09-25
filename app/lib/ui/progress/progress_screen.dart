import 'package:nova_app/ui/settings/grown_up_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/journey/journey_labels.dart';
import 'package:nova_app/ui/journey/journey_providers.dart';
import 'package:nova_app/ui/play/visual_view.dart';
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
      // Every card is built (not lazily), so a screen reader -- and a grown-up
      // searching the page -- can reach all of it.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: NovaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.progressIntro, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: NovaSpace.md),
            // Every threshold behind these states is provisional (curriculum
            // spec 3.5/3.6), and Nova's claims are non-clinical.
            NovaFeedbackBanner(kind: NovaFeedbackKind.info, message: l10n.progressDisclaimer),
            const SizedBox(height: NovaSpace.lg),
            // Mastery evidence: the assessment pipeline's view, skill by skill.
            Semantics(header: true, child: Text(l10n.masteryEvidenceTitle, style: theme.textTheme.titleLarge)),
            const SizedBox(height: NovaSpace.sm),
            for (final skillId in skillIds) ...[_SkillProgressCard(skillId: skillId), const SizedBox(height: NovaSpace.md)],
            const _JourneyReport(),
            const SizedBox(height: NovaSpace.md),
            const GrownUpSettings(),
          ],
        ),
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
          Text(contentText(content, skill.descriptionKey, language), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: NovaSpace.md),
          switch (mastery) {
            AsyncData(:final value) => _MasteryView(record: value),
            AsyncError() => Row(
              children: [
                Expanded(child: Text(l10n.progressLoadFailed, style: theme.textTheme.bodyLarge)),
                NovaButton(label: l10n.retry, variant: NovaButtonVariant.secondary, onPressed: () => ref.invalidate(masteryProvider(skillId))),
              ],
            ),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(i < reached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 20, color: i < reached ? scheme.primary : scheme.outline),
                const SizedBox(width: NovaSpace.xxs),
                Flexible(
                  child: Text(masteryLabel(l10n, masteryLadder[i]), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: i < reached ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// For grown-ups: where the child is in the journey, how the developmental
/// areas are covered so far (a share of activities, not a score), and

/// For grown-ups: the child's age and place in the journey, what has been
/// completed (kept apart from mastery evidence, above), how recent sessions
/// went and how the Adaptive Engine responded, and areas that could use
/// more practice. Descriptive only: not a score and not a diagnosis.
class _JourneyReport extends ConsumerWidget {
  const _JourneyReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(journeyProgressProvider);
    if (progress == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final content = ref.watch(contentRuntimeProvider);
    final lang = ref.watch(languageProvider);
    final curriculum = ref.watch(curriculumProvider);
    final records = [...?ref.watch(activityRecordsProvider).value?.values]..sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    final stage = progress.current;
    final completedStages = [
      for (final s in progress.stages)
        if (s.status == StageStatus.completed) contentText(content, s.stage.nameKey, lang),
    ];
    String gameName(String activityId) {
      final a = curriculum.activity(activityId);
      if (a == null) return activityId;
      final id = a.gameFor(lang);
      return content.hasGame(id) ? contentText(content, content.game(id).nameKey, lang) : id;
    }

    final practiceAreas = {
      for (final r in records)
        if (r.struggled && curriculum.activity(r.activityId) != null) domainLabel(l10n, curriculum.activity(r.activityId)!.domain),
    };
    String moveLabel(AdaptiveMove m) => switch (m) {
      AdaptiveMove.advance => l10n.moveAdvance,
      AdaptiveMove.stay => l10n.moveStay,
      AdaptiveMove.retreat => l10n.moveRetreat,
    };

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: NovaSpace.md, bottom: NovaSpace.xs),
      child: Semantics(header: true, child: Text(text, style: theme.textTheme.titleMedium)),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: NovaSpace.md),
      child: NovaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(l10n.journeyStage, style: theme.textTheme.titleLarge)),
            const SizedBox(height: NovaSpace.xxs),
            Text(l10n.reportAge('${numeral(progress.profile.age, lang)} ${l10n.yearsOld}'), style: theme.textTheme.bodyLarge),
            Text(
              '${contentText(content, stage.stage.nameKey, lang)} · ${l10n.stageDoneCount(numeral(stage.requiredDone, lang), numeral(stage.requiredTotal, lang))}',
              style: theme.textTheme.bodyLarge,
            ),
            heading(l10n.completedStages),
            Text(completedStages.isEmpty ? l10n.noneYet : completedStages.join(' · '), style: theme.textTheme.bodyMedium),
            heading(l10n.activityCompletionTitle),
            Text(l10n.completionNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: NovaSpace.xs),
            for (final d in progress.domains)
              Padding(
                padding: const EdgeInsets.only(bottom: NovaSpace.xs),
                child: Row(
                  children: [
                    SizedBox(width: 150, child: Text(domainLabel(l10n, d.domain), style: theme.textTheme.bodyMedium)),
                    Expanded(
                      child: Semantics(
                        label: '${domainLabel(l10n, d.domain)}: ${numeral(d.done, lang)} / ${numeral(d.total, lang)}',
                        excludeSemantics: true,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(NovaRadius.pill),
                          child: LinearProgressIndicator(value: d.fraction, minHeight: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: NovaSpace.xs),
                    Text('${numeral(d.done, lang)}/${numeral(d.total, lang)}', style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
            Text(l10n.areasNote, style: theme.textTheme.bodySmall),
            heading(l10n.recentPerformance),
            if (records.isEmpty) Text(l10n.noHistoryYet, style: theme.textTheme.bodyMedium),
            for (final r in records.take(12))
              if (curriculum.activity(r.activityId) case final a?)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(r.completed ? Icons.check_circle_rounded : Icons.timelapse_rounded, color: r.completed ? NovaPalette.success : theme.colorScheme.outline),
                  title: Text(gameName(a.id)),
                  subtitle: Text(
                    [
                      '${domainLabel(l10n, a.domain)} · ${r.completed ? l10n.practiced : roleLabel(l10n, a.role)} · ${l10n.playedTimes(numeral(r.attempts, lang))}',
                      if (r.lastAccuracy != null) l10n.accuracyPercent(numeral((r.lastAccuracy! * 100).round(), lang)),
                      if (r.lastHintsPerTrial != null) l10n.hintsPerRound(r.lastHintsPerTrial!.toStringAsFixed(1)),
                      if (r.lastMove != null) moveLabel(r.lastMove!),
                    ].join('\n'),
                  ),
                  isThreeLine: r.lastMove != null,
                ),
            heading(l10n.needsPractice),
            Text(practiceAreas.isEmpty ? l10n.needsPracticeNone : practiceAreas.join(' · '), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

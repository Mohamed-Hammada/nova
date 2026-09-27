import 'package:nova_app/ui/settings/grown_up_settings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/skills/endcore.dart';
import 'package:nova_app/core/skills/error_types.dart';
import 'package:nova_app/core/skills/skill_profile.dart';
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

/// A skill's profile for the local child, through GameRuntime: all its
/// sessions' evidence, accumulated. Invalidated after each session.
final skillProfileProvider = FutureProvider.autoDispose.family<SkillProfile, String>((ref, skillId) {
  return ref.watch(gameRuntimeProvider).skillProfile(childId: currentChildId, skillId: skillId);
});

String trendLabel(AppLocalizations l10n, Trend t) => switch (t) {
  Trend.improving => l10n.trendImproving,
  Trend.steady => l10n.trendSteady,
  Trend.declining => l10n.trendDeclining,
  Trend.unknown => l10n.trendUnknown,
};

String? independenceLabel(AppLocalizations l10n, Independence i) => switch (i) {
  Independence.independent => l10n.independenceIndependent,
  Independence.occasionalHelp => l10n.independenceOccasional,
  Independence.needsHelp => l10n.independenceNeedsHelp,
  Independence.unknown => null,
};

String confidenceLabel(AppLocalizations l10n, double c) => c < 0.45 ? l10n.confidenceEarly : (c < 0.75 ? l10n.confidenceGrowing : l10n.confidenceGood);

String errorLabel(AppLocalizations l10n, String type) => switch (type) {
  ErrorType.overCount => l10n.errOverCount,
  ErrorType.underCount => l10n.errUnderCount,
  ErrorType.wrongObject => l10n.errWrongObject,
  ErrorType.distractorSelected => l10n.errDistractor,
  ErrorType.choseSmaller => l10n.errChoseSmaller,
  ErrorType.choseBigger => l10n.errChoseBigger,
  ErrorType.sequenceBreak => l10n.errSequenceBreak,
  ErrorType.impulsiveResponse => l10n.errImpulsive,
  ErrorType.missedTarget => l10n.errMissedTarget,
  ErrorType.rulePerseveration => l10n.errPerseveration,
  ErrorType.repeatedError => l10n.errRepeated,
  ErrorType.passiveResponse => l10n.errPassive,
  ErrorType.aggressiveResponse => l10n.errAggressive,
  ErrorType.unkindResponse => l10n.errUnkind,
  ErrorType.selfFocused => l10n.errSelfFocused,
  _ => type,
};

String selectionReasonLabel(AppLocalizations l10n, SelectionReason r) => switch (r) {
  SelectionReason.nextRequired => l10n.reasonNextRequired,
  SelectionReason.practiceMissingSkill => l10n.reasonPracticeMissingSkill,
  SelectionReason.addressRepeatedError => l10n.reasonRepeatedError,
  SelectionReason.buildIndependence => l10n.reasonIndependence,
  SelectionReason.reinforceSecureSkill => l10n.reasonReinforce,
  SelectionReason.transferProbe => l10n.reasonTransfer,
  SelectionReason.stretch => l10n.reasonStretch,
  SelectionReason.tryAgainEasier => l10n.reasonTryAgain,
  SelectionReason.variety => l10n.reasonVariety,
  SelectionReason.review => l10n.reasonReview,
};

/// For grown-ups: each skill the playable games assess, described from all
/// the evidence so far -- state, trend, confidence, independence, practice
/// history, transfer and recurring mistakes. Descriptive, never a score.
/// Presentation only.
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
            const CommunicationSkillsGrid(),
            const SizedBox(height: NovaSpace.lg),
            const JapaneseMathMethods(),
            const SizedBox(height: NovaSpace.lg),
            // Mastery evidence: the assessment pipeline's view, skill by skill.
            Semantics(header: true, child: Text(l10n.masteryEvidenceTitle, style: theme.textTheme.titleLarge)),
            const SizedBox(height: NovaSpace.xxs),
            Text(l10n.skillProfileNote, style: theme.textTheme.bodySmall),
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
            AsyncData(:final value) => Builder(builder: (context) {
              final profile = ref.watch(skillProfileProvider(skillId)).value;
              // The profile is the whole evidence (including a grown-up's
              // report of a home task); the stored record is the fallback.
              final record = profile != null && (profile.hasEvidence || profile.transferEvidence > 0) && value != null
                  ? MasteryRecord(childId: value.childId, skillId: skillId, state: profile.state.key, confidence: profile.confidence, updatedAt: value.updatedAt)
                  : value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MasteryView(record: record),
                  if (profile != null) _ProfileView(skillId: skillId, profile: profile),
                ],
              );
            }),
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

/// The child's communication and social skills on the ENDCORE map
/// (Fujimoto & Daibo, 2007): the basic skills underneath, the skills for
/// getting on with others above, in expressing, understanding and managing
/// columns. Each cell names the state its games have shown so far.
class CommunicationSkillsGrid extends ConsumerWidget {
  const CommunicationSkillsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profiles = ref.watch(childEvidenceProvider).value?.profiles ?? const <String, SkillProfile>{};
    String name(EndcoreSkill s) => switch (s) {
      EndcoreSkill.expressivity => l10n.commExpressivity,
      EndcoreSkill.decoding => l10n.commDecoding,
      EndcoreSkill.selfControl => l10n.commSelfControl,
      EndcoreSkill.assertion => l10n.commAssertion,
      EndcoreSkill.otherAcceptance => l10n.commOtherAcceptance,
      EndcoreSkill.relationships => l10n.commRelationships,
    };
    String column(EndcoreSystem s) => switch (s) {
      EndcoreSystem.expressing => l10n.commExpressing,
      EndcoreSystem.understanding => l10n.commUnderstanding,
      EndcoreSystem.managing => l10n.commManaging,
    };

    Widget cell(EndcoreSkill skill) {
      final c = EndcoreCell.from(skill, profiles);
      final state = c.state;
      final label = state == null ? l10n.commNoEvidence : masteryLabel(l10n, state.key);
      final filled = state != null && state.index >= SkillState.developing.index;
      return Semantics(
        label: '${name(skill)}: $label',
        excludeSemantics: true,
        child: Container(
          key: ValueKey('endcore.${skill.name}'),
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(NovaSpace.xs),
          decoration: BoxDecoration(
            color: filled ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(NovaRadius.md),
            border: Border.all(color: state == null ? theme.colorScheme.outlineVariant : theme.colorScheme.primary, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name(skill), style: theme.textTheme.labelLarge),
              const SizedBox(height: NovaSpace.xxs),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    Widget row(EndcoreLevel level) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 72, child: Padding(padding: const EdgeInsets.only(top: NovaSpace.xs), child: Text(level == EndcoreLevel.basic ? l10n.commBasic : l10n.commInterpersonal, style: theme.textTheme.labelMedium))),
        for (final system in EndcoreSystem.values) ...[
          const SizedBox(width: NovaSpace.xxs),
          Expanded(child: cell(EndcoreSkill.at(level, system))),
        ],
      ],
    );

    return NovaCard(
      key: const ValueKey('progress.communication'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(l10n.commSkillsTitle, style: theme.textTheme.titleLarge)),
          const SizedBox(height: NovaSpace.xxs),
          Text(l10n.commSkillsIntro, style: theme.textTheme.bodySmall),
          const SizedBox(height: NovaSpace.sm),
          Row(
            children: [
              const SizedBox(width: 72),
              for (final system in EndcoreSystem.values) ...[
                const SizedBox(width: NovaSpace.xxs),
                Expanded(child: Text(column(system), textAlign: TextAlign.center, style: theme.textTheme.labelMedium)),
              ],
            ],
          ),
          const SizedBox(height: NovaSpace.xxs),
          // The skills for getting on with others sit on the basic ones.
          row(EndcoreLevel.interpersonal),
          const SizedBox(height: NovaSpace.xxs),
          row(EndcoreLevel.basic),
        ],
      ),
    );
  }
}

/// For grown-ups: the Japanese ways of learning number Nova's math games
/// follow, each with the game that practises it and something to try at
/// home (docs/product/japanese-math-methods-ar.md has the sources).
class JapaneseMathMethods extends StatelessWidget {
  const JapaneseMathMethods({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final methods = [
      (Icons.grid_on_rounded, l10n.jpMakeTenTitle, l10n.jpMakeTenBody),
      (Icons.call_split_rounded, l10n.jpCherryTitle, l10n.jpCherryBody),
      (Icons.view_week_rounded, l10n.jpTapeTitle, l10n.jpTapeBody),
      (Icons.linear_scale_rounded, l10n.jpPathTitle, l10n.jpPathBody),
    ];
    return NovaCard(
      key: const ValueKey('progress.japaneseMath'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(l10n.jpMathTitle, style: theme.textTheme.titleLarge)),
          const SizedBox(height: NovaSpace.xxs),
          Text(l10n.jpMathIntro, style: theme.textTheme.bodySmall),
          for (final (icon, title, body) in methods)
            Padding(
              padding: const EdgeInsets.only(top: NovaSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: NovaSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        Text(body, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What the evidence says about the skill, line by line: trend,
/// independence, confidence, practice history, transfer and any mistake
/// that keeps coming back. With a secure skill and a probe task for it, a
/// grown-up can report how the task went at home (transfer evidence).
class _ProfileView extends ConsumerStatefulWidget {
  const _ProfileView({required this.skillId, required this.profile});
  final String skillId;
  final SkillProfile profile;

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<_ProfileView> {
  bool _reported = false;

  Future<void> _report(bool passed) async {
    await ref.read(gameRuntimeProvider).recordTransferProbe(childId: currentChildId, skillId: widget.skillId, passed: passed);
    ref.invalidate(masteryProvider(widget.skillId));
    ref.invalidate(skillProfileProvider(widget.skillId));
    ref.invalidate(childEvidenceProvider);
    if (mounted) setState(() => _reported = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    if (!p.hasEvidence) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lang = ref.watch(languageProvider);
    final content = ref.watch(contentRuntimeProvider);
    final independence = independenceLabel(l10n, p.independence);
    final transfer = p.state == SkillState.transfer || p.transferEvidence > 0
        ? l10n.transferShown
        : (p.readyForTransfer ? l10n.transferReady : l10n.transferNotYet);
    final homeTasks = {
      for (final g in content.gamesForSkill(widget.skillId))
        for (final probe in g.transferProbes)
          if (probe.skillId == widget.skillId)
            if (content.probeTarget(probe.taskRef) case TransferTask task) contentText(content, task.nameKey, lang),
    };

    Widget line(IconData icon, String text, {Key? key}) => Padding(
      key: key,
      padding: const EdgeInsets.only(top: NovaSpace.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: NovaSpace.xs),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: NovaSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(
            switch (p.trend) {
              Trend.improving => Icons.trending_up_rounded,
              Trend.declining => Icons.trending_down_rounded,
              _ => Icons.trending_flat_rounded,
            },
            trendLabel(l10n, p.trend),
            key: ValueKey('profile.${widget.skillId}.trend'),
          ),
          if (independence != null) line(Icons.front_hand_rounded, independence),
          line(Icons.verified_rounded, confidenceLabel(l10n, p.confidence)),
          line(
            Icons.history_rounded,
            l10n.practiceHistory(numeral(p.sessions, lang), numeral(p.attempts, lang), numeral(p.contexts.length, lang)),
            key: ValueKey('profile.${widget.skillId}.history'),
          ),
          if (p.lastPracticed != null) line(Icons.event_rounded, l10n.lastPracticed(DateFormat.MMMd(lang).format(p.lastPracticed!))),
          line(Icons.swap_horiz_rounded, transfer),
          for (final e in p.repeatedErrors) line(Icons.replay_rounded, l10n.repeatedError(errorLabel(l10n, e))),
          if (p.selfCorrections > 0) line(Icons.auto_fix_high_rounded, l10n.selfCorrected(numeral(p.selfCorrections, lang))),
          if ((p.readyForTransfer || _reported) && homeTasks.isNotEmpty) ...[
            const SizedBox(height: NovaSpace.sm),
            for (final task in homeTasks) Text(l10n.tryAtHome(task), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: NovaSpace.xs),
            if (_reported)
              Text(l10n.tryAtHomeThanks, style: theme.textTheme.bodyMedium)
            else
              Wrap(
                spacing: NovaSpace.xs,
                runSpacing: NovaSpace.xs,
                children: [
                  NovaButton(key: ValueKey('probe.${widget.skillId}.passed'), label: l10n.tryAtHomeDidIt, icon: Icons.thumb_up_rounded, onPressed: () => _report(true)),
                  NovaButton(label: l10n.tryAtHomeNotYet, variant: NovaButtonVariant.secondary, onPressed: () => _report(false)),
                ],
              ),
          ],
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
            if (progress.recommendation?.why case final why?) ...[
              const SizedBox(height: NovaSpace.sm),
              Text(l10n.whyNext(selectionReasonLabel(l10n, why.reason)), key: const ValueKey('progress.whyNext'), style: theme.textTheme.bodyMedium),
            ],
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

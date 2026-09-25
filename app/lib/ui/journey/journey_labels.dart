import 'package:flutter/material.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/journey/journey_models.dart';

import '../design/nova_design.dart';
import '../l10n.dart';
import '../widgets/props.dart';

String activityStatusLabel(AppLocalizations l10n, ActivityStatus s) => switch (s) {
      ActivityStatus.locked => l10n.statusLocked,
      ActivityStatus.available => l10n.statusAvailable,
      ActivityStatus.recommended => l10n.statusNext,
      ActivityStatus.completed => l10n.statusCompleted,
      ActivityStatus.mastered => l10n.statusMastered,
    };

String roleLabel(AppLocalizations l10n, LevelRole r) => switch (r) {
      LevelRole.required => l10n.roleRequired,
      LevelRole.practice => l10n.rolePractice,
      LevelRole.challenge => l10n.roleChallenge,
      LevelRole.optional => l10n.roleOptional,
      LevelRole.review => l10n.roleReview,
    };

String domainLabel(AppLocalizations l10n, DevelopmentalDomain d) => switch (d) {
      DevelopmentalDomain.socialEmotional => l10n.domainSocialEmotional,
      DevelopmentalDomain.language => l10n.domainLanguage,
      DevelopmentalDomain.earlyLiteracy => l10n.domainEarlyLiteracy,
      DevelopmentalDomain.auditory => l10n.domainAuditory,
      DevelopmentalDomain.numeracy => l10n.domainNumeracy,
      DevelopmentalDomain.memory => l10n.domainMemory,
      DevelopmentalDomain.attention => l10n.domainAttention,
      DevelopmentalDomain.problemSolving => l10n.domainProblemSolving,
    };

/// The small round badge that marks an activity's or a stage's state, the
/// same everywhere in the journey: a tick, a glowing "next" star, a lock.
class JourneyBadge extends StatelessWidget {
  const JourneyBadge({super.key, required this.status, this.size = 40});
  final ActivityStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      ActivityStatus.completed => (NovaStory.yes, Icons.check_rounded),
      ActivityStatus.mastered => (NovaStory.honey, Icons.workspace_premium_rounded),
      ActivityStatus.recommended => (NovaStory.coral, Icons.play_arrow_rounded),
      ActivityStatus.locked => (NovaStory.inkSoft, Icons.lock_rounded),
      ActivityStatus.available => (NovaStory.ocean, Icons.circle_outlined),
    };
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: NovaStory.cloud, width: 3),
          boxShadow: status == ActivityStatus.recommended ? NovaShadow.glow(NovaStory.coral, strength: 0.5) : NovaShadow.contact,
        ),
        child: status == ActivityStatus.mastered ? Center(child: StarShape(size: size * 0.6)) : Icon(icon, color: Colors.white, size: size * 0.6),
      ),
    );
  }
}

/// Locked places are drawn in soft, misty colours: still solid (the trail
/// passes behind them), but clearly not open yet.
const lockedMist = ColorFilter.matrix([
  0.33, 0.45, 0.12, 0, 60, //
  0.28, 0.5, 0.12, 0, 62,
  0.28, 0.45, 0.17, 0, 70,
  0, 0, 0, 1, 0,
]);

/// Leaves colours unchanged.
const noFilter = ColorFilter.mode(Colors.transparent, BlendMode.dst);

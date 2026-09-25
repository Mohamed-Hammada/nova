import 'package:flutter/widgets.dart';

import '../game/stage3d/stage_capability.dart';
import '../l10n.dart';
import 'age_band.dart';

/// Localized names for the presentation enums.
String bandTitle(BuildContext context, AgeBand band) => switch (band) {
      AgeBand.tiny => context.l10n.bandTiny,
      AgeBand.explorer => context.l10n.bandExplorer,
      AgeBand.champion => context.l10n.bandChampion,
    };

String ageYears(BuildContext context, AgeBand band) =>
    context.l10n.ageYears('${NovaNumbers.format(context, band.minAge)}–${NovaNumbers.format(context, band.maxAge)}');

String worldName(BuildContext context, WorldKind world) => switch (world) {
      WorldKind.candyMeadow => context.l10n.worldCandyMeadow,
      WorldKind.sunnyForest => context.l10n.worldSunnyForest,
      WorldKind.cosmicLab => context.l10n.worldSpaceLab,
    };

String graphicsSettingLabel(BuildContext context, GraphicsQualitySetting q) => switch (q) {
      GraphicsQualitySetting.auto => context.l10n.graphicsAuto,
      GraphicsQualitySetting.high => context.l10n.graphicsHigh,
      GraphicsQualitySetting.medium => context.l10n.graphicsMedium,
      GraphicsQualitySetting.low => context.l10n.graphicsLow,
      GraphicsQualitySetting.twoDimensional => context.l10n.graphics2D,
    };

String graphicsSettingHelp(BuildContext context, GraphicsQualitySetting q) => switch (q) {
      GraphicsQualitySetting.auto => context.l10n.graphicsAutoDesc,
      GraphicsQualitySetting.high => context.l10n.graphicsHighDesc,
      GraphicsQualitySetting.medium => context.l10n.graphicsMediumDesc,
      GraphicsQualitySetting.low => context.l10n.graphicsLowDesc,
      GraphicsQualitySetting.twoDimensional => context.l10n.graphics2DDesc,
    };

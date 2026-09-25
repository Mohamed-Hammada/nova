import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/l10n.dart';

/// Switches the app between Arabic and English. Changing the locale is all it
/// does: text direction, strings, number digits and content language all
/// follow from the inherited locale.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key, this.iconOnly = false});

  /// Just the icon, for round storybook controls (the tooltip and
  /// screen-reader label still name it).
  final bool iconOnly;

  static String endonym(AppLocalizations l10n, Locale locale) =>
      locale.languageCode == NovaLocales.arabic.languageCode ? l10n.languageNameArabic : l10n.languageNameEnglish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = Localizations.localeOf(context);
    return PopupMenuButton<Locale>(
      tooltip: l10n.languageMenuTooltip,
      onSelected: (locale) => ref.read(localeProvider.notifier).state = locale,
      itemBuilder: (context) => [
        for (final locale in NovaLocales.supported)
          CheckedPopupMenuItem<Locale>(
            value: locale,
            checked: locale.languageCode == current.languageCode,
            // Each language name is written in its own script and direction.
            child: Text(
              endonym(l10n, locale),
              textDirection: locale.languageCode == NovaLocales.arabic.languageCode ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: NovaSize.minTouch, minWidth: NovaSize.minTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: NovaSpace.sm),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.translate_rounded),
            // On phones the icon alone (the tooltip and screen-reader label
            // still name it); the current language's name where there is room.
            if (!iconOnly && NovaWidthClass.of(context) != NovaWidthClass.compact) ...[
              const SizedBox(width: NovaSpace.xs),
              Text(endonym(l10n, current), style: Theme.of(context).textTheme.labelLarge),
            ],
          ]),
        ),
      ),
    );
  }
}

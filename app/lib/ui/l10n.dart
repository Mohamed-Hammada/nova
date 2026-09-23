import 'package:flutter/widgets.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/l10n/app_localizations.dart';

export 'package:nova_app/l10n/app_localizations.dart';

/// The app's languages. Direction is not configured here: Flutter's
/// GlobalWidgetsLocalizations derives RTL for Arabic and LTR for English from
/// the active locale, and every Nova layout uses directional (start/end)
/// geometry, so the whole UI mirrors from that one inherited value.
abstract final class NovaLocales {
  static const english = Locale('en');
  static const arabic = Locale('ar');
  static const supported = [english, arabic];

  /// Picks the first device locale Nova supports (by language), else English.
  static Locale resolve(List<Locale>? deviceLocales) {
    for (final device in deviceLocales ?? const <Locale>[]) {
      for (final candidate in supported) {
        if (candidate.languageCode == device.languageCode) return candidate;
      }
    }
    return english;
  }
}

extension NovaLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// The language code used to look up curriculum strings in the content
  /// bundle (which is keyed by language, like the langpacks).
  String get contentLanguage => Localizations.localeOf(this).languageCode;
}

/// Curriculum strings (game and skill names, descriptions) come from the
/// compiled content bundle, never from the ARB files. A key missing in the
/// active language falls back to English before falling back to the raw key,
/// so an untranslated item shows readable text rather than an id.
String contentText(ContentRuntime content, String key, String language) {
  final text = content.i18n(key, language);
  if (text != key || language == NovaLocales.english.languageCode) return text;
  return content.i18n(key, NovaLocales.english.languageCode);
}

/// Numbers shown to the child and caregiver.
///
/// Arabic uses Eastern Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩), matching the
/// Arabic strings already in the content bundle (e.g. "العدّ حتى ٥"). Eastern
/// versus Western digits for Arabic is an open decision awaiting native
/// educator review; this function is the single place to change it.
abstract final class NovaNumbers {
  static const _eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  static String format(BuildContext context, int value) => formatFor(Localizations.localeOf(context), value);

  static String formatFor(Locale locale, int value) {
    final western = value.toString();
    if (locale.languageCode != NovaLocales.arabic.languageCode) return western;
    return western.split('').map((c) {
      final digit = int.tryParse(c);
      return digit == null ? c : _eastern[digit];
    }).join();
  }
}

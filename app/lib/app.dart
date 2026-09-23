import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';

import 'ui/design/nova_design.dart';
import 'ui/home/home_screen.dart';
import 'ui/l10n.dart';

/// The MaterialApp configuration every Nova surface shares -- including the
/// boot screens shown before content has loaded -- so theme, localization and
/// text direction are identical everywhere.
class NovaMaterialApp extends StatelessWidget {
  const NovaMaterialApp({super.key, required this.home, this.locale});

  final Widget home;

  /// Null follows the device's languages (resolved to a supported one).
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: NovaTheme.light(),
      locale: locale,
      supportedLocales: NovaLocales.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (deviceLocales, _) => NovaLocales.resolve(deviceLocales),
      home: home,
    );
  }
}

class NovaApp extends ConsumerWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NovaMaterialApp(locale: ref.watch(localeProvider), home: const HomeScreen());
  }
}

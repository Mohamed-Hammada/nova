import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';

import 'ui/design/nova_design.dart';
import 'ui/home/home_screen.dart';
import 'ui/journey/onboarding_screen.dart';
import 'ui/l10n.dart';
import 'ui/settings/settings_sync.dart';
import 'ui/theme/graphics.dart';
import 'ui/theme/motion.dart';

/// The MaterialApp configuration every Nova surface shares -- including the
/// boot screens shown before content has loaded -- so theme, localization and
/// text direction are identical everywhere.
class NovaMaterialApp extends StatelessWidget {
  const NovaMaterialApp({super.key, required this.home, this.locale, this.builder});

  final Widget home;

  /// Wraps every route (settings, graphics and motion scopes).
  final TransitionBuilder? builder;

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
      builder: builder,
      home: home,
    );
  }
}

class NovaApp extends ConsumerWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NovaMaterialApp(
      locale: ref.watch(localeProvider),
      builder: (context, child) => AmbientMotion(
        enabled: ref.watch(ambientMotionProvider),
        child: Graphics(
          quality: ref.watch(graphicsProvider),
          child: SettingsSync(child: child!),
        ),
      ),
      // A child who has not told Nova their age yet starts with onboarding.
      home: ref.watch(childAgeProvider) == null ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}

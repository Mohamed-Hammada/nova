import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'ui/home_screen.dart';
import 'ui/settings/settings_sync.dart';
import 'ui/theme/graphics.dart';
import 'ui/theme/motion.dart';
import 'ui/theme/nova_theme.dart';
import 'ui/theme/strings.dart';

class NovaApp extends ConsumerWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final band = ref.watch(ageBandProvider);
    final strings = UiStrings.of(ref.watch(languageProvider));
    return MaterialApp(
      title: 'Nova',
      debugShowCheckedModeBanner: false,
      theme: novaTheme(band, ref.watch(paletteProvider)),
      builder: (context, child) => AmbientMotion(
        enabled: ref.watch(ambientMotionProvider),
        child: Graphics(
          quality: ref.watch(graphicsProvider),
          child: SettingsSync(
            child: Directionality(textDirection: strings.direction, child: child!),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

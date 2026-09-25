import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adapters/content_bundle_asset/asset_content_loader.dart';
import 'app.dart';
import 'providers.dart';
import 'ui/settings/settings_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final runtime = await loadContentRuntimeFromAssets();
  final container = ProviderContainer(overrides: [contentRuntimeProvider.overrideWithValue(runtime)]);
  try {
    await loadSettings(container, container.read(playerStatePortProvider)).timeout(const Duration(seconds: 3));
  } catch (_) {
    // First run, or storage unavailable: start with the defaults.
  }
  runApp(UncontrolledProviderScope(container: container, child: const NovaApp()));
}

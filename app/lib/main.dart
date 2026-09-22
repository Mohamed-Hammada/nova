import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adapters/content_bundle_asset/asset_content_loader.dart';
import 'app.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final runtime = await loadContentRuntimeFromAssets();
  runApp(
    ProviderScope(
      overrides: [contentRuntimeProvider.overrideWithValue(runtime)],
      child: const NovaApp(),
    ),
  );
}

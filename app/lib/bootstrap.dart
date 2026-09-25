import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/adapters/content_bundle_asset/asset_content_loader.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/providers.dart';

import 'app.dart';
import 'ui/design/nova_design.dart';
import 'ui/l10n.dart';
import 'ui/settings/settings_sync.dart';

/// What the app needs before its first real screen.
class BootResult {
  const BootResult({required this.content, this.bundledAssets});
  final ContentRuntime content;
  final Set<String>? bundledAssets;
}

Future<BootResult> loadBootResult() async {
  final content = await loadContentRuntimeFromAssets();
  Set<String>? assets;
  try {
    assets = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();
  } catch (_) {
    // Without a manifest, audio simply attempts every play.
  }
  return BootResult(content: content, bundledAssets: assets);
}

/// Loads the compiled content bundle (from the app's own assets -- never the
/// network), showing a real loading state meanwhile and a recoverable error
/// state if it fails, then hands the loaded content to the app through the
/// composition root's provider overrides.
class NovaBootstrap extends StatefulWidget {
  const NovaBootstrap({super.key, this.load = loadBootResult, this.overrides = const []});

  final Future<BootResult> Function() load;

  /// Extra provider overrides (tests swap in fake ports here).
  final List<Override> overrides;

  @override
  State<NovaBootstrap> createState() => _NovaBootstrapState();
}

class _NovaBootstrapState extends State<NovaBootstrap> {
  late Future<ProviderContainer> _boot;
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    _boot = _start();
  }

  @override
  void dispose() {
    _container?.dispose();
    super.dispose();
  }

  /// Loads content, then the saved settings, so the first frame already
  /// shows the child's name, language and world rather than the defaults.
  Future<ProviderContainer> _start() async {
    final result = await widget.load();
    final container = ProviderContainer(overrides: [
      contentRuntimeProvider.overrideWithValue(result.content),
      bundledAssetsProvider.overrideWithValue(result.bundledAssets),
      ...widget.overrides,
    ]);
    try {
      await loadSettings(container, container.read(playerStatePortProvider)).timeout(const Duration(seconds: 3));
    } catch (_) {
      // First run, or storage unavailable: start with the defaults.
    }
    _container?.dispose();
    _container = container;
    return container;
  }

  void _retry() {
    final boot = _start();
    setState(() {
      _boot = boot;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProviderContainer>(
      future: _boot,
      builder: (context, snapshot) {
        final container = snapshot.data;
        if (container != null) {
          return UncontrolledProviderScope(container: container, child: const NovaApp());
        }
        if (snapshot.hasError) {
          debugPrint('Nova failed to load its content bundle: ${snapshot.error}');
          return NovaMaterialApp(home: _BootError(onRetry: _retry));
        }
        return const NovaMaterialApp(home: _BootLoading());
      },
    );
  }
}

class _BootLoading extends StatelessWidget {
  const _BootLoading();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: NovaPalette.canvas,
        child: NovaLoadingView(message: context.l10n.loadingMessage),
      );
}

class _BootError extends StatelessWidget {
  const _BootError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: NovaPalette.canvas,
        child: NovaErrorView(
          title: context.l10n.errorTitle,
          message: context.l10n.errorContentUnavailable,
          retryLabel: context.l10n.retry,
          onRetry: onRetry,
        ),
      );
}

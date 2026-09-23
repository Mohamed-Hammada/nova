import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Keeps the web build self-contained and in step with its Dart packages.
void main() {
  final lock = loadYaml(File('pubspec.lock').readAsStringSync()) as YamlMap;
  String lockedVersion(String package) => ((lock['packages'] as YamlMap)[package] as YamlMap)['version'] as String;

  group('vendored web SQLite assets', () {
    final manifest = jsonDecode(File('web/sqlite_web_assets.json').readAsStringSync()) as Map<String, dynamic>;
    final assets = {for (final e in manifest.entries) if (!e.key.startsWith('_')) e.key: e.value as Map<String, dynamic>};

    test('both sqlite3.wasm and drift_worker.js are vendored', () {
      expect(assets.keys.toSet(), {'sqlite3.wasm', 'drift_worker.js'});
    });

    for (final MapEntry(key: file, value: pin) in assets.entries) {
      test('$file matches the ${pin['package']} version resolved in pubspec.lock', () {
        expect(pin['version'], lockedVersion(pin['package'] as String),
            reason: 'run scripts/update_web_sqlite_assets.sh after upgrading ${pin['package']}');
      });

      test('$file on disk is exactly the pinned file (sha256)', () {
        final bytes = File('web/$file').readAsBytesSync();
        expect(sha256.convert(bytes).toString(), pin['sha256']);
      });
    }
  });

  test('web/index.html loads nothing from another origin', () {
    final html = File('web/index.html').readAsStringSync();
    expect(RegExp(r'''(src|href)\s*=\s*["']\s*(https?:)?//''').hasMatch(html), isFalse);
  });

  test('every font the theme uses is bundled, so no text needs a runtime font download', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final fonts = ((pubspec['flutter'] as YamlMap)['fonts'] as YamlList).cast<YamlMap>();
    final families = fonts.map((f) => f['family'] as String).toSet();
    expect(families, containsAll(['NotoSans', 'NotoSansArabic']));
    for (final family in fonts) {
      for (final font in (family['fonts'] as YamlList).cast<YamlMap>()) {
        expect(File(font['asset'] as String).existsSync(), isTrue, reason: '${font['asset']}');
      }
    }
    final theme = File('lib/ui/design/theme.dart').readAsStringSync();
    expect(theme, contains("fontFamily = 'NotoSans'"));
    expect(theme, contains("['NotoSansArabic']"));
  });

  test("Flutter web's default Roboto and glyph fallbacks resolve locally, never to fonts.gstatic.com", () {
    // Found in a real browser run: without these, the engine fetched Roboto
    // from Google on every boot.
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final families = ((pubspec['flutter'] as YamlMap)['fonts'] as YamlList).map((f) => (f as YamlMap)['family']).toSet();
    expect(families, contains('Roboto'));
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
    expect(bootstrap, contains("fontFallbackBaseUrl: 'assets/font-fallback/'"));
    expect(bootstrap, isNot(contains('gstatic')));
  });

  test('the web scripts build and run without Google\'s CDN (CanvasKit is served from the app itself)', () {
    for (final script in ['../scripts/build_web.sh', '../scripts/build_web.bat', '../scripts/run_web.sh', '../scripts/run_web.bat']) {
      final source = File(script).readAsStringSync();
      expect(source, contains('--no-web-resources-cdn'), reason: script);
      expect(source, contains('regenerate_content_bundle'), reason: '$script must build from freshly compiled content');
    }
  });
}

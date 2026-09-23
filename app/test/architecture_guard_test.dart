import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architectural boundaries, checked mechanically on every test run rather
/// than left to review:
///
///   UI -> ViewModel -> GameRuntime -> Domain -> Ports <- Adapters
///
/// and platform code confined to the one adapter file for its platform, so
/// the web build can never accidentally depend on dart:io (or native on the
/// browser's libraries).
Map<String, List<String>> _importsUnder(String dir) {
  final result = <String, List<String>>{};
  for (final entity in Directory(dir).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    result[path] = [
      for (final line in entity.readAsLinesSync())
        if (RegExp(r'''^\s*(import|export)\s+['"]''').hasMatch(line))
          RegExp(r'''['"]([^'"]+)['"]''').firstMatch(line)!.group(1)!,
    ];
  }
  return result;
}

List<String> _violations(Map<String, List<String>> imports, bool Function(String path) inScope, bool Function(String import) forbidden) => [
      for (final MapEntry(key: path, value: list) in imports.entries)
        if (inScope(path))
          for (final import in list)
            if (forbidden(import)) '$path imports $import',
    ];

void main() {
  final lib = _importsUnder('lib');

  test('the domain core is pure Dart: no Flutter, no platform libraries, no adapters or UI', () {
    expect(
      _violations(
        lib,
        (p) => p.startsWith('lib/core/'),
        (i) =>
            i.startsWith('package:flutter/') ||
            i.startsWith('dart:io') ||
            i.startsWith('dart:ffi') ||
            i.startsWith('dart:js') ||
            i.startsWith('dart:ui') ||
            i.contains('/adapters/') ||
            i.contains('/ui/') ||
            i.contains('mechanics_flutter') ||
            i.contains('providers.dart'),
      ),
      isEmpty,
    );
  });

  test('native-only libraries appear only in the native connection', () {
    const nativeOnly = ['dart:io', 'dart:ffi', 'package:drift/native.dart', 'package:path_provider/', 'package:sqlite3_flutter_libs/', 'package:sqlite3/sqlite3.dart'];
    expect(
      _violations(lib, (p) => p != 'lib/adapters/persistence_drift/connection_native.dart', (i) => nativeOnly.any(i.startsWith)),
      isEmpty,
      reason: 'anything else importing these would break `flutter build web`',
    );
  });

  test('browser-only libraries appear only in the web connection', () {
    const webOnly = ['dart:js_interop', 'dart:html', 'package:web/', 'package:drift/wasm.dart', 'package:drift/web.dart'];
    expect(
      _violations(lib, (p) => p != 'lib/adapters/persistence_drift/connection_web.dart', (i) => webOnly.any(i.startsWith)),
      isEmpty,
    );
  });

  test('the platform connection is selected by a conditional export, not at runtime', () {
    final source = File('lib/adapters/persistence_drift/connection.dart').readAsStringSync();
    expect(source, contains("export 'connection_native.dart' if (dart.library.js_interop) 'connection_web.dart';"));
  });

  test('widgets never reach persistence, assessment, or mastery computation directly', () {
    expect(
      _violations(
        lib,
        (p) => p.startsWith('lib/ui/') || p.startsWith('lib/mechanics_flutter/'),
        (i) =>
            i.contains('/adapters/') ||
            i.endsWith('ports/persistence_port.dart') ||
            i.contains('/core/assessment/') ||
            i.endsWith('mastery/mastery_engine.dart') ||
            i.contains('/core/adaptive/') ||
            i.contains('/core/signals/'),
      ),
      isEmpty,
    );
  });

  test('only the composition root (providers, bootstrap) wires adapters', () {
    expect(
      _violations(
        lib,
        (p) => !p.startsWith('lib/adapters/') && p != 'lib/providers.dart' && p != 'lib/bootstrap.dart',
        (i) => i.contains('/adapters/') || i.startsWith('../adapters/') || i.startsWith('adapters/'),
      ),
      isEmpty,
    );
  });

  test('no user-visible string literal is hardcoded in UI code (all come from l10n or content)', () {
    final pattern = RegExp(r'''(Text\(|label: |tooltip: |message: |semanticLabel: |hint: )\s*['"][A-Za-z؀-ۿ]''');
    final offenders = <String>[];
    for (final dir in ['lib/ui', 'lib/mechanics_flutter']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (pattern.hasMatch(line)) offenders.add('${entity.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('no code under lib/ contains a network URL', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//') || line.startsWith('///') || line.startsWith('*')) continue;
        if (RegExp(r'''https?://|wss?://''').hasMatch(line)) offenders.add('${entity.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}

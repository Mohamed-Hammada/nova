import 'dart:js_interop';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// The same SQLite database the native build uses, compiled to WebAssembly
/// and stored in the browser (OPFS where available, IndexedDB otherwise --
/// drift probes and picks the most reliable option).
///
/// `sqlite3.wasm` and `drift_worker.js` are served from the app's own origin
/// (vendored in app/web/, pinned to the sqlite3/drift versions in
/// pubspec.lock -- see app/web/sqlite_web_assets.json and its guard test).
/// Nothing is fetched from a CDN or a backend.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    await _requestPersistentStorage();
    final result = await WasmDatabase.open(
      databaseName: 'nova',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    debugPrint('Nova storage: ${result.chosenImplementation.name} '
        '(missing browser features: ${result.missingFeatures.map((f) => f.name).join(', ')})');
    if (result.chosenImplementation == WasmStorageImplementation.inMemory ||
        result.chosenImplementation == WasmStorageImplementation.unsafeIndexedDb) {
      // Progress still works for this visit, but the browser did not give us
      // durable storage; surfaced in the console rather than blocking play.
      debugPrint('Nova: browser storage is not durable '
          '(${result.chosenImplementation.name}; missing: ${result.missingFeatures})');
    }
    return result.resolvedExecutor;
  }));
}

/// Browsers may evict site storage under pressure (design doc 2026-09-22,
/// option D's storage-eviction row); asking for persistent storage is the
/// platform's mitigation. Best effort: a refusal or an unsupported API never
/// blocks opening the database.
Future<void> _requestPersistentStorage() async {
  try {
    await web.window.navigator.storage.persist().toDart;
  } catch (_) {}
}

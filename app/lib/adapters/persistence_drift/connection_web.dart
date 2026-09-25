import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web storage: SQLite compiled to WebAssembly, persisted in the browser
/// (OPFS or IndexedDB, whichever the browser supports best). sqlite3.wasm
/// and drift_worker.js are bundled in app/web/ -- served with the app, never
/// fetched from a third party, so the app keeps working offline. Their
/// versions must match the sqlite3 and drift packages in pubspec.lock.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(databaseName: 'nova', sqlite3Uri: Uri.parse('sqlite3.wasm'), driftWorkerUri: Uri.parse('drift_worker.js'));
      return result.resolvedExecutor;
    }),
  ).executor;
}

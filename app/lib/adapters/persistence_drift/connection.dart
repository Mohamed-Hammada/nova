// Platform selection for the drift connection, done at compile time by a
// conditional export so neither side's platform libraries leak into the
// other's build: native builds never see package:web/drift wasm, and web
// builds never see dart:io/dart:ffi (which is what made `flutter build web`
// fail before this split). DriftPersistencePort, the schema, and every SQL
// statement are shared -- only how the SQLite engine is reached differs.
//
// Both libraries export the same `QueryExecutor openConnection()`.
export 'connection_native.dart' if (dart.library.js_interop) 'connection_web.dart';

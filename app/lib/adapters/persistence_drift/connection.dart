// Picks the SQLite backend for the platform: native sqlite3 via FFI on
// Android/iOS/desktop, and sqlite3 compiled to WebAssembly on the web
// (dart:ffi does not exist there). Both expose the same openConnection().
export 'connection_native.dart' if (dart.library.js_interop) 'connection_web.dart';

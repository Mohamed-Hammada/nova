import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart'; // ensures the native sqlite3 lib is bundled with the app; no symbol from it is referenced directly

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = p.join(dir.path, 'nova.sqlite');
    return NativeDatabase.createInBackground(File(file));
  });
}
